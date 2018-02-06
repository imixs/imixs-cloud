# The Imixs-Cloud

_Imixs-Cloud_ is a conceptual infrastructure project, describing a way to create a server environment for business applications.
One of the main objectives of this project is to focus on **simplicity** and **transparency**. 

The general idea is to setup a lightweight [docker](https://www.docker.com/) based infrastructure with [docker swarm](https://docs.docker.com/engine/swarm/). Within this infrastructure business applications like [Imixs-Office-Workflow](http://www.office-workflow.de) can be deployed in a fast and easy way. 

_Imixs-Cloud_ is developed as part of the Open Source project [Imixs-Workflow](http://www.imixs.org) and continuous under development. 


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
 * A Management node providing a registry and a proxy server.
 * One ore many worker nodes to run the services. 
 * A central Reverse-Proxy service to dispatch requests (listening on port 80) to applications.
 * A management UI running on the management node.
 
 
### Nodes

A _Imixs-Cloud_ consists of at least two nodes. 

* The management node is the swarm manager and provides a private registry and a reverse proxy service.
* The worker nodes are serving the applications. 

Only the management node should be visible via the internet. Worker nodes are only visible internally in the swarm. The infrastructure can be scaled by adding new worker nodes. 


<img src="imixs-cloud-01.png" />
 
### Directories 
 
The management node has the following directory structure located in the manager home directory to setup and run the Imixs-Cloud and its services. 

	/-
	 |+ management/
	    |- registry/
	    |- swarmpit/
	    |- traefik/
	 |+ apps/
	    |+ MY-APP/
	       |  docker-compose.yml

The /management/ directory holds the service configuration for the management services running on the management node only. 
The /apps/ directory contains service setups to start applications running on the worker nodes.
Each sub-directory typically holds a docker-compose.yml file to startup the corresponding service and optional additional configuration files. 

You can checkout this structure from the git repo or create the folders by your self. 
 
 
# How to Setup

[Docker-Swarm](https://docs.docker.com/engine/swarm/) is used to run a cluster of docker hosts serving business applications in docker-containers.
Each node in the swarm has at least installed Docker.

Read the following sections to setup a _Imixs-Cloud_ environment:

 * [How to setup Imixs-Cloud](SETUP.md) - basic setup information.
 * [How to secure Imixs-Cloud](SECURITY.md) - advanced setup and security information.
 * [The Private Registry](REGESTRY.md) - how to work with a private registry.


# How to Manage Services

After you have setup the Imixs-Cloud environment you can deploy and start your docker containers. 
In Docker-Swarm, containers are started as services within a so called 'stack'. A _stack_ is described by a docker-compose.yml file. Each service of a stack can comunitcate with eachother in the same stack. A docker-compose file looks like this:

	version: '3.1'
	
	services:
	  app:
	    image: registry.imixs.com:8300/imixs/imixs-office-workflow:3.1.2-SNAPSHOT
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
	    image: my-registry.com:8300/imixs/imixs-office-workflow:3.1.2-SNAPSHOT
	....


  
# Contribute

_Imixs-Cloud_ is open source and are sincerely invited to participate in it. 
If you want to contribute to this project please [report any issues here](https://github.com/imixs/imixs-cloud/issues). 
All source are available on [Github](https://github.com/imixs/imixs-cloud).

