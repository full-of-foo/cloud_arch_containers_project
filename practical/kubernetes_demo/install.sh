#!/bin/bash
#===================================================================================
#
# FILE: install.sh
#
# USAGE: chmod +x ./install.sh && ./install.sh
#
# DESCRIPTION: TODO

#===================================================================================

wget https://storage.googleapis.com/kubernetes-release/release/v0.19.3/bin/linux/amd64/kubectl && \
  chmod +x kubectl && \
  sudo mv kubectl /usr/local/bin && \
  kubectl create -f ./kube/redis-master-service.yaml && \
  kubectl get services && \
  kubectl create -f ./kube/redis-master-controller.yaml && \
  kubectl get rc && \
  kubectl get pods && \
  kubectl create -f ./kube/redis-slave-service.yaml && \
  kubectl get services && \
  kubectl create -f ./kube/redis-slave-controller.yaml && \
  kubectl get rc && \
  kubectl get pods #&& \
  kubectl create -f ./kube/frontend-service.yaml && \
  kubectl get services && \
  kubectl create -f ./kube/frontend-controller.yaml && \
  kubectl get rc && \
  kubectl get pods -l tier
