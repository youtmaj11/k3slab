# Kyverno Health Sentinel

This folder contains a Kubernetes-native health sentinel for Kyverno bootstrap and runtime availability.

## Detection flow

The health sentinel runs as a controller-style Deployment that watches Kyverno control-plane resources and exposes Prometheus metrics for continuous observability.

- ArgoCD `Application` named `kyverno` exists in namespace `gitops`
- Kubernetes namespace `kyverno` exists
- Kyverno pods `kyverno-admission-controller` and `kyverno-background-controller` are present
- Kyverno CRDs exist: `clusterpolicies.policy.kyverno.io`, `policyexceptions.policy.kyverno.io`
- Kyverno validating webhook configuration exists

The agent reacts to watch events and reconciles on changes, emitting metrics and logging failures immediately.

## Failure mode coverage

| Failure mode | Detection |
|---|---|
| Kyverno app missing | `kubectl get application kyverno -n gitops` |
| Kyverno namespace missing | `kubectl get namespace kyverno` |
| Kyverno pods not running | `kubectl get pod -n kyverno ...` |
| Kyverno CRDs absent | `kubectl get crd ...` |
| Webhook not registered | `kubectl get validatingwebhookconfigurations | grep kyverno` |

## Remediation

A companion controller deployment runs continuously and performs auto-remediation when Kyverno failures are isolated.

- re-syncs the Kyverno Application via ArgoCD refresh annotation
- re-applies Kyverno bootstrap by refreshing the ApplicationSet when Kyverno is missing
- restarts unhealthy Kyverno pods
- includes cooldown and exponential backoff logic to avoid remediation storms

## Dependency model

The remediator uses a ConfigMap-driven dependency graph stored in `dependency-model.yaml`.

- `api-server` has no dependencies
- `argocd` depends on `api-server`
- `prometheus` depends on `api-server`
- `webhook-system` depends on `api-server`
- `kyverno` depends on `api-server` and `webhook-system`
- `sentinel` depends on `prometheus`
- `remediator` depends on `api-server` and `argocd`

This model ensures remediation is only attempted when upstream dependencies are healthy.

## Guardrail layer

The remediator evaluates global control-plane health before taking action:
- verifies Kubernetes API server responsiveness
- verifies ArgoCD reachability
- verifies Prometheus availability

It also classifies failures and enters alert-only mode when:
- multiple critical subsystems fail simultaneously
- cluster-wide instability is detected
- severe degradation would make automated recovery unsafe

## Decision flow

```
Health check fails → evaluate guardrails
  ├─ cluster unstable or multiple severe failures → alert-only, no remediation
  └─ isolated failure and control plane healthy → remediate
      ├─ refresh ArgoCD Application
      ├─ refresh ApplicationSet
      └─ restart unhealthy Kyverno pods
```

## Failure mode classification

| Condition | Action |
|---|---|
| isolated Kyverno app/namespace/webhook/CRD issue | remediate |
| API server unreachable | alert-only |
| ArgoCD unreachable | alert-only |
| Prometheus unreachable | alert-only |
| multiple critical issues at once | alert-only |

## Alerting

The sentinel exposes Prometheus metrics and includes alert rules for:
- Kyverno Application missing
- Kyverno namespace missing
- Kyverno webhook missing
- Kyverno CRDs missing

Alerting is enabled via `PrometheusRule` and can be extended with Alertmanager or webhook receivers.

## GitOps management

The sentinel is managed via ArgoCD by including `k8s/security/sentinel` in the `ApplicationSet` path list.
