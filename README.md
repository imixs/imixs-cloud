# The Imixs-Cloud

_Imixs-Cloud_ is a conceptual infrastructure project, describing a lightweight [docker](https://www.docker.com/) based server environment for business applications.
The main objectives of this project are **simplicity**, **transparency** and **operational readiness**. 


_Imixs-Cloud_ runs on [docker swarm](https://docs.docker.com/engine/swarm/) to **build**, **run** and **maintain** business services.
The project is open source and part of the Open Source project [Imixs-Workflow](http://www.imixs.org). This project is continuous under development and we sincerely invite you to participate in it.


## Rules
The main objectives of this project can be itemized under the following rules:

 1. _A Imixs-Cloud can be setup easily and run on commodity hardware._
 2. _All services and infrastructure components are running on docker swarm._
 3. _The docker command line interface (CLI) is used to setup and manage nodes and services._ 
 4. _Docker UI Front-End components are used to monitor the infrastructure._
 5. _Business applications are deployed to a central Docker-Registry and started as services._
 6. _All services are isolated and accessible only through a central proxy server._
 7. _Scalabillity and configuration is managed by docker-compose._
 
 
## Basic Architecture

The basic architecture of the _Imixs-Cloud_ consists of the following components:

 * A Docker-Swarm Cluster running on virtual or hardware nodes. 
 * One management node, providing central services.
 * One or many worker nodes to run the services. 
 * A central Reverse-Proxy service to dispatch requests (listening on port 80) to applications.
 * A management UI running on the management node.
 * A private registry to store custom docker images.
 
 
### Nodes

A _Imixs-Cloud_ consists of at least two nodes. 

* The management node is the swarm manager and provides a private registry and a reverse proxy service.
* The worker nodes are serving the applications. 

Only the management node should be visible via the internet. Worker nodes are only visible internally in the swarm. The infrastructure can be scaled by adding new worker nodes. 


<img src="doc/imixs-cloud-01.png" />
 
### The Configuration Directory 
 
The management node holds the configuration for all services in a central directory which can be synchronized with a code repository like Git.
The configuration directory is used to setup and run the Imixs-Cloud and its services. The directory can be located in a project directory and is structured like in the following example:

	/-
	 |+ management/
	    |- registry/
	    |- swarmpit/
	    |- traefik/
	 |+ apps/
	    |+ MY-APP/
	       |  docker-compose.yml

The /management/ subfolder holds the configuration for all management services running on the management node only. 
The /apps/ directory contains service setups to start applications running typically on the worker nodes.
Each sub-directory holds at least one docker-compose.yml file to startup the corresponding service and optional additional configuration files. 

You can checkout this structure from [GitHub](https://github.com/imixs/imixs-cloud) or you can create the folders manually. 
 
	$ git clone https://github.com/imixs/imixs-cloud.git
 
# How to Setup

[Docker-Swarm](https://docs.docker.com/engine/swarm/) is used to run a cluster of docker hosts serving business applications in docker-containers.
Each node in the swarm has at least installed Docker.

Read the following sections to setup a _Imixs-Cloud_ environment:

 * [How to setup Imixs-Cloud](doc/SETUP.md) - basic setup information for a docker-swarm.
 * [The Private Registry](doc/REGISTRY.md) - how to setup and work with a private registry.
 * [How to secure Imixs-Cloud](doc/SECURITY.md) - advanced setup and security information.
 * [HTTPS support](doc/HTTPS_ENCRYPTION.md) - how to setup HTTPS encryption. 
 * [Version Control](doc/VERSIONCONTROL.md) - how to setup a Git repo
 * [Stateful Services](doc/STATEFUL.md) - how to deploy stateful services. 


# How to Manage Services

After you have setup the Imixs-Cloud environment you can deploy and start your docker containers. 
In Docker-Swarm, containers are started as services within a so called 'stack'. A _stack_ is described by a docker-compose.yml file. Each service of a stack can comunitcate with eachother in the same stack. A docker-compose file looks like this:

	version: '3.1'
	
	services:
	  app:
	    image: my-registry.com:8300/apps/my-app:1.0.0
	    environment:
	    ....
	    networks:
	      - frontend
	      - backend  
	....
	  db:
	    image: postgres:9.6.1
	    environment:
		....
	    volumes: 
	      - dbdata:/var/lib/postgresql/data
	    networks:
	      - backend
	.....
	volumes:
	  dbdata:
	....
	networks:
	  frontend:
	    external:
	      name: imixs-proxy-net 
	  backend: 


### Networks
In this example there a three services, all bound to a internal overlay network called 'backend'. Only the service 'imixs/imixs-office-workflow' is connected in addition to the external proxy network, so that only this application is visible outside of the stack. Read the [Imixs-Cloud setup guide](SETUP.md) to learn how the proxy network is working. 

### docker deploy stack
You can define new custom applications in the /apps/ directory. Each application has its own sub-folder and consists at least of one docker-compose.yml file. 

	 |+ apps/
	    |+ MY-APP/
	       |  docker-compose.yml

To deploy and run a custom application within the Imixs-Cloud, you run the _docker stack deploy_ command:

	docker stack deploy -c apps/MY-APP/docker-compose.yml MY-APP 

### Updating a Stack
If you need to change some configuration or add a new services to a stack, you can restart the already existing stack with the same command. Docker-Swarm will automatically redeploy all affected services. 


### Running Services form the Private Registry
If your stack contains images hosted on the private registry, you need to specify the registry name and port number to enable docker-swarm to download the image.  See the following example:


	version: '3'
	
	services:
	  app:
	    image: my-registry.com:8300/app/my-app:1.0.0
	....


  
# Contribute

_Imixs-Cloud_ is open source and are sincerely invited to participate in it. 
If you want to contribute to this project please [report any issues here](https://github.com/imixs/imixs-cloud/issues). 
All source are available on [Github](https://github.com/imixs/imixs-cloud).

