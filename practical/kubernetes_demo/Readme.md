Demo: Kubernetes Clustering
===
TODO - describe application (what it does and what it aims to demonstrate)

Bootstrapping
---
1. Download and install Docker Toolbox v1.9.0c (https://github.com/docker/toolbox/releases)

2. Create a controller machine, `docker-machine status default || docker-machine create -d virtualbox default && sleep 1`

3. Point your Docker engine to the default controller machine, `eval $(docker-machine env default)`

4. Get the Kubernetes cluster installed and running, `docker-compose up -d`

5. Install the pods
```
docker-machine scp -r kube/ default:./kube && \
docker-machine scp install.sh default:./install.sh && \
docker-machine ssh default "chmod +x ./install.sh && sh ./install.sh"
```
