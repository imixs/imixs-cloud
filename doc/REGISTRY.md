# Imixs-Cloud - Registry

Docker images are available on docker registries. Most public docker images are available on [Docker Hub](https://hub.docker.com/). In the *Imixs-Cloud*  you can also setup your own private docker registry.
A private registry can be used to push locally build docker images to be used in the cloud infrastructure. Images can be pulled and started as services without the need to build the images from a Docker file.


## Habor

The *Imixs-Cloud* already includes a configuration to run the registry [Habor](https://goharbor.io/).
*Habor* is a secure, performant, scalable, and available cloud native repository for Kubernetes. It can be installed useing the [helm tool](../tools/helm/README.md)

You will find the installation guide to install Harbor in the *Imixs-Cloud* [here](../management/harbor/README.md)


### The Web UI

Now you can access the Harbor Web UI form your defined Internet Domain or IP address.

	https://{YOUR-DOMAIN-NAME}
	
<img src="./images/harbor.png" />

	
For the first login the default User/Password is:

	admin/Harbor12345

You can change the admin password and create additional users. 


	
## How to grant a Docker Client

After you setup the harbor registry you can upload custom Docker images to be used by services running in the Imixs-Cloud. 

To  be allowed to push/pull images from your new private docker registry you first need to login Docker with the userid and password from the Harbor web ui:

	$ sudo docker login -u admin {YOUR-DOMAIN-NAME}

**Note:** In case you run Harbor with ingress and traefik, there is no need to deal with the TLS certificate because traefik provides you with a Let's Encrypt certificate. See the section below how to deal with a self-signed certificate.


### How to grant a Worker Node

To allow your worker nodes in your Kubernetes Cluster to access the registry, you need to repeat the login procedure for the local Docker Client on each worker node too! Just login to the shell of each worker node and run:	
	
	node-1$ sudo docker login -u admin {YOUR-DOMAIN-NAME}

	

## Push a local docker image

To push a local docker image into the registry you first need to tag the image with the repository uri

	$ docker tag SOURCE_IMAGE[:TAG] {YOUR-DOMAIN-NAME}/library/IMAGE[:TAG]

**Note:** '/library/' is the project library name defined in Harbor!

next you can push the image:


	$ docker push {YOUR-DOMAIN-NAME}/library/IMAGE[:TAG]	
	
	
