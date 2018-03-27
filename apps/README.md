# Applications

The /apps/ directory holds the configuration of applications running as services in the docker-swarm environment.
Each application has its own application directory holding at least a docker-compose.yml file to start the application.
The application can be started with the _docker stack deploy_ command:


	$ docker stack deploy -c apps/MY-APP/docker-compose.yml MY-APP

The directory apps/whomai/ holds an example. To test the environment you can deploy the test service /emilevauge/whoami . This docker container simply displays the location of itself.

	$ docker stack deploy -c apps/whomai/docker-compose.yml whomai


The docker-compose.yml file for this example looks like:

	version: '3'
	
	services:
	 app:
	   image: emilevauge/whoami
	   
	   deploy:
	     labels:
	      traefik.port: "80"
	      traefik.frontend.rule: "Host:whoami.your-domain.com"
	      traefik.traefik.docker.network: "imixs-proxy-net"
	   
	networks:
	   default:
	    external:
	      name:  imixs-proxy-net    

The labels for traefik configure the reverse proxy server traefik:

* traefik.port - is the port number exposed by the container to be used by traefik to forward requests
* traefik.frontend.rule - this is the virtual host name (dns)
* traefik.docker.network - must be the same overlay network traefik is running in (usually:  imixs-proxy-net)

__Important:__ The label _traefik.docker.network_ is important here and must be set to 'imixs-proxy-net' which is our frontend network. Otherwise, if the container is linked to several networks (e.g. a backend network for a database and a frontend network for the reverse proxy), traefik will randomly pick one (depending on how docker is returning them). This will result in a situation where traefik is not finding the correct route to the backend service and will end up with a 'Gateway Timeout' message. 

## Registry Authentication

In case the service is forced to load images from the private registry the option _--with-registry-auth_ must be provided.
When using docker stack deploy in a swarm, this option will forward the login information to the worker  nodes. 

	$ docker stack deploy --with-registry-auth -c apps/MY-APP/docker-compose.yml MY-APP
