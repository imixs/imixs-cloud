# The Imixs-Cloud

_Imixs-Cloud_ is a conceptual infrastructure project, describing a lightweight [docker](https://www.docker.com/) based server environment for business applications.
The main objectives of this project are **simplicity**, **transparency** and **operational readiness**. 


_Imixs-Cloud_ runs on a [docker swarm](https://docs.docker.com/engine/swarm/)
consisting of multiple Docker hosts acting as managers and workers. _Imixs-Cloud_ is optimized to **build**, **run** and **maintain** business services in small and medium-sized enterprises.
The project is open source and continuous under development. We sincerely invite you to participate in it!


## The Main Objectives
The main objectives of the _Imixs-Cloud_ project can be itemized under the following rules:

 1. _A new environment can be setup easily and run on commodity hardware._
 2. _The docker command line interface (CLI) is the main interface to setup and manage the environment._ 
 3. _Scalabillity and configuration is managed by the core concepts of docker-swarm and docker-compose._
 4. _Docker Images can be deployed to a central Docker-Registry which is part of the environment._
 5. _All services are isolated and accessible through a central reverse proxy server._
 6. _The environment configuration can be managed by a private code repository like Git._
 7. _Docker UI Front-End services are used to monitor the infrastructure._
 
 
## Basic Architecture

The basic architecture of the _Imixs-Cloud_ consists of the following components:

 * A Docker-Swarm Cluster running on virtual or hardware nodes. 
 * One management node, providing central services.
 * One or many worker nodes to run the services. 
 * A central Reverse-Proxy service to dispatch requests (listening on port 80).
 * A management UI running on the management node.
 * A private registry to store custom docker images.
 
 
### Nodes

A _Imixs-Cloud_ consists of at least two nodes. 

* The management node is the swarm manager and provides a private registry and a reverse proxy service.
* The worker nodes are serving the business applications. 

Only the management node should be visible via the internet. Worker nodes are only visible internally by the swarm. The infrastructure can be easily scaled by adding new worker nodes. 


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

The **/management/** subfolder holds the configuration for all management services running on the management node only. This configuration is maintained by this project and can be customized for individual needs. 

The **/apps/** directory is the place where the custom business services are configured. Each sub-directory holds at least one docker-compose.yml file to startup the corresponding services. Optional additional configuration files are located in this directory. 

You can fork this structure from [GitHub](https://github.com/imixs/imixs-cloud) to setup and create your own environment. 
 
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

After you have setup the Imixs-Cloud environment you can deploy and start your custom business services. 
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
In this example there a three services, all bound to a internal overlay network called 'backend'. Only the service 'apps/my-app' is connected in addition to the external proxy network, so that only this application is visible outside of the stack. Read the [Imixs-Cloud setup guide](doc/SETUP.md) to learn how the proxy network is working. 

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

To start the stack run the docker command with the option _--with-registry-auth_. 

	docker stack deploy -c apps/MY-APP/docker-compose.yml MY-APP --with-registry-auth
 
This will force the docker service to authenticate against the registry. 
  
# Contribute

_Imixs-Cloud_ is open source and your are sincerely invited to participate in it. 
If you want to contribute to this project please [report any issues here](https://github.com/imixs/imixs-cloud/issues). 
All source are available on [Github](https://github.com/imixs/imixs-cloud).

