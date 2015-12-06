#!/bin/bash
#===================================================================================
#
# FILE: install.sh
#
# USAGE: chmod +x ./install.sh && ./install.sh
#
# DESCRIPTION: Tears down an existing Swarm hosts and
#              provisions a fresh cluster.

#===================================================================================

VM=local

function provision_machines {
    echo "Entering $VM machine..."
    docker-machine status $VM || docker-machine create -d virtualbox $VM && sleep 2
    docker-machine start $VM && sleep 2
    eval "$(docker-machine env $VM)"

    echo "Creating key-value store machine..."
    docker-machine create -d virtualbox keystore

    echo "Running Consul discovery service..."
    docker $(docker-machine config keystore) run -d -p "8500:8500" -h "consul" progrium/consul -server -bootstrap

    echo "Creating Swarm master..."
    docker-machine create -d virtualbox --swarm --swarm-master --swarm-discovery="consul://$(docker-machine ip keystore):8500" --engine-opt="cluster-store=consul://$(docker-machine ip keystore):8500" --engine-opt="cluster-advertise=eth1:2376" swarm-master

    echo "Creating Swarm node 01..."
    docker-machine create -d virtualbox --swarm --swarm-discovery="consul://$(docker-machine ip keystore):8500" --engine-opt="cluster-store=consul://$(docker-machine ip keystore):8500" --engine-opt="cluster-advertise=eth1:2376" swarm-node-01

    echo "Creating Swarm node 02..."
    docker-machine create -d virtualbox --swarm --swarm-discovery="consul://$(docker-machine ip keystore):8500" --engine-opt="cluster-store=consul://$(docker-machine ip keystore):8500" --engine-opt="cluster-advertise=eth1:2376" swarm-node-02

    echo "Creating overlay network..."
    eval "$(docker-machine env --swarm swarm-master)"
    docker network create --driver overlay ca674_net
}

function start_services {
    echo "Start the back-end container..."
    docker run -itd --name=redis --net=ca674_net redis

    echo "Start the front-end container..."
    docker-compose -f www.yml up -d

    echo "Scale-up the front-end to 2 instances..."
    docker-compose -f www.yml scale www=2

    echo "Find front-end IP addresses and PORT.."
    LB=`docker ps | grep -E -o "(([0-9]{1,3}[\.]){3}[0-9]{1,3})[\:][0-9]{1,5}(->5000/tcp)" | sed 's/:/ /' | sed 's/->5000\/tcp//' | xargs`
    echo "Found: " $LB
    echo "Updating lb.yml file with front-end addresses..."
    sed -i -e 's/command:.*$/command: 80 '"$LB"'/' lb.yml

    echo "Starting load balancer..."
    docker-compose -f lb.yml up -d

    URL=`docker ps | grep -E -o "(([0-9]{1,3}[\.]){3}[0-9]{1,3})(:80->80/tcp)" | sed 's/:80->80\/tcp//'`
    echo "System is operational. Access the URL: "$URL
}

function teardown_swarm_machines {
  echo "Removing old Swarm machines..."
  docker-machine status keystore && docker-machine rm -f keystore
  docker-machine status swarm-master && docker-machine rm -f swarm-master
  docker-machine status swarm-node-01 && docker-machine rm -f swarm-node-01
  docker-machine status swarm-node-02 && docker-machine rm -f swarm-node-02
}

teardown_swarm_machines
provision_machines
start_services
read a