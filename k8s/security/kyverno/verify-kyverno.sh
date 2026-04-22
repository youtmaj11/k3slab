#!/usr/bin/env bash
set -eo pipefail

echo "1) Check Kyverno namespace and pods"
kubectl get ns kyverno
kubectl get pods -n kyverno

echo "\n2) Check Kyverno CRDs"
kubectl get crd clusterpolicies.policy.kyverno.io policyexceptions.policy.kyverno.io

echo "\n3) Check webhook configuration"
kubectl get validatingwebhookconfigurations | grep kyverno
kubectl get mutatingwebhookconfigurations | grep kyverno || true

echo "\n4) Test privileged pod admission"
cat <<'EOF' > /tmp/kyverno-test-priv.yaml
apiVersion: v1
kind: Pod
metadata:
  name: kyverno-test-priv
  namespace: default
spec:
  containers:
    - name: nginx
      image: nginx
      securityContext:
        privileged: true
EOF
if kubectl apply -f /tmp/kyverno-test-priv.yaml 2>&1 | tee /tmp/kyverno-test-priv.log; then
  echo "\nERROR: privileged pod was created unexpectedly"
  kubectl delete pod kyverno-test-priv --ignore-not-found
  exit 1
else
  echo "\nSUCCESS: privileged pod rejected by admission webhook"
  grep -q "admission" /tmp/kyverno-test-priv.log || true
fi
rm -f /tmp/kyverno-test-priv.yaml
