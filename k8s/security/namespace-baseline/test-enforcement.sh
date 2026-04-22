#!/usr/bin/env bash
set -eo pipefail

echo "1) Test namespace creation without required labels"
cat <<'EOF' | kubectl apply -f - || true
apiVersion: v1
kind: Namespace
metadata:
  name: ns-baseline-test-fail
EOF

echo "Expected: namespace creation denied because required labels are missing."

echo "\n2) Create namespace with required labels"
cat <<'EOF' | kubectl apply -f -
apiVersion: v1
kind: Namespace
metadata:
  name: ns-baseline-test
  labels:
    app: test-app
    owner: dev-team
    environment: test
EOF

echo "Namespace created. Waiting for Kyverno generated baseline resources..."
sleep 5

kubectl get namespace ns-baseline-test
kubectl get networkpolicy default-deny -n ns-baseline-test
kubectl get role namespace-baseline -n ns-baseline-test
kubectl get rolebinding namespace-baseline-binding -n ns-baseline-test

echo "\n3) Verify baseline enforcement on an existing namespace"
cat <<'EOF' | kubectl apply -f -
apiVersion: v1
kind: Namespace
metadata:
  name: ns-baseline-test2
  labels:
    app: test-app
    owner: dev-team
    environment: test
EOF

sleep 5
kubectl get networkpolicy default-deny -n ns-baseline-test2
kubectl get role namespace-baseline -n ns-baseline-test2
kubectl get rolebinding namespace-baseline-binding -n ns-baseline-test2

echo "\nNamespace baseline enforcement test completed."
