#!/bin/sh

############################################################
# kubectl apply script
# 
# run
# $ scripts/apply.sh APP-CONTEXT
############################################################


if [ $# -eq 0 ]
  then
    echo "*** no arguments supplied - application context expected!"
    exit 0
  else
    echo "*** app context: $1"
    APP_CONTEXT=$1
fi  

for entry in "$APP_CONTEXT"*
do
#  echo "$entry"
   kubectl apply -f $entry
done
