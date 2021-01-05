# Imixs-Cloud - Registry

Docker images are available on docker registries. Most of the docker images are available on public regestries like [Docker Hub](https://hub.docker.com/). Kubernetes can download these images automatically.  In contrast, private Docker images are stored in private registries. 
*Imixs-Cloud* provides a setup for a private docker registry which can be used push locally build docker images into the *Imixs-Cloud*.


## Harbor

The *Imixs-Cloud* already provides a setup to run the registry [Harbor](https://goharbor.io/).
*Harbor* is a secure, performant, scalable, and available cloud native repository for Kubernetes. It can be installed using the [helm tool](../tools/helm/README.md)

The installation guide to install Harbor in the *Imixs-Cloud* can be found [here](../management/harbor/README.md)


### The Web UI

After you have installed Harbor you can access the Web UI form your defined Internet Domain.

	https://{YOUR-DOMAIN-NAME}
	
<img src="./images/harbor.png" />

For the first login the default User/Password is:

	admin/Harbor12345

You can change the admin password after the first login and create additional users. A detailed documentation about how to use Harbor can be found [here](https://goharbor.io/).


## How to access a Private Registry from Kubernetes

To allow Kubernetes to access a private registry during the deployment of a Docker image, you need to create a registry secret first. This can be done with the *kubectl* tool :


	$ kubectl create secret docker-registry registry.foo.com \
	   --docker-server=https://registry.foo.com \
	   --docker-username=admin --docker-password=Harbor12345 \
	   --docker-email=info@foo.com \
	   -n mynamespace


Now you can reference this secret in a deployment .yaml file to pull the image from your private registry:

	....
	apiVersion: apps/v1
	kind: Deployment
	metadata:
	...
	template:
	  ....
	  spec:
        containers:
        - image: registry.foo.com/library/myimage:latest
        ....
        imagePullSecrets:
        - name: registry.foo.com




**Note:** *imagePullSecrets* are defined per namespace. So even if you use the same Harbor user to access the registry you have to create a separate secrete for each namespace. In this way you have the full control which project is allowed to pull Docker images from your private registry. 
You can find more details about how to pull an image form a private registry [here](https://kubernetes.io/docs/tasks/configure-pod-container/pull-image-private-registry/). 
	
## How to Upload a Local Docker Image

After you setup the harbor registry you can upload custom Docker images either manually via the Web UI or with the *docker push* command. 
To be allowed to push/pull images with Docker into a private registry, you first need to login Docker with the userid and password from your local client. 

	$ sudo docker login -u admin {YOUR-DOMAIN-NAME}

**Note:** In case you run Harbor with the Ingress configuration and a Let's Encrypt certificate, there is no need to deal with the non-trusted TLS certificates. 

To push a local docker image into the registry you first need to tag the image with the repository uri

	$ docker tag SOURCE_IMAGE[:TAG] {YOUR-DOMAIN-NAME}/library/IMAGE[:TAG]

**Note:** '/library/' is the project library name defined in Harbor!

next you can push the image:

	$ docker push {YOUR-DOMAIN-NAME}/library/IMAGE[:TAG]	
	
	




