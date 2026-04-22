# k3s Lab: GitOps Homelab Platform

A portfolio-ready homelab platform built with k3s, GitOps, and modern Kubernetes best practices.
**Latest Architecture Components:**
- **ArgoCD:** GitOps application delivery engine managing `k8s/apps/*` and monitoring workloads
- **Ansible:** Bootstraps k3s clusters and prepares the target environment
- **App Skeleton:** Sample app deployment with Kubernetes manifests
- **PostgreSQL:** Bitnami Helm chart backed by Longhorn PVC
- **Redis:** Bitnami Helm chart backed by Longhorn PVC
- **RabbitMQ:** StatefulSet with Longhorn persistence and management UI
- **Loki:** Centralized log aggregation for cluster logs
- **Prometheus:** Metrics collection for Kubernetes and workloads
- **Grafana:** Dashboarding + Loki/Prometheus visualization
- **Traefik:** Ingress routing for app and GitOps services

---

## 📁 Project Structure

```
k3slab/
├── .github/
│   └── workflows/
│       ├── build-ci.yaml              # Builds app container and runs integration tests
│       └── deploy-cd.yaml             # Deploys manifests via GitOps/ArgoCD or SSH kube apply
├── ansible/                           # Cluster bootstrap automation
│   ├── bootstrap.yml
│   └── roles/
├── k8s/
│   ├── apps/                          # Application workloads
│   │   ├── app-skeleton/
│   │   │   ├── deployment.yaml
│   │   │   ├── service.yaml
│   │   │   └── ingress.yaml
│   │   ├── database/
│   │   │   ├── postgres-helm.yaml
│   │   │   └── pvc.yaml
│   │   ├── redis/
│   │   │   └── redis-helm.yaml
│   │   └── rabbitmq/
│   │       └── rabbitmq-helm.yaml
│   ├── gitops/
│   │   ├── argocd-helm.yaml
│   │   └── argocd-applicationset.yaml
│   └── monitoring/
│       ├── grafana-helm.yaml
│       ├── prometheus-helm.yaml
│       ├── loki-helm.yaml
│       ├── loki-values.yaml
│       └── promtail.yaml
├── src/
│   └── app-skeleton/                  # App skeleton source and Dockerfile
│       ├── Dockerfile
│       └── .env.example
└── tests/
    └── integration/                   # GitHub Actions connectivity tests
        └── full_stack_connectivity.sh
```

---

## 🛠️ Tech Stack

- k3s
- ArgoCD
- Ansible
- Helm / Bitnami charts
- Longhorn
- Traefik
- PostgreSQL
- Redis
- RabbitMQ
- Loki
- Prometheus
- Grafana
- GitHub Actions
- GHCR

---

## 💡 GitOps Flow

1. Developer pushes YAML or app changes to GitHub.
2. `build-ci.yaml` builds the app image and runs integration checks.
3. ArgoCD syncs manifest changes from the repository into the k3s cluster.
4. Kubernetes applies deployments, Helm charts, and monitoring services automatically.
5. Observability stack validates health and logs.


---

### One-command bootstrap

From the repo root, run:

```bash
./bootstrap.sh
```

Or use the Makefile target:

```bash
make bootstrap
```

This script is fully idempotent and will:
- install k3s only if missing
- create or update `~/.kube/config` with correct ownership and permissions
- create a minimal `inventory.ini` if needed
- run the existing `ansible/bootstrap.yml` playbook
- wait for ArgoCD to become healthy
- refresh ArgoCD applications
- print a final status summary with helpful URLs

### Prerequisites
- `ansible-playbook` installed for bootstrap automation
- `kubectl` access to the cluster

### Bootstrap with Ansible

```bash
cd ansible
test -f inventory.ini || echo "[k3s]\nlocalhost ansible_connection=local" > inventory.ini
ansible-playbook -i inventory.ini bootstrap.yml
```

### Deploy with ArgoCD

```bash
kubectl apply -f k8s/gitops/argocd-helm.yaml
kubectl apply -f k8s/gitops/argocd-applicationset.yaml
```

---

## 📦 Deployment

### Manual deploy sequence

```bash
kubectl apply -f k8s/apps/database/pvc.yaml
kubectl apply -f k8s/apps/database/postgres-helm.yaml
kubectl apply -f k8s/apps/redis/redis-helm.yaml
kubectl apply -f k8s/apps/rabbitmq/rabbitmq-helm.yaml
kubectl apply -f k8s/apps/app-skeleton/deployment.yaml
kubectl apply -f k8s/apps/app-skeleton/service.yaml
kubectl apply -f k8s/apps/app-skeleton/ingress.yaml
kubectl apply -f k8s/monitoring/prometheus-helm.yaml
kubectl apply -f k8s/monitoring/grafana-helm.yaml
kubectl apply -f k8s/monitoring/loki-helm.yaml
kubectl apply -f k8s/monitoring/promtail.yaml
```

### GitOps deploy

```bash
git add .
git commit -m "update platform"
git push origin main
```

---

## 📌 Observability

**Grafana:**
```bash
kubectl port-forward -n monitoring svc/grafana 3000:80
# http://localhost:3000
```

**Prometheus:**
```bash
kubectl port-forward -n monitoring svc/prometheus-operated 9090:9090
# http://localhost:9090
```

**Loki:**
```bash
kubectl port-forward -n monitoring svc/loki 3100:3100
# http://localhost:3100
```

---

## 🔐 Security & Best Practices

- Workloads run as non-root
- Resource requests and limits configured
- Helm charts bootstrapped through ArgoCD
- GitHub Actions tests connectivity for the full stack
- Ansible used for repeatable cluster bootstrap

## 🔐 Security & Secrets

This platform uses **Sealed Secrets** for secure GitOps secret management.

- Sensitive credentials are stored in the repo only as encrypted `SealedSecret` objects.
- The Sealed Secrets controller decrypts them into Kubernetes `Secret` resources at runtime.

- Example sealed secrets in this repo:
  - `k8s/database/postgresql-sealedsecret.yaml`
  - `k8s/apps/redis/redis-sealedsecret.yaml`
  - `k8s/monitoring/grafana-sealedsecret.yaml`
- The Sealed Secrets controller manifest is tracked under `k8s/gitops/sealed-secrets-controller.yaml`.
- No plaintext passwords are committed to YAML manifests or Helm values.
- CI avoids hardcoded secret values by using GitHub Actions secrets like `POSTGRES_PASSWORD`.

For production readiness, ensure the controller private key remains secure and rotate sealed secrets if the private key changes.

---

## 🧭 Troubleshooting

```bash
kubectl get pods -A
kubectl describe pod <pod-name> -n <namespace>
kubectl get pvc
kubectl logs <pod-name> -n <namespace>
```

---

## 📚 References
- [k3s](https://docs.k3s.io/)
- [ArgoCD](https://argo-cd.readthedocs.io/)
- [Ansible](https://docs.ansible.com/)
- [Loki](https://grafana.com/oss/loki/)
- [Prometheus](https://prometheus.io/)
- [Grafana](https://grafana.com/)
- [Longhorn](https://longhorn.io/)

---

## Architecture Addendum

```
GitHub → ArgoCD → k3s Cluster
                   ├── apps/
                   ├── monitoring/
                   └── database
```

### System overview

This repository defines a GitOps-driven k3s platform where ArgoCD syncs declared application, monitoring, and database resources into the cluster.

### Deployment flow

`git push → ArgoCD sync → cluster updates automatically`

---

**MIT License** — portfolio-ready documentation for platform engineering.
