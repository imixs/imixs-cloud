# Monitoring

The Core metrics collected by the metrics-server are stored in memory. To collect and monitor the core metrics over time an additional mechanism for aggregating this data needed. As all the Kubernetes internal metrics is exposed using the the Prometheus exposition format, a Prometheus service can be used to aggregate metrics not only from the metric-server but also from other components as also from individual business applications. 

The imixs-prometheus stack is a deployment stack including all necessary services to monitor a kuberentes cluster. This part is independent fom the *Imixs-Cloud* project and can also be applied to other kubernetes setups. The imixs-prometheus stack is based on kustomize which allows you to get better insights how the stack is build and also a convenient way for customizing the stack for individual needs. 

The following section shows how to setup a Monitoring with Prometheus and Grafana.


## The Components

*imixs-prometheus* consists of the following services:

### Prometheus

[Prometheus](https://prometheus.io/) is the open-source systems monitoring and alerting toolkit. 
The Prometheus service is the database used for collecting the metric data. The Prometheus server is typically only used internal to grab data from the metric api and not accessible from outside of your cluster. The internal address for data access is:

	http://prometheus:9090


### Grafana

The [Grafana](https://grafana.com/) service is the front-end application used to visualize the data collected by Prometheus. 
The grafana service provides a web interface with rich functionality for monitoring and alerting. 


### kube-state-metrics

The [kube-state-metrics](https://github.com/kubernetes/kube-state-metrics) is a simple service that listens to the Kubernetes API server and generates metrics about the state of the objects. It is not focused on the health of the individual Kubernetes components, but rather on the health of the various objects inside, such as deployments, nodes and pods. The kube-state-metrics allows to access these metrics from monitoring systems such as Prometheus.

### node-exporter

The [Prometheus node-exporter](https://github.com/prometheus/node_exporter) is an exporter service for hardware and OS metrics exposed by *NIX kernels, written in Go with pluggable metric collectors.


## The Installation

*imixs-prometheus* is based on *kustomize* that allows you to change every details in an easy way.


### Deployment

The prometheus configuration how to scrap the metric data form the different metric APIs is defined in the config file so you can change these settings later easily:

	/config/prometheus.yml 

The configuraiton is provided as a config map. To create the config map run:

	$ kubectl create namespace monitoring
	$ kubectl create configmap prometheus-config --from-file=./management/monitoring/metrics-server/config/prometheus.yml -n monitoring
	
A basic deployment can be run via kubectl and the base kustomize setup hosted on github:

	$ kubectl apply -k https://github.com/imixs/imixs-cloud/management/monitoring/imixs-prometheus/base

If you have already cloned this repo you can also use your local manifest files:

	
	$ kubectl apply -k management/monitoring/imixs-prometheus/base
	

To undeploy the monitoring stack run:


	$ kubectl delete -f management/monitoring/metrics-server/
	$ kubectl delete configmap prometheus-config -n monitoring
	$ kubectl delete namespace monitoring
	
	
	
### Create a Storage Volume

The monitoring stack needs some durable storage volumes to persist data. We use the volume 'grafana-data' to persist the grafana settings like plugins, users and dashbords. So first create the following new Storage volumes:

	monitoring-grafana-data   1G
	monitoring-prometheus-data   10G

If you do not have installed a storage solution like longhorn or ceph you can use an 'emtypy-dir' but this will lot your settings after a redeployment. For testing purpose this can be sufficient. 

To add the new volume configuration just create your own kustomize.yml file to adapt the deployment base deployment

	namespace: monitoring
	
	bases:
	- https://github.com/imixs/imixs-cloud/management/monitoring/imixs-prometheus/base
	#- ../base/
	
	resources:
	- 050-persistencevolume.yaml
	#- 060-ingress.yaml
	
	patchesStrategicMerge:
	- 010-patch-volumes.yaml


To run your custom deployment:

	$ kubectl apply -k management/monitoring/imixs-prometheus
