# The Imixs-Cloud

### Build Your Self Managed Kubernetes Cluster!

*Imixs-Cloud* provides an open concept for small and medium-sized organizations to run an independent, stable and easy to manage cloud infrastructure.
This project is 100% open source and based on [Kubernetes](https://kubernetes.io/) - a cloud solution for automating deployment, scaling, and management of containerized applications.

You can setup an *Imixs-Cloud* Cluster within one day. The flexible and sustainable concept allows you to run your cloud infrastructure without any vendor lock-in. Small and medium-sized cluster environments can be hosted on virtual servers or bare metal. 
The project is open source and constantly under development. We sincerely invite you to participate in it!
If you have any questions just open a new [Issue on Github](https://github.com/imixs/imixs-cloud/issues) and start a Discussion. 

Now, let's get started...

<p align="center"><img src="./doc/images/docker-k8s-logo.png" /></p>


## Topics

 - [Architecture](#the-architecture)
 - [Setup, Upgrade & Maintenance Guide](./doc/SETUP.md)
 - [Terminal Tool K9S](tools/k9s/README.md)
 - [Ingress Integration with NGINX](./doc/INGRESS.md)
 - [Distributed Storage solution](./doc/STORAGE.md)
 - [Docker Registry](./doc/REGISTRY.md)
 - [Security Configuration](./doc/SECURITY.md) 
 - [Monitoring](./doc/MONITORING.md)
 - [SQL Database](./doc/SQL.md)
 - [GitOps](./doc/GITOPS.md)
 - [Continuous Integration CI/CD](./doc/CICD.md)
 - [Kustomize Deployments & Applications](doc/KUSTOMIZE.md)




# The Architecture

The *Imixs-Cloud* project supports the concept of *Infrastructure as Code* and you will find a quick setup guide for a Kubernetes cluster below. But before you get started we should talk about the core concept of cloud architecture. 

Of course, when you set up your own cloud infrastructure with [Kubernetes](https://kubernetes.io/), you need to take care of your servers and your data.
Kubernetes offers a well designed idea how to run a cluster on different nodes, providing a stable runtime environment for your containerized applications. These concepts are well documented and you will find a lot of tutorials about that. But Kubernetes does not provide you with a data infrastructure. It provides a well designed API to abstract storage from your application layer, but it leaves open the question where and how you store your data. 

## The Data Layer

If you do not already have a data storage solution, you should set up a storage for your cluster environment which can be used by your applications. 
There are various projects which can be seamlessly integrated into Kubernetes, for example the [Longhorn project](https://longhorn.io/) provides an quick an easy setup. 
But within the *Imixs-Cloud* project, we believe a storage solution should be run independently from your Kubernetes Cluster. This has several advantages. On the one hand, the data layer is not affected in case of an outage within your Kubernetes Cluster. On the other hand, an independent storage solution can be connected from different clusters which increases the flexibility. Also if you need to change the data infrastructure, you usually do not need to make any major changes on your application side. In our view, a [Ceph cluster](https://ceph.io/) is the best way to provide a stable and scalable storage solution for Kubernetes.

<p align="center"><img src="./doc/images/architectrue-01.png" /></p>

In this picture your application layer is decoupled from your data layer. You can use your data layer in various ways independent from your Kubernetes cluster which gives you more flexibility managing your data. For example if you run more than one Kubernetes cluster you can connect both to the same Ceph cluster.
In general, we do not recommend building a cluster that is too big, but rather several small clusters.  This allows you to migrate data and applications if your requirements grow faster than you have planed in the beginning or if you want to try something new. With the *Imixs-Cloud* project it is easy to setup and manage these kind of small cluster environments. 

 
## Infrastructure as Code
 
The complete infrastructure of a *Imixs-Cloud* environment is described in one central configuration directory. The *Configuration Directory* can be synchronized with a code repository like Git. This concept is also known as *Infrastructure as Code* and makes it easy to role back changes if something went wrong. You can always start with a new environment by just [forking this Github repository](./doc/GIT.md). 

	$ git clone https://github.com/imixs/imixs-cloud.git && rm -rf imixs-cloud/.git/

The imixs-cloud directory structure contains different sub-directories holding your applications, scripts and tools:

	/-
	 |+ management/
	    |- monitoring/
	    |- registry/
	    |- nginx/
	 |+ apps/
	    |+ MY-APP/
	       |  001-deployment.yaml
	    .....
	 |+ scripts/
	    |  apply.sh
	    |  setup.sh
	    |  delete.sh
	 |+ tools/


 - **apps/** is the place where where your custom business services are configured. Each sub-directory holds at least one kubernetes object description (yaml file). Optional additional configuration files are also located in this directory. 

 - **management/** in this directory you can find all the management services which are part of the *Imixs-Cloud*. This different service are maintained by this project and can be customized for individual needs. 

 - **scripts/**  provides bash scripts to setup a new kubernetes node.

 - **tools/**  provides useful tools



### How to Create and Delete Objects

You can define your own services within the /apps/ directory. Each application has its own sub-folder and consists at least of one configuration yaml file 

	 |+ apps/
	    |+ MY-APP/
	       |  020-deployment.yaml

Using the `kubectl apply` command you can easily create or delete your services and objects defined within a apps/ or management/ sub-directory:

	$ kubectl apply -f apps/MY-APP/

For example to deploy the whoami sample service you just need to call:

	$ kubectl apply -f app/whoami/
	
In kubernetes all resources and services are typically described in separate files. Use a naming convention to create an implicit order in which way your objects should be created.

	 |+ whoami/
	    |- 010-deployment.yaml
	    |- 020-service.yaml
	    |- 030-ingress.yaml


If you want to remove an already deployed service or object just use the `delete` command:

	$ kubectl delete -f app/whoami/


You can also use the Kubernetes tool [Kustomize](https://kubernetes.io/docs/tasks/manage-kubernetes-objects/kustomization/) to manage your configuraiton objects in a more flexible way. Read the section [Kustomize Deployments](doc/KUSTOMIZE.md) for more details. 



# Quick Start

The architecture of a *Imixs-Cloud* consists of one Kubernetes master node and one or many Kubernetes worker nodes. This basic architecture can be extended in any dimension. 

<img src="./doc/images/imixs-cloud-architecture.png" />

For a quick setup you need at least a Debian 10 (Buster) server with a public Internet address and a user with sudo privileges.
All configuration files and scripts are provided in this git repository. You can clone the repository or just copy what you need. You will find a detailed installation guide in the [setup section](doc/SETUP.md).

## 1. Install Kubernetes

First clone this git repository on your master node. Therefore, you may need to install git:

	$ sudo apt install -y git 
	   
If you are running Fedora or CentOS than use the yum installer
	   
	$ sudo yum install -y git 


next you can clone the imixs-cloud repo from github....

	$ cd && git clone https://github.com/imixs/imixs-cloud.git
	$ cd imixs-cloud/

now you can run the setup script on your master node to install Docker and Kubernetes:
 
	$ sudo ./scripts/setup_debian.sh

If you are running Fedora or CentOS than run:

	$ sudo ./scripts/setup_centos.sh

You can find details about how to create a cluster on the [official kubernets documentation](https://kubernetes.io/docs/setup/production-environment/tools/kubeadm/create-cluster-kubeadm/). 
 
## 2. Initialize Your Kubernetes Master Node

After the basic setup, run the  _kubeadm_  tool to setup your kubernetes master node:

	$ sudo kubeadm init --pod-network-cidr=10.244.0.0/16 --apiserver-advertise-address={NODE_IP_ADDRESS}

Replace {NODE\_IP\_ADDRESS} with your servers IP address. For a HA cluster you need also to specify the --control-plane-endpoint (see the [setup guide](./doc/SETUP.md) for details)

At the end the init command will give a install guide how to install the commandline tool 'kubectl' on your host. 

Now deploy a cluster network, this is needed for the internal communication between your cluster nodes. 

	$ kubectl apply -f https://raw.githubusercontent.com/coreos/flannel/master/Documentation/kube-flannel.yml

## 3. Setup Your Kubernetes Worker Nodes

To build your cluster you can join any worker node into your new kubernetes cluster. Just repeat the step 1 on each of your worker nodes. 
After the basic setup on a new worker node is completed, you can join your worker node into your new cluster using the join command from your master node:

	$ sudo kubeadm join xxx.xxx.xxx.xxx:6443 --token xxx.xxxxxxxxx  --discovery-token-ca-cert-hash xxxxxxxxxxxxxxxxxxxxxxxxxxxxxx 

If you do not know the join command run the following command on your master node. This command will just print out the command you need to join the cluster from your worker node:

	$ kubeadm token create --print-join-command
 
After a new worker has joined the cluster you can check the status of your master and worker nodes:

	$ kubectl get nodes

	 
**That's it! Your kubernetes cluster is ready**

You will find a more detailed description about how to setup your Kubernetes cluster in the [setup section](doc/SETUP.md). If you have any probelm or questions just open a new [Issue](https://github.com/imixs/imixs-cloud/issues) on Github. 
In the following sections you will find more information about the concepts of Imixs-Cloud.


 
# The Basic Architecture

The basic architecture of the _Imixs-Cloud_ consists of the following components:

 * A Kubernetes Cluster running on virtual or hardware nodes. 
 * One master node, providing the central services.
 * One or many worker nodes to run your services and applications. 
 * A central Reverse-Proxy service to dispatch requests from the Internet (listening on port 80).
 * A management UI and CLI running on the management node.
 * A private registry to store custom docker images.
 * A distributed storage solution for stateful services. 
 


## GitOps

As *Imixs-Cloud* supports the concept of *Infrastructure as Code* you can setup declarative, continuous deliverys - called GitOps - with the tool Argo CD.

<img src="doc/images/argocd-002.png" />
 
This allows you to controll all you application deployments form a modern Web UI and automate the synchronization of your infrastructure.  
Find a detailed description how to install and setup Argo CD in the [section GitOps](./doc/GITOPS.md)



## Manage your Cluster using K9S

To manage your kubernetes cluster you can use [kubectl](https://kubernetes.io/docs/reference/kubectl/overview/), which is already installed on your master node. There is a huge number of commands to obtain information or change configurations. Take a look into the [kubectl Cheat Sheet](https://kubernetes.io/docs/reference/kubectl/cheatsheet/).

A more convenient way to obtain information about your cluster provides the tool [K9s](https://github.com/derailed/k9s). K9s is a powerful terminal tool to interact with your Kubernetes cluster. 


<img src="doc/images/k9s.png" />


To install k9s in _Imixs-Cloud_ follow the setup guide [here](tools/k9s/README.md).
After you have install the tool you can start it with:

	$ ~/imixs-cloud/tools/k9s/k9s



## NGINX

To access your applications from outside of your cluster *Imixs-Cloud* provides the [NGINX Ingress Controller](https://github.com/kubernetes/ingress-nginx).   This tool allows you to easily expose your services in the Intranet or to public Internet addresses.
The Ingress setup of *Imixs-Cloud*  already includes the ACME provider [Let's Encrypt](https://letsencrypt.org/). This makes it easy to publish services to the Internet in a secure way. 

You can find a detailed description how to install and setup the NGINX Ingress Controller in the [section ingress](./doc/INGRESS.md)


## Storage Volumes

To run stateful docker images (e.g. a Database like PostgreSQL) you need to define a storage volume along with your service. Due to its simplicity and the very good integration in Kubernetes, we use [Longhorn](https://longhorn.io/) as the preferred storage solution within Imixs-Cloud.

<img src="doc/images/storage-longhorn-01.png" />


You can find a detailed description how to install and setup a Longhorn storage solution in the [section storage](./doc/STORAGE.md)


## Registry

Docker images are available on docker registries. The _Imixs-Cloud_ includes a setup to run a private Docker Registry. 
You can find a detailed description how to install and setup the registry in the [section registry](./doc/REGISTRY.md)


## Monitoring

_Imixs-Cloud_ also provides also a monitoring feature which allows you to monitor your Kubernetes cluster.

<img src="./doc/images/monitoring-001.png" />  
  
The monitoring is based on [Prometheus](https://prometheus.io/) which is an open-source systems monitoring and alerting toolkit. You can use this monitoring service not only to montor your kubernetes cluster but also to monitor specific application data. Read more about the monitoring feature [here](doc/MONITORING.md).
  
# Contribute

_Imixs-Cloud_ is open source and your are sincerely invited to participate in it. 
If you want to contribute to this project please [report any issues here](https://github.com/imixs/imixs-cloud/issues). 
All source are available on [Github](https://github.com/imixs/imixs-cloud).

**Note:** My first version was based on [docker-swarm](https://docs.docker.com/engine/swarm/). If you want to run your cluster with docker-swarm switch into the [docker-swarm branch](https://github.com/imixs/imixs-cloud/tree/docker-swarm).
