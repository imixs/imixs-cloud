# How to setup the Imixs-Cloud

The following section describes the setup procedure of _Imixs-Cloud_ with [Docker-Swarm](https://docs.docker.com/engine/swarm/) into a productive environment. 

Read the following tutorial for general information about how to setup a Docker-Swarm:

* [Official Docker-Swarm Tutorial](https://docs.docker.com/engine/swarm/swarm-tutorial/)
* [Lightweight Docker Swarm Environment - by Ralph Soika](http://ralph.soika.com/lightweight-docker-swarm-environment/)
* [How to Run Docker-Swarm on VM Servers - by Ralph Soika](http://ralph.soika.com/how-to-run-docker-swarm-on-a-vm-servers/)

## Nodes

A _Imixs-Cloud_ consists of a minimum of two nodes.

* The management node is the swarm manager and provides a private registry and a reverse proxy service.
* The worker nodes are serving the applications. 

A node can be a virtual or a hardware node. All nodes are defined by unique fixed IP-addresses and DNS names. Only the manager-node need to be accessible through the internet. All nodes in the swarm must have docker installed and be able to access the manager at the IP address.

### Install Docker

To install docker on a node follow the [official installation guide for Docker CE](https://docs.docker.com/engine/installation/linux/docker-ce/debian/).
If you have unix user to run the docker cli, you have to add the user to the group 'docker'

	adduser username docker
	
### Directories

The management node has the following directory structure located in the manager home directory to setup and run the Imixs-Workflow-Cloud and its services. 

	/-
	 |- management/
	 |   - registry/
	 |   - swarmpit/
	 |   - traefik/
	 |- apps/

The /management/ directory holds the service configuration for the management services running on the management node only. 
The /apps/ directory contains service setups to start applications running on the worker nodes.
	

### Open networks, protocols and ports

The following ports must be available on each node. 

 - TCP port 2377 for cluster management communications
 - TCP and UDP port 7946 for communication among nodes
 - UDP port 4789 for overlay network traffic
 
The following ports will be later published to be accessable from the internet:

 * 80 - The Reverse proxy endpoint 
 * 8100 - The reverse proxy server UI traefik
 * 8200 - The swarm management UI swarmpit
 * 8300 - The imixs private registry


## Init the swarm manager

To setup docker swarm on the management-node run the following command:

	$ docker swarm init --advertise-addr [manager-ip-address]
	
'manager-ip-address' is the fixed ip address of the manger node to be used by worker nodes. (Typically the main address of the manager-node)


This command init the swarm and returns a pre-configured docker swarm join command for to be executed on any worker-node to joint the swarm. For example: 

	$ docker swarm join --token SWMTKN-1-xxxxxxxxxxxxxxxxxxxx-xxxxxxxx 192.168.99.100:2377
	

The IP address given here is the IP from the manager-node.
To get the join token later run the following command on the manager node:

	$ docker swarm join-token worker 

Working with VMs, the worker-node has typically a private IPv4 address. As a result the swarm may not run correctly, specially in relation with overlay networks. To solve those problems the public IPv4 address of the worker-node need to be added with the option  _–advertise-addr_ when joining the swarm.


	docker swarm join \
	 --token SWMTKN-1-xxxxxxxxxxxxxxxxxxxx-xxxxxxxx \
	 --advertise-addr [worker-ip-address]\
	 [manager-ip-address]:2377

Where [worker-ip-address] is the public IPv4 address of the worker-node joining the swarm.


To verify the nodes in a swarm run:

	$ docker node ls
	ID				HOSTNAME 	STATUS 		AVAILABILITY 	MANAGER STATUS
	niskvdwg4k4k1otrrnpzvgbdn * 	manager1	Ready 		Active 		Leader
	c54zgxn45bvogr78qp5q2vq2c 	worker1		Ready 		Active 

To inspect a node in detail to see if the correct IP is given, run:

	docker node inspect worker1

### Create Overlay Networks

The nodes in the Imixs-Cloud  communicate via two different overlay networks:

 * imixs-cloud-network - used for the swarm 
 * imixs-proxy-network - used by the reverse proxy
 
To create the overlay networks on the manager-node run:

	$ docker network create --driver=overlay imixs-cloud-net
	$ docker network create --driver=overlay imixs-proxy-net

 
### The Swarm UI – swarmpit.io
_Imixs-Cloud_ uses [swarmpit.io](http://swarmpit.io) as a lightweight Docker Swarm management UI. 
swarmpit.io is started as a service on the manager node. The configuration is defined by docker-compose.yml located in the folder 'swarmpit/'

To start the service on the manager node:

	$ docker stack deploy -c management/swarmpit/docker-compose.yml swarmpit

Note: It can take some minutes until swarmpit is started.

After the swarmpit the front-end can be access on port 8200

http://manager-node.com:8200

<img src="imixs-cloud-02.png" />

The default userid is ‘admin’ with the password ‘admin’.

** Note: ** If you change the network configuration you need to remove and already existing swarmpit service and its volume!


## The Private Docker-Registry

Docker images are available on docker registries. Public docker images are basically available on Docker Hub. _Imixs-Cloud_  uses a private docker registry.
The registry is used to push locally build docker images so that the cloud infrastructure can pull and start those services without the need to build the images from a Docker file.

The imixs-cloud registry stores its data into a [data volume](https://docs.docker.com/engine/admin/volumes/), so the registry data is stored within a directory on the Docker host. 

### Create a Self Signed Certificate
The private registry in the _Imixs-Cloud_ is secured with a TLS (Transport Layer Security). This guaranties that only authorized clients can push or pull an image from the registry.  To secure the registry, a self signed certificate for the manager-node is needed. 

To create the certificate a DNS host name for the manager-node is needed. The following example registers the DNS name '_manager-node.com_'. The keys are stored in the directory _registry/_:


	$ mkdir mkdir -p ./management/registry/certs && cd ./management/registry/certs
	$ openssl req -newkey rsa:4096 -nodes -sha256 \
	            -keyout domain.key -x509 -days 356 \
	            -out domain.cert 
	            
	Generating a 4096 bit RSA private key
	................................................++
	writing new private key to 'registry_certs/domain.key'
	-----
	You are about to be asked to enter information that will be incorporated
	into your certificate request.
	What you are about to enter is what is called a Distinguished Name or a DN.
	There are quite a few fields but you can leave some blank
	For some fields there will be a default value,
	If you enter '.', the field will be left blank.
	-----
	Country Name (2 letter code) [AU]:DE
	State or Province Name (full name) [Some-State]:
	Locality Name (eg, city) []: 
	Organization Name (eg, company) [Internet Widgits Pty Ltd]: 
	Organizational Unit Name (eg, section) []:
	Common Name (e.g. server FQDN or YOUR name) []:manager-node.com
	Email Address []:

In this example a x509 certificate and a private RSA key is created with the DNS name (‘Common Name’) _manager-node.com_.
openssl creates two files in the folder 'management/registry/certs/':

* domain.cert – this file can be handled to the client using the private registry
* domain.key – this is the private key which is necessary to run the private registry with TLS

The configuration of the registry service is defined by docker-compose.yml located in the folder 'registry/'
Create a docker-compose.yml file. (See /registry/docker-compose.yml). 

No the registry-service can be started with :

	$ docker stack deploy -c management/registry/docker-compose.yml registry
	
The registry will be available under port 8300 of the manager-node.

You can check the registry API via the Rest API:

	https://manager-node.com:8300/v2/

### How to grant a Client
To grant your local client to be allowed to push/pull images from the new private docker registry, a copy of the certificate need to be copied into the docker certs.d directory of local client and the docker service must be restart once:


	$ mkdir -p /etc/docker/certs.d/manager-node.com:8300
	$ cp domain.cert /etc/docker/certs.d/manager-node.com:8300/ca.crt
	$ service docker restart

**Note:** This is also true for the master-node itself. 


To push a local image from a client into the registry the image must be tagged first:

	$ docker tag emilevauge/whoami manager-node.com:8300/emilevauge/whoami
	$ docker push manager-node.com:8300/emilevauge/whoami
	The push refers to a repository [manager-node.com:8300/emilevauge/whoami]
	7384fdb82758: Pushed 
	latest: digest: sha256:f716da0c5896906613b2da5f465c75efd07b1e0e430c2b702c656f4ce2602f69 size: 528


### Authentication

If you already have defined a HTTPs Basic authentication layer as described in the section [How to secure Imixs-Cloud](SETUP.md), you need to first login to your docker registry:

	 $ docker login -u admin https://manager-node.com:8300

After the successful login, you can push the image.

**Note:** This is also true for the master-node itself if a service need to pull a image from the private registry. 

### Add the registry into swarmpit

The private registry can also be added into swarmpit -  “Registry -> NEW REGISTRY“. Add the URL “https://manager-node-com:8300/”

## The HTTP Reverse Proxy – traefik.io

The HTTP reverse proxy is used to hide services from the internet. In addition the proxy also acts as a load balancer to be used if applications need to be scaled over several nodes.

In _Imixs-Cloud_ [traefik.io](traefik.io) is used as the service for a reverse proxy. 
The service uses a separate overlay network to scann for services. A service which should be available through the proxy need to be run in the network 'imixs-proxy-net'. 

Traefik is configured by a docker-compose.yml file and a traefik.toml file  located in the folder 'management/traefik/'

To start the service on the manager node:

	$ docker stack deploy -c management/traefik/docker-compose.yml proxy
    
    
After traefik is stared you can access the web UI via port 8100

	http://manager-node.com:8100

<img src="imixs-cloud-03.png" />

**Note: **The Traefik configuraiton is done in the traefik.toml file. You can set the logLevel to "DEBUG" if something goes wrong. 

To test the proxy you can start the whoami service:

	
	docker service create \
	    --name whoami1 \
	    --network imixs-proxy-net \
	    --label traefik.port=80 \
	    --label traefik.frontend.rule=Host:whoami.imixs.com \
	    --label traefik.docker.network=imixs-proxy-net \
	    emilevauge/whoami
	
 