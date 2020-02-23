# How to setup the Imixs-Cloud

The following section describes the setup procedure of _Imixs-Cloud_ to run a kubernetes cluster into a productive environment for small and medium organisations.

## Hostnames

To enable communication between your cluster nodes using short names, make sure that on each node the short host names a listed in the /etc/hosts with the public or private IP addresses.



## The Cluster-User

** Note:**
In Imixs-Cloud you should always work with a non-root, sudo privileged cluster user. So first make sure that you have defined a cluster-user on your master node and also on all your worker nodes. 

To create a cluster-user follow the next steps and replace '{username}' with the name of our cluster user you have choosen. 

	$ useradd -m {username} -s /bin/bash
	$ passwd {username}
	$ echo "{username} ALL = (root) NOPASSWD:ALL" | sudo tee /etc/sudoers.d/{username}
	$ sudo chmod 0440 /etc/sudoers.d/{username}

Next create a SSH key on the master node and distribute the public key to each worker node. Leave the passphrase and filename empty  

	# login with your cluster user
	$ su {username}
	$ ssh-keygen

The keys will be stored in the .ssh/ directory. 

Now you can copy the key to all worker nodes

	ssh-copy-id {username}@node1
	ssh-copy-id {username}@node2

 
## Setup 
 
For a quick setup you can clone the git repository and start the setup:

1) install git 

	$ sudo apt-get install -y git

2) clone repo....

	$ git clone https://github.com/imixs/imixs-cloud.git

3) start the setup

	$ sudo ./imixs-cloud/scripts/setup.sh [YOUR_SERVER_IP_ADDRESS]

replace [YOUR\_SERVER\_IP\_ADDRESS] with your servers public IP address

**That's it.** 

## Nodes

A _Imixs-Cloud_ consists of a minimum of two nodes.

* The master node is the kubernetes api server
* The worker nodes are serving the applications (pods). 

A node can be a virtual or a hardware node. All nodes are defined by unique fixed IP-addresses and DNS names. Only the manager-node need to be accessible through the internet. 

## The setup.sh script

In order to ensure that all nodes are running the same software releases run the following setup script. This script is designed for Debian 10 (Buster) but of course you can adapt the script for a different Lnux distribution. The script installs the following tools:

 - docker-ce (the docker engine)
 - docker-ce-cli (the docker command line interface)
 - containerd.io (the container runtime)
 - kubelet (the kubernetes node agent)
 - kubeadm (the kubernetes cluster tool)
 - kubectl (the kubernetes command line interface)


The install script can be found in the script directory /scripts/. Run the setup script as sudo:

	$ chmod u+x scripts/setup.sh
	$ sudo scripts/setup.sh
	




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

	mkdir -p $HOME/.kube
	sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
	sudo chown $(id -u):$(id -g) $HOME/.kube/config

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

**Note:** The admin.conf file gives the user superuser privileges over the cluster. This file should be used sparingly. For normal users, it’s recommended to generate an unique credential to which you whitelist privileges. Kubernetes supports different authentication strategies, defined here.























