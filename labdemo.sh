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
   echo "Supported flags with this script are: [-h|n|i|b|r|c|e|p|a]"
   echo "----------------------------------------------"
   echo
   echo "flags usage:"
   echo "h    Print this Help."
   echo "n    Create Docker networks"
   echo "i    List and Insapect all docker networks"
   echo "b    Build Docker Containers for a 2 node and 3 router topology"
   echo "r    Run Docker Containers to build a 2 node and 3 router topology"
   echo "c    Checking running Docker Containers"
   echo "e    Execute running Docker containers with necessary OSPF configuration. Each container runs in a detached tmux sessions."
   echo "p    Ping from hosta to hostb and check tcpdump on router4"
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
    docker network ls
    ./inspect_dockernetworks.sh
}

DockerBuild()
{
    docker-compose build
}

DockerRun()
{
    docker stop $(docker ps -q)
    docker rm $(docker ps -q)
    docker-compose down
    docker-compose up -d
}

DockerCheck()
{
    docker ps
}

ExecuteDockerContainers()
{
    for i in a b
    do 
        tmux has-session -t host$i 2>/dev/null

        if [ $? != 0 ]; then
            tmux new-session -d -s "host$i"
            tmux send -t host$i "docker exec -it $(sudo docker ps -aqf "name=host$i") /bin/bash" ENTER
        fi
        tmux kill-session -t host$i
        tmux new-session -d -s "host$i"
        tmux send -t host$i "docker exec -it $(sudo docker ps -aqf "name=host$i") /bin/bash" ENTER
        tmux send -t host$i "chmod +x service.sh" ENTER
        tmux send -t host$i "./service.sh" ENTER
    done

    for j in 1 2 3
    do
        tmux has-session -t router$j 2>/dev/null

        if [ $? != 0 ]; then
            tmux new-session -d -s "router$j"
            tmux send -t router$j "docker exec -it $(sudo docker ps -aqf "name=router$j") /bin/bash" ENTER
        fi
        tmux kill-session -t router$j
        tmux new-session -d -s "router$j"
        tmux send -t router$j "docker exec -it $(sudo docker ps -aqf "name=router$j") /bin/bash" ENTER
        tmux send -t router$j "chmod +x service.sh" ENTER
        tmux send -t router$j "./service.sh" ENTER
    done
}

Ping()
{
    
}

AddRouter4()
{
    docker stop router4
    docker rm router4
    docker pull pavani181/quagga_ubuntu20.04:3.0
    docker run -itd --cap-add=ALL --network=net_14 --ip 20.0.5.20 --name router4 pavani181/quagga_ubuntu20.04:2.0 sh
    docker network connect --ip 20.0.6.10 net_43 router4
    docker start router4
    
    tmux has-session -t router4 2>/dev/null

    if [ $? != 0 ]; then
        tmux new-session -d -s "router4"
        tmux send -t router4 "docker exec -it $(sudo docker ps -aqf "name=router4") /bin/bash" ENTER
    fi
    tmux kill-session -t router4
    tmux new-session -d -s "router4"
    tmux send -t router4 "docker exec -it $(sudo docker ps -aqf "name=router4") /bin/bash" ENTER
}

while getopts "hnibrcea" flag; do
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
        e)
        ExecuteDockerContainers
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