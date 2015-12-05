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

function provision_machines {
    echo "Entering dev machine..."
    docker-machine status dev || docker-machine create -d virtualbox dev && sleep 2
    docker-machine start dev && sleep 2
    eval "$(docker-machine env dev)"

    echo "Installing latest Swarm container..."
    TOKEN=`docker run --rm swarm create`
    echo "Got the token " $TOKEN

    echo "Creating Swarm master ..."
    docker-machine create -d virtualbox --swarm --swarm-master --swarm-discovery token://$TOKEN swarm-master
    echo "Creating Swarm node 01 ..."
    docker-machine create -d virtualbox --swarm --swarm-discovery token://$TOKEN swarm-node-01
    echo "Creating Swarm node 02 ..."
    docker-machine create -d virtualbox --swarm --swarm-discovery token://$TOKEN swarm-node-02
}

function teardown_swarm_machines {
  echo "Removing old Swarm machines..."
  docker-machine status swarm-master && docker-machine rm -f swarm-master
  docker-machine status swarm-node-01 && docker-machine rm -f swarm-node-01
  docker-machine status swarm-node-02 && docker-machine rm -f swarm-node-02
}

teardown_swarm_machines
provision_machines
