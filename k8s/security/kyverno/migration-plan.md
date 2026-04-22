# Kyverno Progressive Enforcement Migration Plan

## Goal
Safely migrate Kyverno policies from audit mode to enforce mode while keeping ArgoCD sync stable and avoiding namespace downtime.

## Policy categories

### Category A: Critical security policies (Enforce)
- `audit-deny-privileged-containers` → Enforce
- `audit-require-run-as-non-root` → Enforce
- `audit-deny-hostpath-volumes` → Enforce
- `audit-require-namespace-labels` → Enforce

### Category B: Medium-risk policies (Audit)
- `audit-require-resource-limits` remains in Audit for observation

### Category C: Observability policies (Audit / future)
- Any future monitoring or reporting policies should remain in Audit initially.

## Migration steps
1. Update critical policies in `k8s/security/kyverno/global-enforcement-policies.yaml` to `validationFailureAction: enforce`.
2. Keep resource limit policy in audit mode for continued observation.
3. Verify the policy set with `kubectl apply` and observe Kyverno logs/events.
4. Monitor ArgoCD sync and cluster events for any rejection feedback.
5. Confirm that no existing namespaces or workloads were disrupted by admission enforcement.

## Risk table

| Policy | Category | Mode | Risk if Enforced | Notes |
|---|---|---|---|---|
| `audit-deny-privileged-containers` | Critical | Enforce | High if bypassed | Blocks privileged pods at admission.
| `audit-require-run-as-non-root` | Critical | Enforce | High for container privilege | Prevents root container execution.
| `audit-deny-hostpath-volumes` | Critical | Enforce | High if hostPath used maliciously | Protects node filesystem access.
| `audit-require-namespace-labels` | Critical | Enforce | Medium | Ensures namespaces are tagged and compliant.
| `audit-require-resource-limits` | Medium | Audit | Low | Observes workloads missing limits before enforcement.

## Rollback strategy

If enforcement causes operational issues:

1. Revert the enforce mode changes in Git by setting the affected policies back to `validationFailureAction: audit`.
2. Commit the rollback with a clear message, e.g. `revert: restore Kyverno policies to audit mode for stability`.
3. Push the rollback branch and allow ArgoCD to reconcile.
4. Review Kyverno logs and alerts before reattempting enforcement.

## ArgoCD compatibility notes

- Kyverno operates at admission time; existing resources are not mutated automatically.
- With enforce mode enabled, application syncs may fail for invalid manifests, but ArgoCD will not break cluster state.
- Use Git history to revert policy changes if necessary, preserving ArgoCD drift detection.
