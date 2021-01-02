# Creating a Highly Available Cluster

I you have followed the [setup guide](./SETUP.md) so far you cluster consists of one master node and several worker nodes. In this setup, you services and applications are distributed among the different worker nodes, resulting in an even load. 
If one of the worker nodes fails or you shut it down, one of the other worker nodes automatically overtakes the unavailable tasks. In Kubernetes the rescheduling can take up to 5 minutes for the desired cluster status to be restored. 

In contrast, there is no resilience for the master node. It exists only once in the cluster. However, in case of a failure of the master node, the master and all its information about the deployment objects can be quickly restored from the Git repository. This concept is also called *configuration by code*. In the following section we describe how to setup a Highly Available cluster with more than one master nodes. 


## Highly Available Master Nodes

To setup highly available master nodes there exist different concepts and topologies. In this project we follow the concept of a so called *Stacked HA cluster*. A stacked HA cluster is a topology where the distributed data storage cluster provided by etcd is stacked on top of the cluster formed by the nodes managed by *kubeadm* that run control plane components. This concept is easy to realize with minimal additional hardware requirements. You can find more information about the different topologies [here](https://kubernetes.io/docs/setup/production-environment/tools/kubeadm/ha-topology/).

Each master node runs an instance of the kube-apiserver, kube-scheduler, and kube-controller-manager. The kube-apiserver is exposed to worker nodes using a load balancer. The etcd is distributed on each master node which is coupled to the control planes on the same node.
To avoid compromised redundancy in case of a lost master node a minimum of three master nodes for an HA cluster is recommended.

## Setup Highly Available Master Nodes

Before you start, ensure that the full network connectivity between all machines in the cluster is working (public or private network). Install the kuberentes with the same setup script used in the [setup guide](./SETUP.md).

### Create a load balancer 

The first step is to create a load balancer for the control plane (a load balancer is required when using multiple control plane nodes). Since the setup of a load balancer depends mainly on your server environment we can not provide a install guide for this. 
If you are running in a public or private data center ask the support team how to setup a load balancer on port 6443 including your master nodes.
The load balancer should using a Layer 4 load balancer (TCP instead of HTTP/HTTPS). Health checks should be configured as SSL health checks instead of TCP health checks (this will weed out spurious “TLS handshake errors” in the API server’s logs).

See also [here](https://blog.scottlowe.org/2019/08/12/converting-kubernetes-to-ha-control-plane/)


https://stackoverflow.com/questions/65505137/how-to-convert-a-kubernetes-non-ha-control-plane-into-an-ha-control-plane


TBD: So solution found to migrate an existing  non-HA control plane (single control plane node) to an HA control plane (multiple control plane)


It looks like the only solution is to init a complete new master node and join all worker nodes again. 


Setup 1st master:

	sudo kubeadm init --control-plane-endpoint "LOAD_BALANCER_DNS:LOAD_BALANCER_PORT" --upload-certs

Load balancer ort should be 6443

	
Setup 2nd master:

	sudo kubeadm join LOAD_BALANCER_DNS:LOAD_BALANCER_PORT --token 9vr73a.a8uxyaju799qwdjv --discovery-token-ca-cert-hash sha256:........................ --control-plane --certificate-key .................
	
 - The --control-plane flag tells kubeadm join to create a new control plane.
 - The --certificate-key ... will cause the control plane certificates to be downloaded from the kubeadm-certs Secret in the cluster and be decrypted using the given key.



### Add master to existing cluster

https://stackoverflow.com/questions/49887597/add-a-second-master-node-for-high-availabity-in-kubernetes
	
https://stackoverflow.com/questions/55867216/adding-master-to-kubernetes-cluster-cluster-doesnt-have-a-stable-controlplanee
	

1) copy the K8s CA cert from kubemaster01.


	scp root@<kubemaster01-ip-address>:/etc/kubernetes/pki/* /etc/kubernetes/pki


2) For bootstrapping create a config.yaml:


	apiVersion: kubeadm.k8s.io/v1beta1
	kind: ClusterConfiguration
	api:
	  advertiseAddress: <private-ip>
	etcd:
	  endpoints:
	 - https://<your-ectd-ip>:2379
	  caFile: /etc/kubernetes/pki/etcd/ca.pem
	  certFile: /etc/kubernetes/pki/etcd/client.pem
	  keyFile: /etc/kubernetes/pki/etcd/client-key.pem
	networking:
	  podSubnet: <podCIDR>
	apiServerCertSANs:
	- <load-balancer-ip>  
	apiServerExtraArgs:
	  apiserver-count: "2"
	
Ensure that the following placeholders are replaced:

 - your-ectd-ip the IP address your etcd
 - private-ip it with the private IPv4 of the master server.
 - <podCIDR> with your Pod CIDR
 - load-balancer-ip endpoint to connect your masters
	
	