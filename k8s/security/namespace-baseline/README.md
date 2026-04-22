# Namespace Baseline Enforcement

This folder contains Kyverno policies that enforce a common security baseline for namespaces in the k3s cluster.

Baseline requirements:
- every namespace must have labels: `app`, `owner`, and `environment`
- every non-system namespace automatically gets a `default-deny` NetworkPolicy
- every non-system namespace automatically receives a minimal namespace-local Role and RoleBinding
- namespace creation is rejected if it violates label validation
- existing namespaces are reconciled through Kyverno background processing
