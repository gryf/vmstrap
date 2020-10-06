#!/usr/bin/env bash                                                                                                                                                                                         

kubectl -n foo delete networkpolicy deny_all
kubectl -n foo delete pod client
kubectl -n foo delete service foosrvr  # remove LB
kubectl -n foo delete pod server
kubectl delete namespace foo
