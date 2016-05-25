#!/usr/bin/env bash

set -e

docker-machine create -d google \
    --google-project silken-zenith-132017 \
    proxy

export DOCKER_IP=$(docker-machine ip proxy)
export CONSUL_IP=$(docker-machine ip proxy)
export CONSUL_INTERNAL=$(gcloud compute instances describe proxy --format=text     | grep '^networkInterfaces\[[0-9]\+\]\.networkIP:' | sed 's/^.* //g')
export GOOGLE_PROJECT_NAME=silken-zenith-132017

eval "$(docker-machine env proxy)"

docker-compose up -d consul-server

sleep 2

docker-compose up -d proxy

docker-machine create -d google \
    --google-project $GOOGLE_PROJECT_NAME \
    --swarm --swarm-master \
    --swarm-discovery="consul://$CONSUL_IP:8500" \
    --engine-opt="cluster-store=consul://$CONSUL_IP:8500" \
    --engine-opt="cluster-advertise=eth0:2376" \
    swarm-master

docker-machine create -d google \
    --google-project $GOOGLE_PROJECT_NAME \
    --swarm \
    --swarm-discovery="consul://$CONSUL_IP:8500" \
    --engine-opt="cluster-store=consul://$CONSUL_IP:8500" \
    --engine-opt="cluster-advertise=eth0:2376" \
    swarm-node-1

docker-machine create -d google \
    --google-project $GOOGLE_PROJECT_NAME \
    --swarm \
    --swarm-discovery="consul://$CONSUL_IP:8500" \
    --engine-opt="cluster-store=consul://$CONSUL_IP:8500" \
    --engine-opt="cluster-advertise=eth0:2376" \
    swarm-node-2

eval "$(docker-machine env swarm-master)"

export DOCKER_IP=$(docker-machine ip swarm-master)

docker-compose up -d registrator

eval "$(docker-machine env swarm-node-1)"

export DOCKER_IP=$(docker-machine ip swarm-node-1)

docker-compose up -d registrator

eval "$(docker-machine env swarm-node-2)"

export DOCKER_IP=$(docker-machine ip swarm-node-2)

docker-compose up -d registrator
