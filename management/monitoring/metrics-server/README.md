# Metrics Server

The open source project [metrics-server](https://github.com/kubernetes-sigs/metrics-server) provides a scalable, efficient source of container resource metrics
like CPU, memory, disk and network. These are also referred to as the "Core" metrics.
The Kubernetes Metrics Server is collecting and aggregating these core metrics in your cluster and is used by other Kubernetes add ons, such as the Horizontal Pod Autoscaler or the Kubernetes Dashboard. 

## How to Install

To install the metrics-server run:

	$ kubectl apply -f https://github.com/kubernetes-sigs/metrics-server/releases/download/v0.6.1/components.yaml

The metric-server will be installed into the namespace 'kube-system' and starts grabbing the node metrics. Until the first data is available it may take some seconds. 
You can verifiy the server with the following command showing you the current CPU and Memory usage:

	$ kubectl top nodes
	NAME       CPU(cores)   CPU%   MEMORY(bytes)   MEMORY%   
	master-1   297m         14%    1358Mi          36%       
	worker-1   1424m        35%    13913Mi         89%       


## Insecure TLS

In case the metric server will not work and you see the following kind of log entries in the metric-servers log:

    E0908 18:08:29.711310       1 scraper.go:139] "Failed to scrape node" err="Get \"https://10.68.14.125:10250/stats/summary?only_cpu_and_memory=true\": x509: cannot validate certificate for 10.68.14.125 because it doesn't contain any IP SANs" node="scw-sharp-cray"


than you have the following solutions.

**1) Set -kubelet-insecure-tls**

To ignore the messages you can set the flag `-kubelet-insecure-tls`.

First download the deployment yaml file from github:

	$ cd management/monitoring/metrics-server/
	$ wget https://github.com/kubernetes-sigs/metrics-server/releases/download/v0.6.1/components.yaml

Open the file with an editor and add  the command argument `-kubelet-insecure-tls` to the args section of the container:

      containers:
      - args:
        - --cert-dir=/tmp
        - --secure-port=4443
        - --kubelet-preferred-address-types=InternalIP,ExternalIP,Hostname
        - --kubelet-use-node-status-port
        - --metric-resolution=15s
        # allow insecure node certificates
        - --kubelet-insecure-tls

Now you can start the server again accepting insecure certificates:

	$ kubectl apply 

**2) Set serverTLSBootstrap: true**

A more secure solution can be found [here](https://particule.io/en/blog/kubeadm-metrics-server/)

On your master node, edit the file /var/lib/kubelet/config.yaml and add the option `serverTLSBootstrap: true` to the end of the file.

Next restart the kubelet:

	$ sudo systemctl restart kubelet

Now `kubelet` will generate a CSR and submit it to the APIServer. You need to approve the new CSRs for each Kubelet on your cluster.

List the certificates with:

	$ kubectl get csr
	NAME        AGE     SIGNERNAME                      REQUESTOR              REQUESTEDDURATION   CONDITION
	csr-123xc   8m32s   kubernetes.io/kubelet-serving   system:node:master-1   <none>              Approved,Issued
	csr-456pf   3m15s   kubernetes.io/kubelet-serving   system:node:worker-1   <none>              Pending
	

And call for each certificate shown in the list:

	
	$ kubectl certificate approve [csr-name]
	
**Note:** replace `[csr-name]` with the name of your certs. It may take some minutes until the worker nodes are shown up again after you have restarted kubelet.

Find more about this topic in the discussion [here](https://github.com/kubernetes-sigs/metrics-server/issues/196)

