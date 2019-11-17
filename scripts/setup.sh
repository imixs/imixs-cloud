#!/bin/bash
 
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

# Check advertise-addr

if [ $# -eq 0 ]
  then
    echo "No arguments supplied"
    echo "*** Setup failed: advertise-addr is missing! ( setup.sh [SERVER-IP])"

    exit 0
fi

# Run as root
echo "========================================================================="
echo " adding repositories..."
echo "========================================================================="
apt-get update
apt-get install -y apt-transport-https ca-certificates ne curl gnupg2 software-properties-common

# Add docker repositry
curl -fsSL https://download.docker.com/linux/debian/gpg | apt-key add -
add-apt-repository \
          "deb [arch=amd64] https://download.docker.com/linux/debian \
           $(lsb_release -cs) \
           stable"
           

echo "========================================================================="
echo " installing docker..."
echo "========================================================================="
apt-get update
apt-get install -y docker-ce docker-ce-cli containerd.io

# add current user to docker group
adduser $userid docker

echo "========================================================================="
echo " init docker-swarm manager node..."
echo "========================================================================="
docker swarm init --advertise-addr $1


echo " adding default overlay network 'imixs-cloud-net' ...."
docker network create --driver=overlay imixs-cloud-net
