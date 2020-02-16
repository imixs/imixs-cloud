# Imixs-Cloud - Registry

Docker images are available on docker registries. Most public docker images are available on [Docker Hub](https://hub.docker.com/). In the _Imixs-Cloud_  you can also setup your own private docker registry.
A private registry can be used to push locally build docker images to be used in the cloud infrastructure. Images can be pulled and started as services without the need to build the images from a Docker file.


## Habor

The _Imixs-Cloud_ already includes a configuration to run the registry [Habor](https://goharbor.io/).
_Habor_ is a secure, performant, scalable, and available cloud native repository for Kubernetes. It can be installed useing heml.


## Installation

Habor consists of several services. To make it easy to install Habor the right way you can use `helm`. Make sure that you have installed helm (see the install script `scripts/get_helm.sh`)

### Add the harbor helm repository

First add the Helm repository for Harbor

	$ helm repo add harbor https://helm.goharbor.io

Now you can install Harbor using the corresponding chart. 


### Install Harbor 

The Harbor Helm chart comes with a lot of parameters which can be applied during installation using the `--set` parameter. See the [Habor Helm Installer](https://github.com/goharbor/harbor-helm) for more information.

The following command installs harbor into the _Imixs-Cloud_. 
	
	$ helm install registry harbor/harbor --set persistence.enabled=false\
	  --set expose.type=nodePort --set expose.tls.enabled=true\
	  --set externalURL=https://{MASTER-NODE}:30003\
	  --set expose.tls.commonName={MASTER-NODE}

replace the `{MASTER-NODE}` with the DNS name of your master node. 

After a few seconds you can access harbor from your web browser via https:

	https://{MASTER-NODE}:30003
	
The default User/Password is:

	admin/Harbor12345		
	
<img src="./images/harbor.png" />
	
### Uninstall Harbor	

To uninstall/delete the registry deployment:

	$ helm uninstall registry

	


# How to grant a Docker Client

After you setup the harbor registry you can upload custom Docker images to be used by services running in the Imixs-Cloud. 

To  be allowed to push/pull images from the private docker registry hosted in your Imixs-Cloud, a copy of the certificate need to be copied into the docker certs.d directory of your local client and the docker service must be restarted once:

You can download the Harbor certificate from the Habor web frontend from your web browser or via command line :

	$ wget -O ca.crt --no-check-certificate https://{MASTER-NODE}:30003/api/systeminfo/getcert

replace {MASTER-NODE} with your cluster master node name.

now create a new directly in your local docker/certs.d directory and copy the certificate:

	$ mkdir -p /etc/docker/certs.d/{MASTER-NODE}:30003
	$ cp ca.crt /etc/docker/certs.d/{MASTER-NODE}:30003/ca.crt
	$ service docker restart
	
Now you need to first login to your registry with docker:

	$ docker login -u admin {MASTER-NODE}:30003
	

# Push a local docker image

To push a local docker image into the registry you first need to tag the image with the repository uri

	$ docker tag SOURCE_IMAGE[:TAG] {MASTER-NODE}:30003/library/IMAGE[:TAG]

**Note:** '/library/' is the project library name defined in Harbor!

next you can push the image:


	$ docker push {MASTER-NODE}:30003/library/IMAGE[:TAG]	
	