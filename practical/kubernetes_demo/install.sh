#!/bin/bash
#===================================================================================
#
# FILE: install.sh
#
# USAGE: chmod +x ./install.sh && ./install.sh
#
# DESCRIPTION: TODO

#===================================================================================

wget https://storage.googleapis.com/kubernetes-release/release/v1.0.1/bin/linux/amd64/kubectl && \
  chmod +x kubectl && \
  sudo mv kubectl /usr/local/bin && \
  kubectl create -f ./kube/redis-master-service.yaml && \
  kubectl get services && \
  kubectl create -f ./kube/redis-master-controller.yaml && \
  kubectl get rc && \
  kubectl get pods && \
  #redis_port=`kubectl get -o yaml service/redis-master | grep -o "nodePort: [0-9]*" | tr -d 'nodePort: '` && \
  kubectl create -f ./kube/frontend-service.yaml && \
  kubectl get services && \
  #sed -i "s/EXPOSED_PORT/$redis_port/" kube/frontend-controller.yaml && \
  kubectl create -f ./kube/frontend-controller.yaml && \
  kubectl get rc && \
  kubectl get pods -l tier
