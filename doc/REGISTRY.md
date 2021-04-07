# Imixs-Cloud - Registry

Docker images are available on docker registries. Most of the docker images are available on public registries like [Docker Hub](https://hub.docker.com/). Kubernetes can download these images automatically.  In contrast, private Docker images are stored in private registries. 
*Imixs-Cloud* provides a setup for a private docker registry which can be used push locally build docker images into the *Imixs-Cloud*.


## The Docker Registry

The *Imixs-Cloud* already provides a setup to run the official [Docker Registry](https://hub.docker.com/_/registry).
The Docker Registry 2.0 can be used to store and distribute private and public Docker images.

The installation guide to install the Docker Registry into the *Imixs-Cloud* can be found [here](../management/registry/README.md)


### The Rest API

After you have installed the Docker Registry you can access the Rest API from your defined Internet Domain.

	https://{YOUR-DOMAIN-NAME}/v2/_catalog

This url is just to test if everything works fine and your uploaded images are visible. 

### Security

Securing you Docker Registry for authorized access only can be easily implemented with the help of the [NGINX Ingress Controller](./INGRESS.md). 

You just need to create a basic auth file used for a Basic Authentication mechanism to protect the registry. In the install directory you can use the script *adduser.sh*:

	$ ./keys/adduser [USERID] [PASSWORD]

This creates the file 'auth' with the specified user/password. You can add multiple users with the script. Find details in the [install section](../management/registry/README.md)

### Multiple Libraries

If you need multiple libraries for different projects or user groups, you can deploy a new library in a separate namespace. The namespace concept allows you to isolate registries for specific purpose. 

Just edit the 'namespace' tag in the yaml files.

## How to access a Private Registry from Kubernetes

To allow Kubernetes to access a private registry during the deployment of a Docker image, you need to create a registry secret first. This can be done with the *kubectl* tool :


	$ kubectl create secret docker-registry registry.foo.com \
	   --docker-server=https://registry.foo.com \
	   --docker-username=admin --docker-password=12345 \
	   --docker-email=info@foo.com \
	   -n registry


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
        - image: registry.foo.com/myimage:latest
        ....
        imagePullSecrets:
        - name: registry.foo.com



**Note:** *imagePullSecrets* are defined per namespace. So even if you use the same user to access the registry you have to create a separate secret for each namespace. In this way you have the full control which project is allowed to pull Docker images from your private registry. 
You can find more details about how to pull an image form a private registry [here](https://kubernetes.io/docs/tasks/configure-pod-container/pull-image-private-registry/). 
	
## How to Upload a Local Docker Image

After you setup the registry you can upload custom Docker images either manually via the Web UI or with the *docker push* command. 
To be allowed to push/pull images with Docker into a private registry, you first need to login Docker with the userid and password from your local client. 

	$ sudo docker login -u admin {YOUR-DOMAIN-NAME}

**Note:** In case you run registry with the Ingress configuration and a Let's Encrypt certificate, there is no need to deal with the non-trusted TLS certificates. 

To push a local docker image into the registry you first need to tag the image with the repository uri

	$ docker tag SOURCE_IMAGE[:TAG] {YOUR-DOMAIN-NAME}/IMAGE[:TAG]


next you can push the image:

	$ docker push {YOUR-DOMAIN-NAME}/IMAGE[:TAG]	
	
	

## Harbor

As an alternative open source registry you can also use [Harbor](https://goharbor.io/). See the [setup guide](../management/harbor/README.md) for details. 


