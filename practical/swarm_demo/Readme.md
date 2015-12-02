Demo: Swarm Clustering
===
This demo will show the docker swarm in action! We use the new networking features plus swarm to deploy a fully fledged application with a data store (in redis), a web interface (python) and a manual load balancer (nothing is perfect!).

Bootstrapping
---
Download and install Docker Toolbox v1.9.0c (https://github.com/docker/toolbox/releases)

1) Create key value store
docker-machine create -d virtualbox keystore

2) Run discovery service
docker $(docker-machine config keystore) run -d \
    -p "8500:8500" \
    -h "consul" \
    progrium/consul -server -bootstrap

3) Create swarm cluster
docker-machine create \
-d virtualbox \
--swarm --swarm-master \
--swarm-discovery="consul://$(docker-machine ip keystore):8500" \
--engine-opt="cluster-store=consul://$(docker-machine ip keystore):8500" \
--engine-opt="cluster-advertise=eth1:2376" \
swarm-master

4) Create two nodes
docker-machine create -d virtualbox \
    --swarm \
    --swarm-discovery="consul://$(docker-machine ip keystore):8500" \
    --engine-opt="cluster-store=consul://$(docker-machine ip keystore):8500" \
    --engine-opt="cluster-advertise=eth1:2376" \
  swarm-node-01

docker-machine create -d virtualbox \
    --swarm \
    --swarm-discovery="consul://$(docker-machine ip keystore):8500" \
    --engine-opt="cluster-store=consul://$(docker-machine ip keystore):8500" \
    --engine-opt="cluster-advertise=eth1:2376" \
  swarm-node-02

5) Create overlay network
eval $(docker-machine env --swarm swarm-master)cd d
docker network create --driver overlay ca674_net

6) Create the redis data store (must specify the network - created above)
docker run -itd --name=redis --net=ca674_net redis

7) Run and scale the www frontend (in 4 instances)
VIA DOCKER-COMPOSE
docker-compose -f www.yml up -d
docker-compose -f www.yml scale www=4

OR (directly via docker run as many times as you want)
docker run -itd --publish-all --net=ca674_net magrossi/ca674_demo_app

8) Get all www instances and ports and add it to the command in the lb.yml file
$ docker ps
> CONTAINER ID        IMAGE                     COMMAND                  CREATED             STATUS              PORTS                            NAMES
> 970aaf3edc0d        magrossi/ca674_demo_app   "/bin/sh -c 'gunicorn"   1 seconds ago       Up 1 seconds        192.168.99.103:32776->5000/tcp   swarm-node-01/clever_bardeen
> 55674487925d        magrossi/ca674_demo_app   "/bin/sh -c 'gunicorn"   2 seconds ago       Up 2 seconds        192.168.99.102:32773->5000/tcp   swarm-master/stupefied_perlman
> c800cf08f6a7        redis                     "/entrypoint.sh redis"   2 minutes ago       Up 2 minutes        6379/tcp                         swarm-node-01/redis

In the above example you would need to edit the lb.yml to be:
lb:
  image: jpetazzo/hamba
  command: 80 192.168.99.103 32776 192.168.99.102 32773
  mem_limit: 50000000
  ports:
    - "80:80"

9) Run the load balancer through docker-compose
docker-compose -f lb.yml up -d

10) Check the system by opening the web page (lb machine ip address on port 80)
Have fun!
