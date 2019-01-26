# Monitoring

This stack provides a Prometheus service and a Grafana Service integrated in Docker Swarm. Find general information about Docker and Prometeus [here](https://docs.docker.com/config/thirdparty/prometheus/). 


## How to Start

The montiroing stack is located in the Imixs-Cloud management node. Find more information how to setup [here](https://github.com/imixs/imixs-cloud/blob/master/doc/MONITORING.md). 

To start the monitoring service run:

	$ docker stack deploy -c management/monitoring/docker-compose.yml monitoring



