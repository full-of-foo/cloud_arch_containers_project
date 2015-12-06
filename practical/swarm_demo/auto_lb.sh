#!/bin/bash
#===================================================================================
#
# FILE: auto_lb.sh
#
# USAGE: chmod +x ./auto_lb.sh && ./auto_lb.sh
#
# DESCRIPTION: Auto-configures and recreates the load balancer container for the
#              CA674 demo app (requires ./install.sh being ran first).
#
#===================================================================================

VM=swarm-master

function connectswarm {
    echo "Connecting to swarm environment..."
    eval "$(docker-machine env --swarm $VM)"
}

function teardown {
    echo "Tearing down old load balancer..."
    docker-compose -f lb.yml stop && docker-compose -f lb.yml rm --force
}

function auto_loadbalance {
    echo "Find front-end IP addresses and PORT.."
    LB=`docker ps | grep -E -o "(([0-9]{1,3}[\.]){3}[0-9]{1,3})[\:][0-9]{1,5}(->5000/tcp)" | sed 's/:/ /' | sed 's/->5000\/tcp//' | xargs`
    echo "Found: "$LB

    echo "Updating lb.yml file with front-end addresses..."
    sed -i -e 's/command:.*$/command: 80 '"$LB"'/' lb.yml

    echo "Running load balancer..."
    docker-compose -f lb.yml up -d

    URL=`docker ps | grep -E -o "(([0-9]{1,3}[\.]){3}[0-9]{1,3})(:80->80/tcp)" | sed 's/:80->80\/tcp//'`
    echo "System is operational. Access the URL: "$URL
}

connectswarm
teardown
auto_loadbalance
