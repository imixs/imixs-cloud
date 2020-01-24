#!/bin/sh

############################################################
# kubectl delete script
# 
# run
# $ scripts/delete.sh APP-CONTEXT
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
   kubectl delete -f $entry
done
