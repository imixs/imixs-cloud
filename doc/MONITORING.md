# How to Monitor Imixs-Cloud

*Imixs-Cloud* also provides a monitoring feature which allows you to monitor your Kubernetes cluster.

<img src="./images/monitoring-001.png" />

The Monitoring setup is based on [Prometheus](https://prometheus.io/) and [Grafana](https://grafana.com/). You have various ways to customize the monitoring to your individual needs. 

Follow the [Deployment Guide](../management/monitoring/README.md) to setup the monitoring services. 


## Prometheus

[Prometheus](https://prometheus.io/) is an open-source systems monitoring and alerting toolkit. 
The Prometheus service is database used for collecting the metric data. The *Prometheus Node exporter* is responsible for collecting the hardware and OS metrics exposed by *NIX kernels on each node. The *kube-state-metrics* service listens to the Kubernetes API server and generates metrics about the state of the objects deployed on your Kubernetes Cluster.

The Prometheus server is only internal and not accessible from outside of your cluster. But for later configuration you need to know the internal address for data access:

	http://prometheus:9090


## Grafana

The [Grafana](https://grafana.com/) service is the front-end application used to visualize the data collected by Prometheus. 
The grafana service provides a web interface with rich functionality for monitoring and alerting. 
 
### First Login

For the first login use the userid 'admin' and the password 'admin'. You will be force to change the admin password first.

<img src="./images/monitoring-002.png" />
 
### Setup the Prometheus Database

After your first login you will be asked to add a data source. Choose the data source type 'prometheus'

Enter the prometheus url 'http://prometheus:9090'. 

<img src="./images/monitoring-003.png" />

You don't need to add or change additional data.



## Install a Dashboard

Now you can import a new Dashbaord. Dashboards are a discription how to visualize the data provided form the prometheus data source. There are a lot of community dashboards available in the public [Grafana Dashboard repository](https://grafana.com/grafana/dashboards?direction=asc&orderBy=name&search=kubernetes).

You can import the dashboard available in the *Imixs-Cloud* project located in /monitoring/dashboards/

From the left toolbar choose 'Dashboards -> manage' and click on 'import

<img src="./images/monitoring-004.png" />

Past the content of the json file */monitoring/dashboards/imixs-cloud.json* into the text field and click on load:

<img src="./images/monitoring-005.png" />


Thant's it.

<img src="./images/monitoring-001.png" />

