# Docker Registry

The following section explains how to setup the Docker Registry into the *Imxis-Cloud*.


## The Data Volume

The images uploaded into your registry are stored in a data volume. We use the  distributed block storage longhorn here. See the section [Longhorn](../../doc/LONGHORN.md) how to setup a Longhorn system.

Before you start the deployment, make sure that you have created a longhorn volume with the following settings:

	size: 10G 
	name: registry-data
	storageClassName: longhorn-durable


## The Ingress Configuration

To access the docker registry via an Ingress on NGINX, it is necessary to replace the hostname in the file 030-network.yaml. Replace {YOUR-DOMAIN-NAME} with your own Internet name:

	kind: Ingress
	apiVersion: networking.k8s.io/v1
	metadata:
	  name: docker-registry
	  namespace: registry
	  annotations:
	    nginx.ingress.kubernetes.io/proxy-body-size: "0"
	    nginx.ingress.kubernetes.io/proxy-read-timeout: "600"
	    nginx.ingress.kubernetes.io/proxy-send-timeout: "600"
	    cert-manager.io/cluster-issuer: "letsencrypt-prod"
	    # optional authentication
	    nginx.ingress.kubernetes.io/auth-type: basic
	    nginx.ingress.kubernetes.io/ssl-redirect: 'false'
	    nginx.ingress.kubernetes.io/auth-secret: registry-basic-auth
	    nginx.ingress.kubernetes.io/auth-realm: 'Authentication Required '		    
	spec:
	  tls:
	  - hosts:
	    - {YOUR-DOMAIN-NAME}
	    secretName: docker-registry-tls
	  rules:
	  - host: {YOUR-DOMAIN-NAME}
	    http:
	      paths:
	      - path: /
	        pathType: Prefix
	        backend:
	          service:
	            name: docker-registry
	            port:
	              number: 5000

You can find details how to setup the NGNIX Ingress Controller [here](../../doc/INGRESS.md).


## Security

The Ingress configuration used here enables Authentication of your registry. This means only authenticated users can access the registry form Internet. 

To protect you registry via the NGNIX Ingress Controller you need a separate auth file. Using the script /keys/adduser.sh  you can create a auth file for basic authentication on your master node.

	$ ./keys/adduser [USERID] [PASSWORD]
	
The script creates the file 'auth' with the specified user/password. You can add multiple users with the script. 

Next you can create a secret in your namespace the Ingress is defined:

	$ kubectl create secret generic registry-basic-auth -n registry --from-file=management/registry/keys/auth

If you changed the auth file by adding new users you need to delete the exisiting secret before you can update the secret
	
	$ kubectl delete secret registry-basic-auth -n registry

You can find more details how to secure a NGNIX Ingress [here](../../doc/INGRESS.md). See also the example for a docker-registry with NGNIX [here](https://kubernetes.github.io/ingress-nginx/examples/docker-registry/).

## Deploy

After you have provided the Longhorn volume and setup the Ignress security you can now deploy the registry with the following command:

	$ kubectl apply -f management/registry

Corresponding to your ingress configuration you can test the registry Rest API from your browser

	https://{YOUR-DOMAIN-NAME}/v2/_catalog


