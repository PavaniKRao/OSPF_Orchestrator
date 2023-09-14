#!/bin/bash

if [ ! -d "/users/Pavani/Lab2/OSPF_Orchestrator" ];
then
    git clone --quiet https://github.com/PavaniKRao/OSPF_Orchestrator.git
fi

cd OSPF_Orchestrator

Help()
{
   # Display Help
   echo 
   echo "Usage:      ./labdemo -FLAG"
   echo
   echo "Supported flags with this script are: [-h|n|i|b|r|c]"
   echo "----------------------------------------------"
   echo
   echo "flags usage:"
   echo "h    Print this Help."
   echo "n    Create Docker networks"
   echo "i    Inspect all docker networks"
   echo "b    Build Docker Containers"
   echo "r    Run Docker Containers"
   echo "c    Checking running Docker Containers"
   echo 
   echo "----------------------------------------------"
}

DockerCreateNetwork()
{
    docker network prune -f
    ./create_dockernetworks.sh
}

DockerInspectNetwork()
{
    ./inspect_dockernetworks.sh
}

DockerBuild()
{
    docker-compose build
}

DockerRun()
{
    docker kill $(docker ps -q)
    docker-compose down
    docker-compose up -d
}

DockerCheck()
{
    docker ps
}

while getopts "hnibrc" flag; do
    case "${flag}" in
        h) 
        Help
        ;;
        n)
        DockerCreateNetwork
        ;;
        i) 
        DockerInspectNetwork
        ;;
        b) 
        DockerBuild
        ;;
        r)
        DockerRun
        ;;
        c)
        DockerCheck
        ;;
        *)
        echo
        echo "Incorrect flag!"
        Help
        ;;
    esac
done

if [ $# -eq 0 ];
then
    echo 
    echo "Please run with appropriate flag!"
    Help
    exit 0
fi
