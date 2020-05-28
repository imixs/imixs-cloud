# How to setup the Imixs-Cloud

The following section describes the setup procedure of *Imixs-Cloud* to run a kubernetes cluster into a productive environment for small and medium organizations. 
If you just want to upgrade your existing *Imixs-Cloud* environment jump to the [upgrade section](#upgrade) below.


## The Cluster Nodes

A *Imixs-Cloud* consists of a minimum of two nodes.

* The master node is the kubernetes api server
* The worker nodes are serving the applications (pods). 

A node can be a virtual or a hardware node. All nodes are defined by unique fixed IP-addresses and DNS names. Only the manager-node need to be accessible through the Internet. 

To enable communication between your cluster nodes using short names, make sure that on each node the short host names a listed in the /etc/hosts with the public or private IP addresses.



## The Cluster-User

** Note:**
In *Imixs-Cloud* you should always work with a non-root, sudo privileged cluster user. So first make sure that you have defined a cluster-user on your master node and also on all your worker nodes. 

To create a cluster-user follow the next steps and replace '{username}' with the name of our cluster user you have choosen. 

	$ useradd -m {username} -s /bin/bash
	$ passwd {username}

 
## Install the Master Node 
 
*Imixs-Cloud* provides a install script for Debain and Fedora/CentOS linux distributes. You can copy the setup script from the /scritps/ directory. But we recommend to clone the *Imixs-Cloud* git repo so you have all scripts and configuration files in one place. You can also fork the *Imixs-Cloud* project to customize your environment individually to your needs. 
 
### Install Git
 
For a easy setup install git and clone the *Imixs-Cloud* repository on your master node:

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

 - docker-ce (the docker engine)
 - docker-ce-cli (the docker command line interface)
 - containerd.io (the container runtime)
 - kubelet (the kubernetes node agent)
 - kubeadm (the kubernetes cluster tool)
 - kubectl (the kubernetes command line interface)


The install script can be found in the script directory /scripts/. We provide the install script for Debian/Ubuntu and Fedora/CentOS. Run the setup script as sudo:

For Debian 10

	$ sudo ~/imixs-cloud/scripts/setup_debian.sh
	
For CentOS 7

	$ sudo ~/imixs-cloud/scripts/setup_centos.sh
	



## Setup the Cluster

After you have installed the necessary libraries you can initialize the Kubernetes cluster using the following kubeadm command:

	$ sudo kubeadm init --pod-network-cidr=10.244.0.0/16 --apiserver-advertise-address=[NODE_IP_ADDRESS]

Replace [NODE\_IP\_ADDRESS] with your servers public IP address.

You will see a detailed protocol showing what happens behind the scene. If something went wrong you can easily roll back everything with the command:

	$ sudo kubeadm reset

The last output form the protocol shows you the join token needed to setup a worker node. If you forgot to note the join token run:

	$ sudo kubeadm token create --print-join-command

### Setup kubectl on a Server

To make kubectl work for your non-root user, run these commands, which are also part of the kubeadm init output:

	$ mkdir -p $HOME/.kube
	$ sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
	$ sudo chown $(id -u):$(id -g) $HOME/.kube/config

This will copy the configuration of your master node into the kubernetes config directory ./kube of your home directory.


### Setup a flannel network

Next, deploy the flannel network to the kubernetes cluster using the kubectl command.

	$ kubectl apply -f https://raw.githubusercontent.com/coreos/flannel/master/Documentation/kube-flannel.yml

The flannel network will been deployed to the Kubernetes cluster. After some seconds the cluster should be up and running. You can check the status with:

	$ kubectl cluster-info



## Install Worker Nodes

Now you can run the same script used to install the master node on each of your worker nodes. This will install the docker runtime and kubernetes tools. To add the new node to your cluster created in the previous step run the join command from the master setup. If you do not know the join command you can run the following command on your master node frist:

	$ kubeadm token create --print-join-command

Run the output as a root user on your worker node:

	$ sudo kubeadm join xxx.xxx.xxx.xxx:6443 --token xxx.xxxxxxxxx     --discovery-token-ca-cert-hash xxxxxxxxxxxxxxxxxxxxxxxxxxxxxx

and list all nodes with:

	$ kubectl get nodes
	
## Controlling Your Cluster From your Workstation

In different to docker-swarm, a kubernetes cluster can be administrated remote from your workstation. The tool ‘kubectl’ is the kubernetes command line tool used to manage your cluster via the kubernetes api either from your server or from a workstatio..
Setup kubectl on Your Workstation

To run kubectl from your workstation you need first to install it. You will find the official install guide here. Note: you install only the kubectl tool, not a full kubernetes server as in the section before.

In order to get kubectl talking to your cluster, you can again copy the content from the administrator kubeconfig file (/etc/kubernetes/admin.conf) into your workstation. (See the section above ‘Setup cubectl on a Server’)

	$HOME/.kube/config 

**Note:** The admin.conf file gives the user superuser privileges over the cluster. This file should be used sparingly. For normal users, it’s recommended to generate an unique credential to which you whitelist privileges. Kubernetes supports different authentication strategies. We recommend you to run kubectl only from your master node which gives you more control who access your cluster. 



# Upgrade

You can verify the status of your kubernets cluster by the following command:

	$ kubectl get nodes
	NAME              STATUS   ROLES    AGE   VERSION
	ixchel-master-1   Ready    master   28d   v1.18.2
	ixchel-worker-1   Ready    <none>   28d   v1.18.2
	ixchel-worker-2   Ready    <none>   28d   v1.18.2
	ixchel-worker-3   Ready    <none>   28d   v1.18.2

This will show you the current version of kubernetes running on each node

To check the status of docker run the following command on each node:

	$ sudo docker version
	Client: Docker Engine - Community
	 Version:           19.03.8
	 API version:       1.40
	 Go version:        go1.12.17
	 Git commit:        afacb8b7f0
	 Built:             Wed Mar 11 01:25:56 2020
	 OS/Arch:           linux/amd64
	 Experimental:      false
	
	Server: Docker Engine - Community
	 Engine:
	  Version:          19.03.8
	  API version:      1.40 (minimum version 1.12)
	  Go version:       go1.12.17
	  Git commit:       afacb8b7f0
	  Built:            Wed Mar 11 01:24:28 2020
	  OS/Arch:          linux/amd64
	  Experimental:     false
	 containerd:
	  Version:          1.2.13
	  GitCommit:        7ad184331fa3e5
	 runc:
	  Version:          1.0.0-rc10
	  GitCommit:        dc9208a3303fee
	 docker-init:
	  Version:          0.18.0
	  GitCommit:        fec3683


To upgrade you existing *Imixs-Cloud* environment follow these steps:

**1. Create a snapshot**

Before your start upgrading a worker node or your master node it's a good idea to make a snapshot or backup from your node so you can roll back in case something went wrong.

**2. apt upate**

To update your worker or master node run the following commands on a debian platform:

	$ sudo apt update
	$ sudo apt upgrade

**3. Reboot your node **

After an upgrade kubernetes will automatically reschedule the node pods. 
Optional you can also reboot your node to make sure docker deamon and kubernets is restarted correctly.

	$ sudo reboot

















