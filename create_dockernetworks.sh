#!/bin/bash

docker network create -d bridge net_a1 --subnet=20.0.1.0/24
docker network create -d bridge net_12 --subnet=20.0.2.0/24
docker network create -d bridge net_23 --subnet=20.0.3.0/24
docker network create -d bridge net_3b --subnet=20.0.4.0/24
docker network create -d bridge net_14 --subnet=20.0.5.0/24
docker network create -d bridge net_43 --subnet=20.0.6.0/24