#!/bin/bash

kubectl delete daemonset -n kube-system aws-node

kubectl apply -f ./scripts/calico-vxlan.yaml

