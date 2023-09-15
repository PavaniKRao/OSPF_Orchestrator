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
   echo "Supported flags with this script are: [-h|n|i|b|r|c|a]"
   echo "----------------------------------------------"
   echo
   echo "flags usage:"
   echo "h    Print this Help."
   echo "n    Create Docker networks"
   echo "i    Inspect all docker networks"
   echo "b    Build Docker Containers for a 2 node and 3 router topology"
   echo "r    Run Docker Containers to build a 2 node and 3 router topology"
   echo "c    Checking running Docker Containers"
   echo "a    Add router4 to the existing 2 node and 3 router topology. You can check running containers again using the -c flag."
   echo 
   echo "----------------------------------------------"
}

DockerCreateNetwork()
{
    docker kill $(docker ps -q)
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

AddRouter4()
{
    docker rm $(docker ps -a -q)
    docker pull pavani181/quagga_ubuntu20.04:1.0
    docker run -itd --cap-add=ALL --network=net_14 --ip 20.0.5.20 --name router4 pavani181/quagga_ubuntu20.04:2.0 sh
    docker network connect --ip 20.0.6.10 net_43 router4
    docker start router4
    tmux new-session -d -s "router4"
}

LaunchNodes()
{
    for i in a b
    do 
        tmux new-session -d -s "host$i"
        tmux send -t host$i "docker exec -it $(sudo docker ps -aqf "name=host$i") /bin/bash" ENTER
    done

    for j in 1 2 3
    do
        tmux new-session -d -s "router$j"
        tmux send -t router$j "docker exec -it $(sudo docker ps -aqf "name=router$j") /bin/bash" ENTER
    done
}

while getopts "hnibrca" flag; do
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
        a)
        AddRouter4
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