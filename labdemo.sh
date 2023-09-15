#!/bin/bash

if [ ! -d "/users/Pavani/Lab2/OSPF_Orchestrator" ];
then
    git clone --quiet git@github.com:PavaniKRao/OSPF_Orchestrator.git
fi

cd OSPF_Orchestrator

Help()
{
   # Display Help
   echo 
   echo "Usage:      ./labdemo -FLAG"
   echo
   echo "Supported flags with this script are: [-h|n|i|b|r|c|e|p|a|t|w]"
   echo "----------------------------------------------"
   echo
   echo "flags usage:"
   echo "h    Print this Help."
   echo "n    Create Docker networks"
   echo "i    List and Insapect all docker networks"
   echo "b    Build Docker Containers for the 2 node and 3 router topology"
   echo "r    Run Docker Containers to build the 2 node and 3 router topology"
   echo "c    Checking running Docker Containers"
   echo "e    Execute running Docker containers with necessary OSPF configuration. \
   Each container runs in a separate detached tmux session."
   echo "p    Ping from hosta to hostb and check tcpdump on router2. \
   Since you are in the tmux session of router2, please use Ctrl+b and s key to jump between sessions. \
   Check succesful ping messages on session hosta. To exit tmux press Ctrl+b and d."
   echo "a    Add router4 to the existing 2 node and 3 router topology. \
   You can check running containers again using the -c flag."
   echo "t    Check tcpdump on router4. Since you are in the tmux session of router4, \
   please use Ctrl+b and s key to jump between sessions. To exit tmux press Ctrl+b and d."
   echo "w    Change route from via router2 to via router4."
   echo 
   echo "----------------------------------------------"
}

DockerCreateNetwork()
{
    echo
    echo "Creating required networks for the topology. The system will be first pruned. Please wait."
    echo "=========================================================================================="
    echo
    docker kill $(docker ps -q)
    docker network prune -f
    ./create_dockernetworks.sh
    echo
    echo "Networks are now created. Please check using the -i flag."
    echo
}

DockerInspectNetwork()
{
    echo
    echo "The Network details are:"
    echo "========================"
    echo
    docker network ls
    ./inspect_dockernetworks.sh
    echo
    echo "Go ahead and build servers using the -b flag."
    echo
}

DockerBuild()
{
    echo
    echo "Building servers for the 2 node and 3 router topology. The system will be first pruned. Please wait."
    echo "===================================================================================================="
    echo
    docker-compose build
    echo
    echo "Servers are ready to start. Please run using the -r flag."
    echo
}

DockerRun()
{
    echo
    echo "Starting servers for the 2 node and 3 router topology. The system will be first pruned. Please wait."
    echo "===================================================================================================="
    echo
    docker stop $(docker ps -q)
    docker rm $(docker ps -q)
    docker-compose down
    docker-compose up -d
    echo
    echo "Servers are now created. Please check using the -c flag."
    echo
}

DockerCheck()
{
    echo
    echo "The Servers are:"
    echo "================"
    echo
    docker ps
    echo
    echo "To go ahead with the OSPF configurations on the server, use flag -e"
    echo
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
    echo 
    echo "Below are the tmux sessions for each topology node. Feel free to attach and check."
    echo "=================================================================================="
    echo
    tmux ls
    echo
    echo "To ping check the hosts, use -p flag."
    echo
}

Ping()
{
    echo
    echo "Please wait while the servers are ready for ping. It might take close to 50s."
    echo
    echo "Once the servers are ready, you'll be inside router2 tmux session with tcpdump running. \
    Check the ICMP packets. Use Ctrl+b and s keys to switch to hosta session and see successful pings to hostb."
    echo
    echo "You must exit all tmux sessions to proceed further using Ctrl+b and d keys."
    echo
    echo "To add router4 in next stage, use -a flag."
    echo
    sleep 50
    tmux send -t hosta "ping 20.0.4.20" ENTER
    tmux send -t router2 "tcpdump -i eth0" ENTER
    tmux attach -t router2
    
}

AddRouter4()
{
    echo
    echo "Adding router4 to the 2 node and 3 router topology. The system will be first pruned. Please wait."
    echo "================================================================================================="
    echo
    docker stop router4
    docker rm router4
    docker pull pavani181/quagga_ubuntu20.04:4.0
    docker run -itd --cap-add=ALL --network=net_14 --ip 20.0.5.20 --name router4 pavani181/quagga_ubuntu20.04:2.0 sh
    docker network connect --ip 20.0.6.10 net_43 router4
    docker start router4
    docker cp service_r4.sh $(sudo docker ps -aqf "name=router4"):/
    
    tmux has-session -t router4 2>/dev/null

    if [ $? != 0 ]; then
        tmux new-session -d -s "router4"
        tmux send -t router4 "docker exec -it $(sudo docker ps -aqf "name=router4") /bin/bash" ENTER
    fi
    tmux kill-session -t router4
    tmux new-session -d -s "router4"
    tmux send -t router4 "docker exec -it $(sudo docker ps -aqf "name=router4") /bin/bash" ENTER
    # tmux send -t router4 "chmod +x service_r4.sh" ENTER
    # tmux send -t router4 "./service_r4.sh" ENTER
    echo
    echo "Router4 is created and added to the topology with necessary OSPF configurations. \
    Check tcpdump on it using -t flag. \
    You should see NO ICMP packets in there.\
    Remember: You must exit all tmux sessions to proceed further using Ctrl+b and d keys."
    echo
}

R4tcpdump()
{
    echo 
    echo "To change route to via router4, use -w flag."
    echo
    tmux send -t router4 "tcpdump -i eth0" ENTER
    tmux attach -t router4

}

ChangeRoute()
{
    tmux has-session -t router4_2 2>/dev/null

    if [ $? != 0 ]; then
        tmux new-session -d -s "router4_2"
        tmux send -t router4_2 "docker exec -it $(sudo docker ps -aqf "name=router4") /bin/bash" ENTER
    fi
    tmux kill-session -t router4_2
    tmux new-session -d -s "router4_2"
    tmux send -t router4_2 "docker exec -it $(sudo docker ps -aqf "name=router4") /bin/bash" ENTER
    tmux send -t router4_2 "chmod +x ./service_r4.sh" ENTER
    tmux send -t router4_2 "./service_r4.sh" ENTER
    echo
    echo "Please wait while the OSPF is reconfiguring to change route to via r4. It might take close to 40s."
    echo
    echo "Once the route has been changed, you'll be taken back to router4 tcpdump session to find ICMP packets. \
    Use Ctrl+b and s keys to switch to router2 tcpdump session to see NO ICMP packets now."
    echo
    sleep 20

    tmux send -t router4_2 "vtysh" ENTER
    sleep 5
    tmux send -t router4_2 "configure terminal" ENTER
    sleep 2
    tmux send -t router4_2 "interface eth0" ENTER
    sleep 2
    tmux send -t router4_2 "ip ospf cost 5" ENTER
    sleep 2
    tmux send -t router4_2 "exit" ENTER
    sleep 2
    tmux send -t router4_2 "interface eth1" ENTER
    sleep 2
    tmux send -t router4_2 "ip ospf cost 5" ENTER
    sleep 2
    tmux send -t router4_2 "exit" ENTER
    sleep 2
    tmux send -t router4_2 "exit" ENTER
    sleep 2
    #tmux send -t router4_2 "tcpdump -i eth0" ENTER
    tmux attach -t router4
    
}

while getopts "hnibrcepatw" flag; do
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
        p)
        Ping
        ;;
        a)
        AddRouter4
        ;;
        t)
        R4tcpdump
        ;;
        w)
        ChangeRoute
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