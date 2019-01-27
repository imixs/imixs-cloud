# The Imixs-Cloud

_Imixs-Cloud_ is an open infrastructure project, describing a lightweight [docker](https://www.docker.com/) based container environment for business applications.
The main objectives of this project are **simplicity**, **transparency** and **operational readiness**. 
_Imixs-Cloud_ is based on a [docker swarm](https://docs.docker.com/engine/swarm/) and typically
consists of multiple Docker hosts. _Imixs-Cloud_ is optimized to **build**, **run** and **maintain** business services in small and medium-sized enterprises.
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

* The _management node_ is the swarm manager and provides a private registry and a reverse proxy service.
* The _worker nodes_ are serving the business applications. 

Only the _management node_ should be visible via the Internet. _Worker nodes_ are only visible internally by docker swarm. The infrastructure can be easily scaled by adding new worker nodes. 


<img src="doc/imixs-cloud-01.png" />
 
### The Configuration Directory 
 
The complete infrastructure is described in an easy maintainable directory structure of docker files. The _management node_ holds the configuration for all services in a central directory which can be synchronized with a code repository like Git.
The configuration directory is used to setup and run the Imixs-Cloud and its services. The directory can be located in a project directory and is structured like in the following example:

	/-
	 |+ management/
	    |- registry/
	    |- swarmpit/
	    |- traefik/
	 |+ apps/
	    |+ MY-APP/
	       |  docker-compose.yml

The **/management/** sub-folder holds the configuration for all management services running on the management node only. This configuration is maintained by this project and can be customized for individual needs. 

The **/apps/** directory is the place where the custom business services are configured. Each sub-directory holds at least one docker-compose.yml file to startup the corresponding services. Optional additional configuration files are located in this directory. 

You can copy this structure from [GitHub](https://github.com/imixs/imixs-cloud) to setup and create your own _Imixs-Cloud_ environment. 
 
	$ git clone https://github.com/imixs/imixs-cloud.git && rm -rf imixs-cloud/.git/
	
Optional you can also fork the repo directyl on Github. 
 
# How to Setup

_Imixs-Cloud_ is based on [docker](https://www.docker.com/) and its build in tool chain. [Docker-Swarm](https://docs.docker.com/engine/swarm/) is the scheduler service used to run a cluster of docker hosts serving business applications in docker-containers.
Each node in the swarm has at least installed Docker.

Read the following sections to setup a _Imixs-Cloud_ environment:

 * [How to setup Imixs-Cloud](doc/SETUP.md) - basic setup information for a docker-swarm.
 * [The Private Registry](doc/REGISTRY.md) - how to setup and work with a private registry.
 * [How to secure Imixs-Cloud](doc/SECURITY.md) - advanced setup and security information.
 * [HTTPS support](doc/HTTPS_ENCRYPTION.md) - how to setup HTTPS encryption. 
 * [Version Control](doc/VERSIONCONTROL.md) - how to setup a Git repo
 * [Stateful Services](doc/STATEFUL.md) - how to deploy stateful services. 
 * [Monitoring](doc/MONITORING.md) - how to monitor the docker-swarm. 


# How to Manage Services

After you have setup you own _Imixs-Cloud_ environment you can deploy and start your custom business services. 
In Docker-Swarm, containers are started as services within a so called 'stack'. A _stack_ is described by a docker-compose.yml file. In this file you can define settings and parameters and describe dependencies and linked resources. Each service in a stack can communicate with each other in the same stack over the network services provided by docker. 


## Example 

The following example shows a docker-compose file describing a Wordpress application. The example consists of two services - a MySQL database and a wordpress application:



	version: '3.1'
	services:
	# Wordpress Example
	  mysql:
	    image: mysql:5.7
	    volumes:
	      - dbdata:/var/lib/mysql
	    environment:
	      MYSQL_ROOT_PASSWORD: your_root_password
	      MYSQL_DATABASE: wordpress
	      MYSQL_USER: wordpress
	      MYSQL_PASSWORD: "yourpassword"
	    deploy:
	      placement:
	        constraints:
             - node.hostname == worker-1
	    networks:
	      - backend
	
	  wordpress:
	    depends_on:
	       - mysql
	    image: wordpress:4.9.8
	    environment:
	      WORDPRESS_DB_HOST: mysql:3306
	      WORDPRESS_DB_USER: wordpress
	      WORDPRESS_DB_PASSWORD: "yourpassword"
	    volumes: 
	      - wp-content:/var/www/html/wp-content
	    deploy:
	      labels:
	        traefik.port: "80"
	        traefik.frontend.rule: "Host:your.host.local"
	        traefik.docker.network: "imixs-proxy-net"
	      placement:
	        constraints:
             - node.hostname == worker-1
	    networks:
	      - frontend
	      - backend
	
	volumes:
	  dbdata:
	  wp-content:
	
	networks:
	  frontend:
	    external:
	      name: imixs-proxy-net 
	  backend: 



### The Networks
The _Imixs-Cloud_ provides a reverse proxy concept based on [Traefik.io](https://traefik.io/). In the example the wordpress service is mapped to the domain name 'your.host.local'. Traefik.io  automatically manages the routing so that your application is available on port 80. 
In this example both services are bound to a internal overlay network called 'backend'. Only the service 'wordpress' is connected to the external network '_imixs-proxy-net_'. As a result, the service 'wordpress' is visible outside of the stack. This is a typical setup to isolate your services from other applications within your cluster environment. Read the [Imixs-Cloud setup guide](doc/SETUP.md) to learn how the proxy network is working. 

### The Data Volumes
In the example two data volumes are defined. The volumes are used to persist the data of the MySQL database and the Wordpress content files. The services are placed on a specific host (worker-1) to avoid a lost of data. Of course the data can be persisted on other storage independent from a cluster node. 




## How to Deploy a Stack
You can define new custom applications in the /apps/ directory. Each application has its own sub-folder and consists at least of one docker-compose.yml file. 

	 |+ apps/
	    |+ MY-APP/
	       |  docker-compose.yml

To deploy and run a custom application within the Imixs-Cloud, you run the _docker stack deploy_ command:

	docker stack deploy -c apps/MY-APP/docker-compose.yml MY-APP 

### Updating a Stack
If you need to change some configuration or add a new services to a stack, you can restart the already existing stack with the same command. Docker-Swarm will automatically redeploy all affected services. 


### Running Services from the Private Registry
If your stack contains images hosted in a private registry, you need to specify the registry name and port number to enable docker-swarm to download the image.  See the following example:


	version: '3'
	
	services:
	  app:
	    image: my-registry.com:8300/app/my-app:1.0.0
	....

To start the stack run the docker command with the option _--with-registry-auth_. 

	docker stack deploy -c apps/MY-APP/docker-compose.yml MY-APP --with-registry-auth
 
This will force the docker service to authenticate against the registry.
You can setup  a private registry in your _Imixs-Cloud_ environment. See the section "[The Private Registry](doc/REGISTRY.md)"  
  
  
# How to Montior

_Imixs-Cloud_ also provides also a monitoring feature which allows you to monitor your docker-swarm.

<img src="./doc/imixs-cloud-04.png" />  
  
The monitoring is based on [Prometheus](https://prometheus.io/) which is an open-source systems monitoring and alerting toolkit. You can use this monitoring service not only to montor your docker-swarm network but also to monitor specific application data. Read more about the monitoring feature [here](doc/MONITORING.md).
  
# Contribute

_Imixs-Cloud_ is open source and your are sincerely invited to participate in it. 
If you want to contribute to this project please [report any issues here](https://github.com/imixs/imixs-cloud/issues). 
All source are available on [Github](https://github.com/imixs/imixs-cloud).

