# Monitoring

The Core metrics collected by the metrics-server are stored in memory. To collect and monitor the core metrics over time an additional mechanism for aggregating this data needed. As all the Kubernetes internal metrics is exposed using the the Prometheus exposition format, a Prometheus service can be used to aggregate metrics not only from the metric-server but also from other components as also from individual business applications. The following section shows how to setup a Monitoring with Prometheus and Grafana.

## kube-state-metrics

The [kube-state-metrics](https://github.com/kubernetes/kube-state-metrics) is a simple service that listens to the Kubernetes API server and generates metrics about the state of the objects. It is not focused on the health of the individual Kubernetes components, but rather on the health of the various objects inside, such as deployments, nodes and pods. The kube-state-metrics allows to access these metrics from monitoring systems such as Prometheus.

## node-exporter

The [Prometheus node-exporter](https://github.com/prometheus/node_exporter) is an exporter service for hardware and OS metrics exposed by *NIX kernels, written in Go with pluggable metric collectors.


## Installation

### Create a Storage Volume

The monitoring stack needs some durable storage volumes to persist data. We use the volume 'grafana-data' to persist the grafana settings like plugins, users and dashbords. So first create the following new Storage volumes:

	monitoring-grafana-data   1G
	monitoring-prometheus-data   10G

If you do not have installed a storage solution like longhorn or ceph you can use an 'emtypy-dir' but this will lot your settings after a redeployment. For testing purpose this can be sufficient. Just replace in the file deployment-grafana.yaml the volumes definition  for the volume *grafana-data*  with an emptyDir:

	  .....
      volumes:
        - name: monitoring-grafana-data
          emptyDir: {}
      .....

### Deployment

We use the config map providing prometheus with the necessary settings. You can change these settings later easily in the file /config/prometheus.yml. To create the config map run:

	$ kubectl create namespace monitoring
	$ kubectl create configmap prometheus-config --from-file=./management/monitoring/metrics-server/config/prometheus.yml -n monitoring
	
Now you can deploy the monitoring stack:

	$ kubectl apply -k management/monitoring/imixs-prometheus/



To undeploy the monitoring stack run:


	$ kubectl delete -f management/monitoring/metrics-server/
	$ kubectl delete configmap prometheus-config -n monitoring
	$ kubectl delete namespace monitoring
	
	
	


