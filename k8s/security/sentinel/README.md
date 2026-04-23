# Kyverno Health Sentinel

This folder contains a Kubernetes-native health sentinel for Kyverno bootstrap and runtime availability.

## Detection flow

A CronJob runs every 15 minutes and performs the following checks:

- ArgoCD `Application` named `kyverno` exists in namespace `gitops`
- Kubernetes namespace `kyverno` exists
- Kyverno pods `kyverno-admission-controller` and `kyverno-background-controller` are present
- Kyverno CRDs exist: `clusterpolicies.policy.kyverno.io`, `policyexceptions.policy.kyverno.io`
- Kyverno validating webhook configuration exists

If any check fails, the CronJob exits with status `1`, and the failure is visible in the Job logs.

## Failure mode coverage

| Failure mode | Detection |
|---|---|
| Kyverno app missing | `kubectl get application kyverno -n gitops` |
| Kyverno namespace missing | `kubectl get namespace kyverno` |
| Kyverno pods not running | `kubectl get pod -n kyverno ...` |
| Kyverno CRDs absent | `kubectl get crd ...` |
| Webhook not registered | `kubectl get validatingwebhookconfigurations | grep kyverno` |

## Optional alerting

This CronJob logs failures in Kubernetes Job status and Pod logs. For alerting, integrate with a log scraper or Prometheus Event exporter.

## GitOps management

The sentinel is managed via ArgoCD by including `k8s/security/sentinel` in the `ApplicationSet` path list.
