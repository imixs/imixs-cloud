# Ingress Configuration with NGINX

In general services running in a kubernetes cluster are not visible from outside your cluster or the Internet. To gain access to a service running inside your cluster from the Internet, you need a so called [Ingress Network](https://kubernetes.io/docs/concepts/services-networking/ingress/).   

_Imixs-Cloud_  provides you with a ready to use Ingress Configuration based on the [NGINX Ingress Controller](https://github.com/kubernetes/ingress-nginx) 
 in combination with the ACME provider [Let's Encrypt](https://letsencrypt.org/). This makes it easy to publish services to the Internet in a secure way. 

## Quick Setup

The following is a quick setup guide to install teh NGINX Controller. You will find a detailed description about the setup [here](../management/nginx/README.md). 

**1. Edit the NGINX .yaml files**

First edit the file management/nginx/020-service.yaml and replace {YOUR_CLUSTER_IP} with the ip address of your master node. This will be the entry point for all your services.

In the file management/nginx/030-cluster-issuer.yaml replace the email address with a valid address from your organization. This email address will become the issuer for the Let’s Encrypt certificates.

**2. Deploy the cert-manager **

To support certificates from Let's Encrypt, the cert-manager is needed. This service can be deployed from the cert-manager repo on Github:

	$ kubectl apply -f https://github.com/jetstack/cert-manager/releases/download/v1.1.0/cert-manager.yaml


**3. Deploy the NGINX Controller **

Finally you can deploy the NGINX Ignress Controller:

	$ kubectl apply --kustomize  management/nginx
	
The deployment may take some seconds. 

You will find a detailed description about the setup [here](../management/nginx/README.md).
		

	

## Ingress 

Now as you have deployed the NGINX Intress controller  into your cluster you can define your own Ingress within your POD to gain access from the Internet.
The following example shows a simple Ingress configuration from the whoami sample application:

	kind: Ingress
	apiVersion: networking.k8s.io/v1
	metadata:
	  name: whoami
	  annotations:
	    cert-manager.io/cluster-issuer: "letsencrypt-staging"
	    # For production
	    #cert-manager.io/cluster-issuer: "letsencrypt-prod"
	spec:
	  tls:
	  - hosts:
	    - {YOUR-DOMAIN-NAME}
	    secretName: tls-whoami
	  rules:
	  - host: {YOUR-DOMAIN-NAME}
	    http:
	      paths:
	      - path: /
	        pathType: Prefix
	        backend:
	          service:
	            name: whoami
	            port:
	              number: 80

HTTP requests will be automatically forwarded to HTTPS and a Let's Encrypt certificate will be requested by cert-manager.

## Let's Encrypt

Let's Encrypt supports a staging and a production server for certificates.
The Let’s Encrypt staging server has no rate-limits for requests made against it, so for testing purposes you should always first use the staging configuration. If everything works fine you can change to the production cluster-issuer.

	cert-manager.io/cluster-issuer: "letsencrypt-prod"



## Authentication

The NGINX Controller also supports a Basic Authentication mechanism to protect web sites and services. 
To protect your ingress with Basic Authentication follow these steps:

**1. Create a basic auth file**

Using openssl you can create a auth file for basic authentication on your master node:

	$ USER=<USERNAME_HERE>; PASSWORD=<PASSWORD_HERE>; echo "${USER}:$(openssl passwd -stdin -apr1 <<< ${PASSWORD})" >> auth

**2. Create a secret:**

Next you can create a secet in your namespace the Ingress is defined:

	$ kubectl -n YOUR_NAMESPACE create secret generic basic-auth --from-file=auth


**3. Update the NGINX Ingress**

Now you can update the Ingress yaml file by adding the annotations for 'auth' and 'ssl'. See the following example:

	kind: Ingress
	apiVersion: networking.k8s.io/v1
	metadata:
	  name: YOUR_INGRESS
	  namespace: YOUR_NAMESPACE
	  annotations:
	    cert-manager.io/cluster-issuer: "letsencrypt-staging"
	    # type of authentication
	    nginx.ingress.kubernetes.io/auth-type: basic
	    # prevent the controller from redirecting (308) to HTTPS
	    nginx.ingress.kubernetes.io/ssl-redirect: 'false'
	    # name of the secret that contains the user/password definitions
	    nginx.ingress.kubernetes.io/auth-secret: basic-auth
	    # message to display with an appropriate context why the authentication is required
	    nginx.ingress.kubernetes.io/auth-realm: 'Authentication Required '
	spec:
	  tls:
	  - hosts:
	    - {YOUR-DOMAIN-NAME}
	    secretName: your-secret
	  rules:
	  - host: {YOUR-DOMAIN-NAME}
	    http:
	      paths:
	      - path: /
	        pathType: Prefix
	        backend:
	          service:
	            name: your-service
	            port:
	              number: 80

