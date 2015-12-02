Demo: Kubernetes Clustering
===
TODO - describe application (what it does and what it aims to demonstrate)

Bootstrapping
---
1. Download and install Docker Toolbox v1.9.1b (https://github.com/docker/toolbox/releases/tag/v1.9.1b)

2. Create a controller machine, `docker-machine status kube-host || docker-machine create -d virtualbox --virtualbox-memory 4096 --virtualbox-cpu-count 2 kube-host && sleep 1`

3. Point your Docker engine to the kube-host controller machine, `eval $(docker-machine env kube-host)`

4. Get the Kubernetes cluster installed and running
```
docker stop $(docker ps -a -q) && \ # uncomment to stop all containers
docker rm -f $(docker ps -a -q) && \ # uncomment to clear all containers
docker-compose up --force-recreate -d
```
5. Install the pods
```
docker-machine ssh kube-host "rm -fr ./kube" && \
docker-machine scp -r kube/ kube-host:./kube && \
docker-machine scp install.sh kube-host:./install.sh && \
docker-machine ssh kube-host "chmod +x ./install.sh && sh ./install.sh"
```
6. Wait for all the pods to be running, `docker-machine ssh kube-host "kubectl get pods"`

7. Visit the application
```
port=`docker-machine ssh kube-host "kubectl get -o yaml service/frontend" | grep -o "nodePort: [0-9]*" | tr -d 'nodePort: '` && \
open http://$(docker-machine ip kube-host):$port
```
