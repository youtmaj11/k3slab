# GitOps Policy Enforcement

This directory contains Gatekeeper install and OPA policy resources for enforcing secure cluster configuration via GitOps.

- `gatekeeper-helm.yaml`: installs Gatekeeper into the cluster using a HelmChart managed by ArgoCD.
- `constrainttemplate-*.yaml`: custom Gatekeeper ConstraintTemplate definitions.
- `*.yaml` constraints are used to enforce admission policies.

Policies enforce:
- no privileged containers
- no hostPath volumes
- required `app` and `phase` labels on Pod workloads

These policies are integrated into ArgoCD sync via the application path defined in `k8s/gitops/argocd-applicationset.yaml`.
