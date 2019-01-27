# How to Montior Imixs-Cloud

_Imixs-Cloud_ also provides a monitoring feature which allows you to monitor your docker-swarm.

<img src="./imixs-cloud-04.png" />

The following section describes how you can monitor Imixs-Cloud. The monitoring stack in Imixs-Cloud provices the following services:

 * Prometheus - the prometheus main service configured for docker-swarm.
 * Node-Exporter - a prometheus service which provides the machine data from every node in your docker-swarm.
 * Grafana - the monitoring dashboard connected to prometheus.

## Prometheus

[Prometheus](https://prometheus.io/) is an open-source systems monitoring and alerting toolkit. 
The Prometheus service can be integrated in Docker Swarm to monitor your Docker instance. You can find general information about Docker and Prometeus [here](https://docs.docker.com/config/thirdparty/prometheus/). 

### Configuration

Prometheus is already configured in the management folder /management/prometeus. 
To configure the Docker daemon on the management node as a Prometheus target, you need to specify the metrics-address. 
The best way to do this is via the daemon.json, which is located at /etc/docker/daemon.json . If the file does not exist, create it.

    /etc/docker/daemon.json

If the file is currently empty, paste the following:

	{
	  "metrics-addr" : "127.0.0.1:9323",
	  "experimental" : true
	}

If the file is not empty, add those two keys, making sure that the resulting file is valid JSON. Be careful that every line ends with a comma (,) except for the last line.

**Note:** The metrics-add is the manager-ip address from your docker-swarm!

Save the file, and restart Docker.

	$ service docker restart

Docker now exposes Prometheus-compatible metrics on port 9323.

The general configuration is defined by the file 'prometheus.yml':

	# my global config
	global:
	  scrape_interval:     15s # Set the scrape interval to every 15 seconds. Default is every 1 minute.
	  evaluation_interval: 15s # Evaluate rules every 15 seconds. The default is every 1 minute.
	  # scrape_timeout is set to the global default (10s).
	
	  # Attach these labels to any time series or alerts when communicating with
	  # external systems (federation, remote storage, Alertmanager).
	  external_labels:
	      monitor: 'codelab-monitor'
	
	# Load rules once and periodically evaluate them according to the global 'evaluation_interval'.
	rule_files:
	  # - "first.rules"
	  # - "second.rules"
	
	# A scrape configuration containing exactly one endpoint to scrape:
	# Here it's Prometheus itself.
	scrape_configs:
	  # The job name is added as a label `job=<job_name>` to any timeseries scraped from this config.
	  - job_name: 'prometheus'
	
	    # metrics_path defaults to '/metrics'
	    # scheme defaults to 'http'.
	
	    static_configs:
	      - targets: ['localhost:9090']
	
	  - job_name: 'docker'
	         # metrics_path defaults to '/metrics'
	         # scheme defaults to 'http'.
	
	    static_configs:
	      - targets: ['manager-node-ip:9323']
	    
	      
	  - job_name: 'node-exporter'
	    static_configs:
	      # add IP adresses for all nodes to monitor
	      - targets: ['manager-node-ip:9100']
	      - targets: ['worker-node1-ip:9100']
	      - targets: ['worker-node2-ip:9100']	


**Note:** Ad in the section node-exporter all targets with the IP addresses from your swarm nodes to be monitored.  Otherwise you will see the following error:

## The node-exporter

The node -exporter is an imprtant service provided by prometheus. This service will provide the machine data in a prometheus format. There for this service is deployed in 'global' mode which means the service will be started on every node in your docker-swarm network. It is important that you take care of the 'node-exporter' job description in the prometheus.yml file. You need to add the IP address from every node here! 

## Grafana

The Imixs-Cloud Monitoring Service also includes a grafana service which is providing a dashboard for prometheus.
The grafana service maps a data volume named 'grafana-data' to store your settings made in grafana. 



## Starting 

To start the Monitoring service run:

	$ docker stack deploy -c management/monitoring/docker-compose.yml monitoring

Prometheus will be available on port 9090. Grafana Dashboard will be available on port 3000.
You can customize the setup using the traefik.io integration and map the prometheus service to a hostname and also secure the service with basic authentication. Uncomment the corresponding lables in the docker-compose.yml file. 
