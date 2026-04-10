#!/usr/bin/env bash
set -euo pipefail
umask 077
IFS=$'\n\t'

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

info() {
  printf '\033[1;34m%s\033[0m\n' "$*"
}
success() {
  printf '\033[1;32m%s\033[0m\n' "$*"
}
warn() {
  printf '\033[1;33m%s\033[0m\n' "$*"
}
fail() {
  printf '\033[1;31m%s\033[0m\n' "$*" >&2
  exit 1
}

has_cmd() {
  command -v "$1" >/dev/null 2>&1
}

run_as_root() {
  if [ "$(id -u)" -ne 0 ]; then
    if ! has_cmd sudo; then
      fail "sudo is required to run: $*"
    fi
    sudo "$@"
  else
    "$@"
  fi
}

maybe_install_package() {
  local pkg="$1"
  if has_cmd apt-get; then
    info "Installing package '$pkg' with apt"
    run_as_root apt-get update -y
    run_as_root apt-get install -y "$pkg"
  else
    fail "Required package '$pkg' is missing and apt-get is unavailable"
  fi
}

if ! has_cmd curl && ! has_cmd wget; then
  maybe_install_package curl
fi

if ! has_cmd k3s; then
  info "k3s not found: installing k3s"
  if has_cmd curl; then
    run_as_root sh -c 'curl -fsSL https://get.k3s.io | sh -'
  else
    run_as_root sh -c 'wget -qO- https://get.k3s.io | sh -'
  fi
else
  info "k3s already installed"
fi

if ! has_cmd kubectl; then
  if has_cmd k3s; then
    export PATH="/usr/local/bin:$PATH"
  fi
fi

if ! has_cmd kubectl; then
  fail "kubectl not available after k3s installation"
fi

if [ ! -d "$HOME/.kube" ]; then
  mkdir -p "$HOME/.kube"
fi

if [ ! -f /etc/rancher/k3s/k3s.yaml ]; then
  fail "/etc/rancher/k3s/k3s.yaml not found. Ensure k3s installed successfully."
fi

if [ ! -f "$HOME/.kube/config" ] || ! cmp -s /etc/rancher/k3s/k3s.yaml "$HOME/.kube/config" 2>/dev/null; then
  info "Copying k3s kubeconfig to $HOME/.kube/config"
  if [ "$(id -u)" -ne 0 ]; then
    run_as_root cp /etc/rancher/k3s/k3s.yaml "$HOME/.kube/config"
    run_as_root chown "$(id -u):$(id -g)" "$HOME/.kube/config"
  else
    cp /etc/rancher/k3s/k3s.yaml "$HOME/.kube/config"
    chown "$(id -u):$(id -g)" "$HOME/.kube/config"
  fi
fi
chmod 700 "$HOME/.kube"
chmod 600 "$HOME/.kube/config"
export KUBECONFIG="$HOME/.kube/config"
info "Using KUBECONFIG=$KUBECONFIG"

if [ ! -f "$SCRIPT_DIR/inventory.ini" ]; then
  info "Creating minimal inventory.ini"
  cat > "$SCRIPT_DIR/inventory.ini" <<'EOF'
[k3s]
localhost ansible_connection=local
EOF
fi

if ! has_cmd ansible-playbook; then
  info "ansible-playbook not found"
  maybe_install_package ansible
fi

info "Running Ansible bootstrap"
ansible-playbook -i inventory.ini ansible/bootstrap.yml

info "Waiting for ArgoCD server deployment"
kubectl -n gitops wait --for=condition=available deployment/argocd-server --timeout=300s

info "Refreshing ArgoCD applications"
kubectl -n gitops annotate applications.argoproj.io --all argocd.argoproj.io/refresh=hard --overwrite

info "Waiting for ArgoCD application status"
for i in $(seq 1 30); do
  if kubectl -n gitops get applications.argoproj.io >/dev/null 2>&1; then
    break
  fi
  sleep 5
  info "Waiting for ArgoCD apps to be visible... ($i/30)"
done

cat <<'EOF'

============================================================
Bootstrap complete. Your homelab should now be restoring services.

Useful commands:
  kubectl get pods -A
  kubectl -n gitops get applications.argoproj.io
  kubectl -n monitoring get svc grafana
  kubectl -n gitops get svc argocd-server
  kubectl -n longhorn get svc longhorn-frontend

Port-forward examples:
  Grafana: kubectl port-forward -n monitoring svc/grafana 3000:80
  ArgoCD:  kubectl port-forward -n gitops svc/argocd-server 8080:443
  Longhorn: kubectl port-forward -n longhorn svc/longhorn-frontend 8081:80

If ArgoCD apps are not fully synced yet, watch them with:
  kubectl -n gitops get applications.argoproj.io -o wide
============================================================
EOF

success "Bootstrap script finished successfully"
