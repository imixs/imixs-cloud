#!/bin/bash
############################################################
# Script to generate the registry certificates
#
############################################################

echo "========================================================================="
echo "add a new user...."
echo "========================================================================="

if [ "$1" == "" ]
  then
    echo "password missing! (run with:  adduser.sh [USERID] [PASSWORD])"
    exit 0
fi


USER=$1
PASSWORD=$2
SCRIPTPATH="$( cd -- "$(dirname "$0")" >/dev/null 2>&1 ; pwd -P )"

echo "${USER}:$(openssl passwd -stdin -apr1 <<< ${PASSWORD})" >> $SCRIPTPATH/auth




echo "========================================================================="
echo "Generating new registry keys completed"
echo "========================================================================="
