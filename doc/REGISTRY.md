# Imixs-Cloud - Registry

If you setup the Imixs-Cloud as explained in the [Setup Guide](SETUP.md) you can use the private registry to upload custom Docker images to be used by services running in the Imixs-Cloud. 

## How to grant a Client

To grant your local client to be allowed to push/pull images from the private docker registry hosted in your Imixs-Cloud, a copy of the certificate need to be copied into the docker certs.d directory of your local client and the docker service must be restarted once:

	mkdir -p /etc/docker/certs.d/manager-node.com:8300
	cp domain.cert /etc/docker/certs.d/manager-node.com:8300/ca.crt
	service docker restart

## How to Push a Docker Image into the Registry

To push a local image from a client into the Imixs-Cloud registry, the image must be tagged first. The following example pushes an image name 'apps/my-app' into the registry with the version numer '1.0.0':

	docker tag apps/my-app manager-node.com:8300/apps/my-app:1.0.0
	docker push manager-node.com:8300/apps/my-app:1.0.0

The push refers to a Imixs-Cloud repository on the host [manager-node.com:8300]

