#!/bin/bash

sudo service zebra start
sudo service zebra status
sudo service ospfd start
sudo service ospfd status


sudo systemctl is-enabled zebra.service
sudo systemctl is-enabled ospfd.service
sudo systemctl enable zebra.service
sudo systemctl enable ospfd.service

systemctl status bgpd
 
systemctl is-enabled bgpd
systemctl is-enabled ospf6d
systemctl is-enabled ripd
systemctl is-enabled ripngd
systemctl is-enabled isisd
 
systemctl disable bgpd
systemctl disable ospf6d
systemctl disable ripd
systemctl disable ripngd
systemctl disable isisd