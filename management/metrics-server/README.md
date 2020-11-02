# Metrics Server

The open source project [metrics-server](https://github.com/kubernetes-sigs/metrics-server) provides a scalable, efficient source of container resource metrics
like CPU, memory, disk and network. These are also referred to as the "Core" metrics.
The Kubernetes Metrics Server is collecting and aggregating these core metrics in your cluster and is used by other Kubernetes add ons, such as the Horizontal Pod Autoscaler or the Kubernetes Dashboard. 

## How to Install

To install the metrics-server follow these steps:

Create a deployment directory

	$ mkdir metrics-server
	$ cd metrics-server
	
Copy the latest component.yaml file from github:

	$ wget https://github.com/kubernetes-sigs/metrics-server/releases/download/v0.3.7/components.yaml
	
Start the metric server with:

	$ kubectl apply -f components.yaml

The metrics-server will start grabbing the node metrics. Until the first data is available it may take some seconds. 


	$ kubectl top nodes
	NAME       CPU(cores)   CPU%   MEMORY(bytes)   MEMORY%   
	master-1   297m         14%    1358Mi          36%       
	worker-1   1424m        35%    13913Mi         89%       


