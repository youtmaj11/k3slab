# k3s Lab GitOps Platform

A minimal GitOps homelab setup for k3s with ArgoCD, Traefik, Sealed Secrets, monitoring, and PostgreSQL.

```
GitHub → ArgoCD → k3s Cluster
                   ├── apps/
                   ├── monitoring/
                   └── database
```

- GitOps flow: GitHub commits are synced by ArgoCD into the cluster.
- Traefik routes ingress traffic to applications and services.
- Sealed Secrets encrypt sensitive values for safe storage in Git.
- Monitoring stack collects metrics, logs, and dashboards.
- PostgreSQL stores application data for the platform.

Deployment:

`git push → ArgoCD sync → cluster updates automatically`
