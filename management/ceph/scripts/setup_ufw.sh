#!/bin/bash

############################################################
# setup ufw
############################################################

# determine if we run as sudo
userid="${SUDO_USER:-$USER}"
if [ "$userid" == 'root' ]
  then 
    echo "Please run the setup as sudo and not as root!"
    exit 1
fi
if [ "$EUID" -ne 0 ]
  then 
    echo "Please run setup as sudo!"
    exit 1
fi

ufw allow ssh
ufw allow 8443 comment 'allow dashboard'
ufw allow from 10.0.0.0/16

# Uncomment this to allow your kubernetes cluster to access your ceph nodes
# rreplace the public IPs
#ufw allow from x.y.a.b comment 'allow your ceph cluster nodes'
#ufw allow from x.y.a.c
#ufw allow from x.y.a.d


ufw default allow outgoing
ufw default deny incoming
ufw enable

# setup finished
#############################################################
