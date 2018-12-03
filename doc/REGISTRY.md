# Imixs-Cloud - Registry

Docker images are available on docker registries. Most public docker images are available on [Docker Hub](https://hub.docker.com/). In the _Imixs-Cloud_  you can also setup your own private docker registry.
A private registry can be used to push locally build docker images to be used in the cloud infrastructure. Images can be pulled and started as services without the need to build the images from a Docker file.

# Setup a Private Registry 

The _Imixs-Cloud_ already includes a configuration to run a private registry. The registry stores its data into a [data volume](https://docs.docker.com/engine/admin/volumes/), so the registry data is stored within a directory on the Docker management node. 

### Create a Self Signed Certificate
The private registry in the _Imixs-Cloud_ is secured with a TLS (Transport Layer Security). This guaranties that only authorized clients can push or pull an image from the registry.  To secure the registry, a self signed certificate for the manager-node is needed. 

To create the certificate a DNS host name for the manager-node is needed. The following example registers the DNS name '_manager-node.com_'. The keys are stored in the directory _registry/_:


	mkdir -p ./management/registry/certs && cd ./management/registry/certs
	openssl req -newkey rsa:4096 -nodes -sha256 \
	            -keyout domain.key -x509 -days 356 \
	            -out domain.cert 
	            
	Generating a 4096 bit RSA private key
	................................................++
	writing new private key to 'registry_certs/domain.key'
	-----
	You are about to be asked to enter information that will be incorporated
	into your certificate request.
	What you are about to enter is what is called a Distinguished Name or a DN.
	There are quite a few fields but you can leave some blank
	For some fields there will be a default value,
	If you enter '.', the field will be left blank.
	-----
	Country Name (2 letter code) [AU]:DE
	State or Province Name (full name) [Some-State]:
	Locality Name (eg, city) []: 
	Organization Name (eg, company) [Internet Widgits Pty Ltd]: 
	Organizational Unit Name (eg, section) []:
	Common Name (e.g. server FQDN or YOUR name) []:manager-node.com
	Email Address []:

In this example a x509 certificate and a private RSA key is created with the DNS name (‘Common Name’) _manager-node.com_.
openssl creates two files in the folder 'management/registry/certs/':

* domain.cert – this file can be handled to the client using the private registry
* domain.key – this is the private key which is necessary to run the private registry with TLS

The configuration of the registry service is defined by docker-compose.yml located in the folder 'registry/'
Create a docker-compose.yml file. (See /registry/docker-compose.yml). 

Now the registry-service can be started with :

	docker stack deploy -c management/registry/docker-compose.yml registry
	
The registry will be available under port 8300 of the manager-node.

You can check the registry API via the Rest API:

	https://manager-node.com:8300/v2/



### Add the registry into your Swarm UI

If you have installed a docker swarm-ui you can add the prived registry. 
Add the registry by the URL “https://manager-node-com:8300/”






# How to grant a Client

After you setup the private registry you can upload custom Docker images to be used by services running in the Imixs-Cloud. 

To grant your local client to be allowed to push/pull images from the private docker registry hosted in your Imixs-Cloud, a copy of the certificate need to be copied into the docker certs.d directory of your local client and the docker service must be restarted once:

	mkdir -p /etc/docker/certs.d/manager-node.com:8300
	cp domain.cert /etc/docker/certs.d/manager-node.com:8300/ca.crt
	service docker restart

# How to Push a Docker Image into the Registry

To push a local image from a client into the Imixs-Cloud registry, the image must be tagged first. The following example pushes an image name 'apps/my-app' into the registry with the version numer '1.0.0':

	docker tag apps/my-app manager-node.com:8300/apps/my-app:1.0.0
	docker push manager-node.com:8300/apps/my-app:1.0.0

The push refers to a Imixs-Cloud repository on the host [manager-node.com:8300]




### Authentication

If you already have defined a HTTPs Basic authentication layer as described in the section [How to secure Imixs-Cloud](SETUP.md), you need to first login to your docker registry:

	 docker login -u admin https://manager-node.com:8300

After the successful login, you can push the image.

**Note:** This is also true for the master-node itself if a service need to pull a image from the private registry. 
