# Global Kyverno Enforcement

This folder contains the Kyverno policies used for cluster-wide admission control in the k3s GitOps cluster.

## Installation

Kyverno is installed via Helm using the manifest in this folder:
- `k8s/security/kyverno/kyverno-app/kyverno-helm.yaml`

## Architecture diagram

```
GitHub → ArgoCD ApplicationSet → Kyverno Application
                            └── k8s/security/kyverno/kyverno
```

## Global policy definitions

The following cluster-wide policies are defined in `global-enforcement-policies.yaml`:
- deny privileged containers
- require containers to run as non-root
- require CPU and memory limits on containers
- deny hostPath volumes
- audit namespace label compliance

## Enforcement workflow

1. Kyverno is installed as an admission controller.
2. Policies are created in audit mode first to collect violations without blocking workloads.
3. When the audit results are reviewed, policies can be switched to `validationFailureAction: enforce`.
4. ArgoCD keeps the policies in Git and reconciles drift automatically.

## Upgrade path

- Start with `validationFailureAction: audit` for each ClusterPolicy.
- After validating behavior, change `validationFailureAction` to `enforce`.
- Verify with the provided `test-enforcement.sh` script.
- See `migration-plan.md` for the enforce rollout plan, risk table, and rollback instructions.

## Kyverno runtime installation

Kyverno is installed by ArgoCD through the ApplicationSet only.

- Standard GitOps flow: `k8s/security/kyverno/*` is included in `k8s/gitops/argocd-applicationset.yaml`.
- Recovery template: `docs/kyverno-root-bootstrap.yaml` is a manual restore manifest and not part of active ApplicationSet reconciliation.

## Bootstrap reliability

The ApplicationSet provides scalable discovery for Kyverno application directories, but directory wildcard matching can be fragile when the install manifest is not placed under a subdirectory.

The safety net root app ensures:
- a Kyverno application always exists in ArgoCD
- the `kyverno` namespace is created
- Helm chart installation and CRDs are bootstrapped
- admission webhook configuration is installed

## Ownership model

- Primary source of truth: ApplicationSet-based GitOps via `k8s/gitops/argocd-applicationset.yaml`.
- Root bootstrap recovery: manual template stored in `docs/kyverno-root-bootstrap.yaml` and intentionally excluded from active ApplicationSet discovery.
- This prevents duplicate reconciliation loops and ensures only one controller manages Kyverno in normal operation.

## Failure mode analysis

ApplicationSet-only bootstrap is unsafe because:
- `k8s/security/kyverno/*` only matches subdirectories, not files directly under `k8s/security/kyverno`
- if the install manifest sits in the parent directory, no Application is generated silently
- no generated Application means Kyverno is never installed and no failure is surfaced in ArgoCD UI
- the root-app safety net avoids this by explicitly creating a bootstrap Application

## Testing steps

Run the included test script to exercise admission checks:

```bash
chmod +x k8s/security/kyverno/test-enforcement.sh
./k8s/security/kyverno/test-enforcement.sh
```

The script applies the following cases:
- privileged container pod
- missing resource limits pod
- pod with hostPath volume
- namespace creation without required labels

## Verification commands

```bash
kubectl get ns kyverno
kubectl get pods -n kyverno
kubectl get crd clusterpolicies.policy.kyverno.io policyexceptions.policy.kyverno.io
kubectl get validatingwebhookconfigurations | grep kyverno
kubectl get mutatingwebhookconfigurations | grep kyverno || true
```

## Troubleshooting

- If `kyverno` namespace is missing, confirm ArgoCD synced the generated `kyverno` application from the ApplicationSet.
- If `kyverno-admission-controller` is not running, check pod logs with `kubectl logs -n kyverno -l app=kyverno`.
- If webhook resources are missing, verify the Helm chart was installed with `installCRDs: true`.
- If enforcement is not rejecting, confirm `validationFailureAction: enforce` on critical `ClusterPolicy` resources.
- If the ApplicationSet generated app is missing, verify `k8s/security/kyverno/*` is included in `k8s/gitops/argocd-applicationset.yaml`.
