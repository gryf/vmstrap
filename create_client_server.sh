#!/usr/bin/env bash

function wait_for {
    local command=$1
    local amount=$2
    while true; do
        if eval "${command}"; then
            break;
        fi
        sleep "${amount}"
    done
}

kubectl create namespace foo
kubectl run --image kuryr/demo -n foo server
wait_for "kubectl get pod -A |grep server|grep -q Running" 1
kubectl expose pod/server -n foo --port 80 --target-port 8080 --name=foosrvr
sleep 6
wait_for "openstack loadbalancer list -f value -c name -c provisioning_status | grep foosrvr | grep -q ACTIVE" 4
kubectl run --image kuryr/demo -n foo client
wait_for "kubectl get pod -A |grep client|grep -q Running" 1
kubectl exec -ti -n foo client -- wget http://server.foo -q -O -
cat > policy_foo_deny_all.yaml << NIL
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: deny-all
  namespace: foo
spec:
  podSelector: {}
  policyTypes:
    - Ingress
NIL
kubectl apply -f policy_foo_deny_all.yaml
