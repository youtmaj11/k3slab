#!/usr/bin/env bash
set -eo pipefail

echo "1) Apply a Pod with privileged container and expect audit / rejection in enforce mode"
cat <<'EOF' | kubectl apply -f - || true
apiVersion: v1
kind: Pod
metadata:
  name: kyverno-test-privileged
  namespace: default
spec:
  containers:
    - name: busybox
      image: busybox
      command: ["sleep", "3600"]
      securityContext:
        privileged: true
EOF

echo "\n2) Apply a Pod without resource limits and expect audit / rejection in enforce mode"
cat <<'EOF' | kubectl apply -f - || true
apiVersion: v1
kind: Pod
metadata:
  name: kyverno-test-no-limits
  namespace: default
spec:
  containers:
    - name: busybox
      image: busybox
      command: ["sleep", "3600"]
      securityContext:
        runAsNonRoot: true
EOF

echo "\n3) Apply a Pod using hostPath volume and expect audit / rejection in enforce mode"
cat <<'EOF' | kubectl apply -f - || true
apiVersion: v1
kind: Pod
metadata:
  name: kyverno-test-hostpath
  namespace: default
spec:
  containers:
    - name: busybox
      image: busybox
      command: ["sleep", "3600"]
  volumes:
    - name: hostpath-volume
      hostPath:
        path: /tmp
        type: DirectoryOrCreate
EOF

echo "\n4) Create a namespace without required labels and expect audit / rejection in enforce mode"
cat <<'EOF' | kubectl apply -f - || true
apiVersion: v1
kind: Namespace
metadata:
  name: kyverno-namespace-test
EOF

echo "\n5) Create a namespace with required labels and validate baseline enforcement"
cat <<'EOF' | kubectl apply -f -
apiVersion: v1
kind: Namespace
metadata:
  name: kyverno-namespace-valid
  labels:
    app: platform
    owner: sec-team
    environment: test
EOF

echo "\nReview these resources and Kyverno audit events to verify policy behavior."
