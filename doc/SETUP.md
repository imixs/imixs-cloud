# How to Setup the Imixs-Cloud

The following section describes the setup procedure of *Imixs-Cloud* for small and medium organizations. 
This setup guide shows how to install a kubernetes cluster into a productive environment consisting of several Internet nodes. 

If you just want to upgrade your existing *Imixs-Cloud* environment jump to the [upgrade section](#upgrade) below.

In the [Maintenance section](#maintenance) you will find useful information how to maintain a running *Imixs-Cloud* cluster environment. 

## The Cluster Nodes

A *Imixs-Cloud* consists of a minimum of two nodes.

* The master node is the kubernetes api server
* The worker nodes are serving the applications (pods). 

A node can be a virtual or a hardware node. All nodes are defined by unique fixed IP-addresses and DNS names. Only the manager-node need to be accessible through the Internet. So you also can connect your worker nodes with a private network if you like. 

To enable communication between your cluster nodes using short names, make sure that on each node the short host names are listed in the /etc/hosts with the public or private IP addresses.



## The Cluster-User

**Note:**
In *Imixs-Cloud* you should always work with a non-root, sudo privileged cluster user. This protects yourself from doing nasty things with the root user. So first make sure that you have defined a cluster-user on your master node and also on all your worker nodes. 

To create a cluster-user follow the next steps and replace '{username}' with the name of our cluster user you have chosen. 

	$ useradd -m {username} -s /bin/bash
	$ passwd {username}

Make sure that your cluster-user has also *sudo* rights!
 
## Install the Master Node 
 
*Imixs-Cloud* provides a install script for Debain and Fedora/CentOS linux distributions. You can copy the setup script from the /scritps/ directory. But we recommend to clone the *Imixs-Cloud* git repo so you have all scripts and configuration files in one place. You can also fork the *Imixs-Cloud* project to customize your environment individually to your needs. 
 
### Install Git
 
For a easy setup install git on your master node and clone the *Imixs-Cloud* repository or a fork:

For Debian 10 run:

	$ sudo apt install -y git
	
For CentOS 7 run:
	
	$ sudo yum install -y git

Next you can clone the repo or your personal fork of *Imixs-Cloud* ....

	$ cd
	$ git clone https://github.com/imixs/imixs-cloud.git

*Imixs-Cloud* is now installed in your home directory:

	~/imixs-cloud/


Find more details about how to fork or clone this repo [here](GIT.md).

### The Setup Script

In order to ensure that all nodes are running the same software releases run the *Imixs-Cloud* setup script on all your nodes. The script installs the following tools:

 - containerd (the container runtime)
 - kubelet (the kubernetes node agent)
 - kubeadm (the kubernetes cluster tool)
 - kubectl (the kubernetes command line interface)


The install script can be found in the script directory /scripts/. The install script is available for Debian/Ubuntu and Fedora/CentOS. Run the setup script as sudo:

For Debian 10

	$ sudo ~/imixs-cloud/scripts/setup_debian.sh
	
For CentOS 7

	$ sudo ~/imixs-cloud/scripts/setup_centos.sh
	

### Hostnames and Network Addresses

In case you are running your cluster in a private network, make sure that all host names of the cluster nodes are listed in the */etc/hosts* with the IP addresses of you private network. Otherwise your cluster nodes will probably communicate via the public Internet IPs which is what you want to avoid. 

## Setup the Cluster

After you have installed the setup script and checked you network IP addresses, you can initialize the Kubernetes cluster using the following kubeadm command:

	$ sudo kubeadm init --pod-network-cidr=10.244.0.0/16 --apiserver-advertise-address=[NODE_IP_ADDRESS]

Replace [NODE\_IP\_ADDRESS] with your servers private IP address.

You will see a detailed protocol showing what happens behind the scene. 

The last output form the protocol shows you the join token needed to setup a worker node. If you forgot to note the join token you can run the following command:

	$ sudo kubeadm token create --print-join-command

### The control-plane-endpoint

**Note:** If you have plans to upgrade this single control-plane kubeadm cluster to high availability you should specify the --control-plane-endpoint to set the shared endpoint for all control-plane nodes. Such an endpoint should be a DNS name, so you can change the endpoint later easily. 

	$ sudo kubeadm init --pod-network-cidr=10.244.0.0/16 --apiserver-advertise-address=[NODE_IP_ADDRESS] --control-plane-endpoint=[LOAD-BALANCER-DNS-NAME]



### Setup kubectl on a Server

*kubectl* is the commandline tool of kubernetes. We use *kubectl* to administration *Imixs-Cloud* and to create, update or delete resources and applications into the cluster.

To make kubectl work for your non-root user, run these commands on your master node. (These commands are also part of the kubeadm init output):

	$ mkdir -p $HOME/.kube
	$ sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
	$ sudo chown $(id -u):$(id -g) $HOME/.kube/config

This will copy the configuration of your master node into the kubernetes config directory ./kube of your home directory. Now you can administrate your kubernetes cluster as a non-root user.


### Setup a Cluster Network Interface (CNI)

Before you start to setup your first worker node you need to install a kubernetes cluster network. There are several network plugins available. You can find a list [here](https://kubernetes.io/docs/concepts/cluster-administration/networking/).

#### The Flannel Network

[Flannel](https://github.com/flannel-io/flannel#flannel) is a simple and easy way to configure a layer 3 network fabric designed for Kubernetes. To deploy the flannel network to the kubernetes cluster run the following kubectl command:

	$ kubectl apply -f https://raw.githubusercontent.com/coreos/flannel/v0.13.0/Documentation/kube-flannel.yml

The flannel network will been deployed to the Kubernetes cluster. After some seconds the cluster should be up and running. You can check the status with:

	$ kubectl cluster-info

**Note:** You can switch to a newer version if you check the relase notes from the flannel project on [github](https://github.com/flannel-io/flannel/releases)

#### The Calico Network

[Calico](https://docs.projectcalico.org/) is an open source networking and network security solution for containers, virtual machines, and native host-based workloads. It is more flexible and powerful than the flannel network and can be a good alternative.

To install calico download the calico.yaml file from [here](https://docs.projectcalico.org/manifests/calico.yaml). 

	$ curl https://docs.projectcalico.org/manifests/calico.yaml -O	
	
If you have defined a CIDR network than you can optional uncomment the environment variable 'CALICO_IPV4POOL_CIDR' and set your CIDR network here. But this step should not be required if you followed the setup guide here. 

To deploy the network run:

	$ kubectl apply -f calico.yaml
	
After some seconds the cluster should be up and running. You can check the status with:

	$ kubectl cluster-info	

Find more details about how to install calico [here](https://docs.projectcalico.org/getting-started/kubernetes/self-managed-onprem/onpremises).

### How to Reset a Node

If something went wrong you can easily roll back everything with the command:

	$ sudo kubeadm reset

**Note:** This will erase the etcd database! 

## Install Worker Nodes

Now you can run the same script used to install the master node on each of your worker nodes. 

	$ sudo ~/imixs-cloud/scripts/setup_debian.sh

This will install the containerd runtime and the kubernetes tools. 

### Adding a Worker Node to your Cluster

To add the new node to your cluster you need to run the join command from the master setup:

	$ sudo kubeadm join xxx.xxx.xxx.xxx:6443 --token xxx.xxxxxxxxx     --discovery-token-ca-cert-hash xxxxxxxxxxxxxxxxxxxxxxxxxxxxxx

If you do not know the join command you can run the following command on your master node first:

	$ kubeadm token create --print-join-command

Check your new cluster status on your master node:

	$ kubectl get nodes
	
## Controlling your Cluster From your Workstation

In different to docker-swarm, a kubernetes cluster can be administrated remote from your workstation. The tool ‘kubectl’ is the kubernetes command line tool used to manage your cluster via the kubernetes api either from your server or from a workstation.

For security reasons we recommend to run kubectl in smaller environments only from your master-node. 

### Setup kubectl on Your Workstation

To run kubectl from your workstation you need first to install it. You will find the official install guide here. Note: you install only the kubectl tool, not a full kubernetes server as in the section before.

In order to get kubectl talking to your cluster, you can again copy the content from the administrator kubeconfig file (/etc/kubernetes/admin.conf) into your workstation. (See the section above ‘Setup cubectl on a Server’)

	$HOME/.kube/config 

**Note:** The admin.conf file gives the user superuser privileges over the cluster. This file should be used sparingly. For normal users, it’s recommended to generate an unique credential to which you whitelist privileges. Kubernetes supports different authentication strategies. We recommend you to run kubectl only from your master node which gives you more control who access your cluster. 



# Upgrade

After you have successfull installed your Imixs-Cloud cluster you may want to verify its status and maybe update your master and worker nodes. The following guide shows you how to do this. (If you just have installed your new cluster you can skip this section.)

## Verify your Cluster Status

You can verify the status of your kubernets cluster with the following command:

	$ kubectl get nodes
	NAME              STATUS   ROLES    AGE   VERSION
	master-1   Ready    master   28d   v1.21.6
	worker-1   Ready    <none>   28d   v1.21.6
	worker-2   Ready    <none>   28d   v1.21.6
	worker-3   Ready    <none>   28d   v1.21.6

This will show you the current version of kubernetes running on each node

**NOTE:** To upgrade the kubeadm and kubectl versions do not run an `apt upgrade`. Instead follow carefully the official [Kubernetes Upgrade Guide](https://kubernetes.io/docs/tasks/administer-cluster/kubeadm/kubeadm-upgrade/). 

You can check the available versions compared to your current instlled verions:

	$ sudo apt update && apt-cache madison kubeadm




## Upgrade the Master Node

To upgrade the kubeadm tool on the master node run:

	$ sudo apt-get update && apt-get install -y --allow-change-held-packages kubeadm=1.22.x-00
	
Where you replace the kubeadm version with the version you want to upgrade to. Next your can verify the update:

	$ sudo kubeadm version	

With the following command youc can that your cluster can be upgraded. The command fetches the versions you can upgrade to. It also shows a table with the component config version states.


	$ sudo kubeadm upgrade plan
	
	
**Note:** Follow carefully the instruction on the 	[Upgrade Guide](https://kubernetes.io/docs/tasks/administer-cluster/kubeadm/kubeadm-upgrade/). 
	
	$ sudo kubeadm upgrade apply v1.21.6
	
After following the upgrade command you can finally upgrade kubelet and kubectl:
	
	$ sudo apt-get update && apt-get install -y --allow-change-held-packages kubelet=1.22.x-00 kubectl=1.22.x-00

Where you again need to replace the correct version.	
	
	
## Upgrade the Worker Nodes

On the worker nodes your only need to upgrade kubeadm tool:

	$ sudo apt-get update && apt-get install -y --allow-change-held-packages kubeadm=1.22.x-00
	$ sudo kubeadm upgrade node
	
Where you replace the kubeadm version with the version you want to upgrade to. Next your can verify the update:

	$ sudo kubeadm version	
	
To upgrade kubelet and kubectl run:
	
	$ sudo apt-get update && apt-get install -y --allow-change-held-packages kubelet=1.22.x-00 kubectl=1.22.x-00

Where you again need to replace the correct version.

# Maintenance

The following section contains some maintenance tips for a running environment. 

See also the section [Monitoring](MONITORING.md) to learn how you can monitor your cluster and its metrics with a modern dashboard. 

## Rescale a Node

To rescale a node first mark the node as unschedulable:

	$ kubectl drain node-x

next you can shutdown the node, upgrade or rescale the node. After the node is up again run *uncordon* to join the node again the scheduler.

	$ kubectl uncordon node-x
	

## Remove a Node

In order to remove a node form the cluster you can first call:

	$ kubectl drain <node name>

This will safely evict all pods from a node before you perform maintenance on the node (e.g. kernel upgrade, hardware maintenance, etc.). Safe evictions allow the pod's containers to gracefully terminate and will respect the PodDisruptionBudgets you have specified.

To bring the node back into the cluster run:

	$ kubectl uncordon node-x

To delete the node from the cluster:

	$ kubectl delete node <node-name>
	
Finally connect to the specific worker node an run:

	# ATTENTION: MAKE SURE YOU ARE ON THE NODE TO BE REMOVED!!!
	$ sudo kubeadm reset
	

