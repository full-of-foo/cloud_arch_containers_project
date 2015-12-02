#!/bin/bash
#===================================================================================
#
# FILE: install.sh
#
# USAGE: chmod +x ./install.sh && ./install.sh
#
# DESCRIPTION: Install script to be ran on a kube-host machine instance. This machines
#   conceptually acts a 'cluster' management machine from which cluster orchestration
#   is done. In this local case, we install the cluster onto the same host machine.
#
#===================================================================================

wget https://storage.googleapis.com/kubernetes-release/release/v1.0.1/bin/linux/amd64/kubectl && \
  chmod +x kubectl && \
  sudo mv kubectl /usr/local/bin && \
  kubectl create -f ./kube/redis-master-service.yaml && \
  kubectl get services && \
  kubectl create -f ./kube/redis-master-controller.yaml && \
  kubectl get rc && \
  kubectl get pods && \
  kubectl create -f ./kube/frontend-service.yaml && \
  kubectl get services && \
  kubectl create -f ./kube/frontend-controller.yaml && \
  kubectl get rc && \
  kubectl get pods -l tier
