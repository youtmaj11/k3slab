# k3s Lab: GitOps-Driven Homelab Platform

A declarative, GitOps-first Kubernetes homelab platform—portfolio piece for DevOps & Platform Engineering roles.

**Key Highlights:** 100% YAML infrastructure | Helm-driven deployments | GitHub Actions CI/CD | Prometheus/Grafana observability | Longhorn storage | Traefik ingress

---

## 🏗️ Architecture

**GitOps Flow:**
```
Git Push → Build CI (Docker → GHCR) → Deploy CD (SSH → kubectl apply)
```

**Cluster Components:**
- **App:** Deployment (2x pods) + Service + Traefik Ingress → `api.homelab.local`
- **Data:** PostgreSQL (Helm) + Redis (Helm) on Longhorn storage
- **Storage UI:** Longhorn UI via `longhorn.homelab.local`
- **Observability:** Prometheus + Grafana

---

## 🛠️ Tech Stack

k3s | Traefik | Longhorn | PostgreSQL (Helm) | Redis (Helm) | Prometheus | Grafana | GitHub Actions | GHCR

## 📁 Project Structure

```
k3s-lab/
├── .gitignore                              # Security: Secrets, build artifacts
├── .github/
│   └── workflows/
│       ├── build-ci.yaml                   # Phase 4: Docker build → GHCR
│       └── deploy-cd.yaml                  # Phase 4: SSH deploy & rollout
├── terraform/                              # Phase 1: IaC scaffolding (mock local provider)
│   ├── main.tf                             # Mock provisioning
│   ├── variables.tf                        # Configuration variables
│   └── templates/
│       └── config.tpl                      # Terraform template
├── src/
│   └── app-skeleton/                       # Phase 2: Your app placeholder
│       ├── Dockerfile                      # Alpine-based, multi-stage
│       └── .env.example                    # Environment template
└── k8s/
    ├── apps/
    │   ├── app-skeleton/                   # Phase 2: Deployment manifests
    │   │   ├── deployment.yaml             # App pods (2 replicas)
    │   │   ├── service.yaml                # ClusterIP service
    │   │   └── ingress.yaml                # Traefik routing
    │   ├── database/                       # Phase 3: PostgreSQL
    │   │   ├── postgres-helm.yaml          # Bitnami Helm chart
    │   │   └── pvc.yaml                    # Longhorn PVC (10Gi)
    │   └── redis/                          # Phase 3: Redis
    │       └── redis-helm.yaml             # Bitnami Helm chart
    └── monitoring/                         # Phase 4: Observability
        ├── prometheus-helm.yaml            # Prometheus + Node Exporter
        └── grafana-helm.yaml               # Grafana dashboards
    └── storage/                            # Phase 5: Longhorn storage operator
        ├── namespace.yaml                  # Longhorn namespace
        ├── longhorn-helm.yaml              # HelmChart deploy for Longhorn
        └── longhorn-ui-ingress.yaml        # Traefik routing to Longhorn UI
```

---

## 🚀 Quick Start

### Prerequisites
- k3s cluster with kubectl configured
- Longhorn storage class
- Traefik (built-in to k3s)

### Setup

```bash
git clone https://github.com/yourusername/k3slab.git && cd k3slab

# Verify cluster
kubectl get nodes && kubectl get storageclass

# Create monitoring namespace
kubectl create namespace monitoring
```

### GitHub Secrets (for CD)
Add to `Settings → Secrets and variables → Actions`:
- `SSH_PRIVATE_KEY` — SSH key for k3s host
- `SSH_USER` — SSH username
- `HOST_IP` — k3s host IP

---

## 📦 Deployment

### Manual (Testing)
```bash
kubectl apply -f k8s/apps/database/pvc.yaml
kubectl apply -f k8s/apps/database/postgres-helm.yaml
kubectl apply -f k8s/apps/redis/redis-helm.yaml
kubectl apply -f k8s/apps/app-skeleton/{deployment,service,ingress}.yaml
kubectl apply -f k8s/monitoring/{prometheus,grafana}-helm.yaml
```

### GitOps (Recommended)
```bash
git add . && git commit -m "Deploy changes"
git push origin main  # → GitHub Actions builds + deploys automatically
```

---

## 🔗 Mount Your Application

**Option 1:** Replace `src/app-skeleton/Dockerfile` with your app code → commit → auto-deployed

**Option 2:** Use external image:
```yaml
# k8s/apps/app-skeleton/deployment.yaml
containers:
- name: app-skeleton
  image: ghcr.io/yourname/my-app:latest
```

**Option 3:** Add source to `src/app-skeleton/` and build multi-stage

**Env vars** (injected automatically):
```
DB_HOST=postgres.default.svc.cluster.local  (5432)
REDIS_HOST=redis.default.svc.cluster.local  (6379)
```

---

## 🔄 CI/CD Workflows

**Build CI** (`.github/workflows/build-ci.yaml`)
- Trigger: Push to `main` affecting `src/app-skeleton/**`
- Output: Docker image → `ghcr.io/yourname/k3slab/app-skeleton:latest`

**Deploy CD** (`.github/workflows/deploy-cd.yaml`)
- Trigger: Push to `main` affecting `k8s/apps/**`
- Action: SSH → `kubectl apply` → `kubectl rollout restart`
- Requires: `SSH_PRIVATE_KEY`, `SSH_USER`, `HOST_IP` (GitHub Secrets)

---

## 📊 Observability

**Prometheus:** Metrics scraping
```bash
kubectl port-forward -n monitoring svc/prometheus-operated 9090:9090
# http://localhost:9090
```

**Grafana:** Pre-built dashboards (Cluster, Nodes, Pods)
```bash
kubectl port-forward -n monitoring svc/grafana 3000:80
# http://localhost:3000 | admin/changeme
```

---

## 🔒 Security

✅ Non-root users | ✅ Dropped capabilities | ✅ Pod security contexts | ✅ Resource limits | ✅ Health checks | ✅ .gitignore secrets | ✅ GitHub Secrets for CI/CD

---

## 🛠️ Troubleshooting

```bash
# Pods pending?
kubectl describe pod <pod> && kubectl get pvc

# Image pull errors?
kubectl create secret docker-registry ghcr-secret \
  --docker-server=ghcr.io --docker-username=<user> --docker-password=<token>
# Then add `imagePullSecrets: [name: ghcr-secret]` to deployment

# DNS/connection issues?
kubectl exec <pod> -- nslookup postgres.default.svc.cluster.local
kubectl exec <pod> -- env | grep DB_

# Ingress not working?
kubectl describe ingress app-skeleton && kubectl get pods -A | grep traefik
```

---

## 📚 Resources

[k3s Docs](https://docs.k3s.io/) | [Kubernetes Declarative](https://kubernetes.io/docs/tasks/manage-kubernetes-objects/declarative-config/) | [Helm](https://helm.sh/docs/) | [Longhorn](https://longhorn.io/) | [GitHub Actions](https://github.com/features/actions) | [Prometheus](https://prometheus.io/docs/practices/)

---

**MIT License** — Feel free to fork and adapt for your portfolio.

**Questions?** Open an issue on GitHub.

**Happy deploying! 🚀**
