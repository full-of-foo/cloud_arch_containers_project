#!/bin/bash
#===================================================================================
#
# FILE: install.sh
#
# USAGE: chmod +x ./install.sh && ./install.sh
#
# DESCRIPTION: Creates a Docker Swarm cluster with a discovery service node (Consul),
#              a master and two slave nodes and runs the CA674 demo app on top of it.
#              The CA674 demo is comprised of a back-end store (redis) and front-end
#              www implementation (python) scaled to initially two instances.
#              A load balancer is used to randomize access to each front-end container
#              and unify the entry point of the app.
#
#===================================================================================

function teardown_swarm_machines {
  echo "Removing old Swarm machines..."
  docker-machine stop keystore
  docker-machine stop swarm-master
  docker-machine stop swarm-node-01
  docker-machine stop swarm-node-02
  docker-machine rm -f keystore
  docker-machine rm -f swarm-master
  docker-machine rm -f swarm-node-01
  docker-machine rm -f swarm-node-02
}

function provision_machines {
    echo "Creating key-value store machine..."
    docker-machine create -d virtualbox keystore

    echo "Running Consul discovery service..."
    docker $(docker-machine config keystore) run -d -p "8500:8500" -h "consul" progrium/consul -server -bootstrap

    echo "Creating Swarm master..."
    docker-machine create -d virtualbox --swarm --swarm-master --swarm-discovery="consul://$(docker-machine ip keystore):8500" --engine-opt="cluster-store=consul://$(docker-machine ip keystore):8500" --engine-opt="cluster-advertise=eth1:2376" swarm-master && sleep 2
    docker-machine start swarm-master && sleep 20

    echo "Creating Swarm node 01..."
    docker-machine create -d virtualbox --swarm --swarm-discovery="consul://$(docker-machine ip keystore):8500" --engine-opt="cluster-store=consul://$(docker-machine ip keystore):8500" --engine-opt="cluster-advertise=eth1:2376" swarm-node-01 && sleep 2
    docker-machine start swarm-node-01 && sleep 2

    echo "Creating Swarm node 02..."
    docker-machine create -d virtualbox --swarm --swarm-discovery="consul://$(docker-machine ip keystore):8500" --engine-opt="cluster-store=consul://$(docker-machine ip keystore):8500" --engine-opt="cluster-advertise=eth1:2376" swarm-node-02 && sleep 2
    docker-machine start swarm-node-02 && sleep 2

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

function finishtobash {
    echo "Finishing up. Setting environment variables for machine swarm-master..."
    eval "$($DOCKER_MACHINE env --swarm swarm-master)"
    
    clear
    echo "CA674 - Docker Swarm demo app running on "$URL
    echo "use 'docker ps' to see the running containers"
    exec "$BASH" --login -i
}

teardown_swarm_machines
provision_machines
start_services
finishtobash