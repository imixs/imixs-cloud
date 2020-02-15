# Habor

[Habor](https://goharbor.io/) is a secure, performant, scalable, and available cloud native repository for Kubernetes. It can be installed useing heml.


## Installation

Habor consists of several servess. To make it easy to install Habor the right way we use `helm`. Make sure that you have installed helm (see the install script `scripts/get_helm.sh`)

First add the Helm repository

	$ helm repo add harbor https://helm.goharbor.io


### Install the chart

To install the Harbor you run the helm chart. This chart comes with a lot of parameters which can be set using the `--set` parameter. See the [Habor Helm Installer](https://github.com/goharbor/harbor-helm) for more information.


#### Intall Harbor 

The following command installs habor in a test mode. 

	$ helm install registry harbor/harbor --set persistence.enabled=false --set expose.type=nodePort --set expose.tls.enabled=false --set externalURL=http://{NODE_IP_ADDRESS}:30002

replace the `{NODE_IP_ADDRESS}` with the IP address of your worker node. 

After a few seconds you can access harbor from your web browser:

	http://{NODE_IP_ADDRESS}:8300
	
The default User/Password is:

	admin/Harbor12345		
	
	
	
### Push a local docker image

To push a local docker image into the registry you first need to tag the imige with the repository uri



	$ docker tag SOURCE_IMAGE[:TAG] {NODE_IP_ADDRESS}:30002/library/IMAGE[:TAG]

next you can push the image:


	$ docker push {NODE_IP_ADDRESS}:30002/library/IMAGE[:TAG]	
	
**Note:** you need to first login to your registry with docker:

	$ docker login -u admin {NODE_IP_ADDRESS}:30002

After the successful login, you can push the image.	


	$ docker login -u admin  https://{NODE_IP_ADDRESS}:30002/v2/







	
	
### Uninstall Harbor	

To uninstall/delete the registry deployment:

	$ helm uninstall registry



	
	

	