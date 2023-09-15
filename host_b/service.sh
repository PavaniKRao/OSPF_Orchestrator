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

/bin/cat << EOF > /etc/quagga/ospfd.conf
hostname hostb
!password zebra
!enable password please-set-at-here
log file /var/log/quagga/ospfd.log
router ospf
  ospf router-id 20.0.4.20
  log-adjacency-changes
  redistribute kernel
  redistribute connected
  redistribute static
  network 20.0.4.0/24 area 2 stub
!
access-list 20 permit 20.0.1.0 0.0.0.255
access-list 21 permit 20.0.2.0 0.0.0.255
access-list 22 permit 20.0.3.0 0.0.0.255
access-list 23 permit 20.0.5.0 0.0.0.255
access-list 24 permit 20.0.6.0 0.0.0.255
access-list 25 deny any
!
line vty
!
EOF

/bin/cat << EOF > /etc/quagga/zebra.conf
hostname hostb
password zebra
enable password zebra
log file /var/log/quagga/zebra.log
!
! Interface's description.
!
!interface lo
! description test of desc.
!
!interface sit0
! multicast

!
! Static default route sample.
!
!ip route 0.0.0.0/0 203.181.89.241
!

!log file zebra.log
line vty
!
EOF

service zebra restart
service ospfd restart