# How to secure Imixs-Cloud

The following section describes additional security concepts of Imixs-Cloud

See also [here](https://docs.traefik.io/middlewares/basicauth/).




## Traefik: Setup Basic Authentication 

The traefik web front-end (8080) is accessible to anonymous per default. To secure the front-end follow these steps:

#### 1. Generate a password file

To generate a password file you can use the commadline tool 'htpasswd' which is part of the apache2-utils.
The following command will add a new user:password pair to a local stored password file named 'kubepasswd'

	$ htpasswd -nb admin adminadmin >> .kubepasswd
	$ htpasswd -nb user password >> .kubepasswd

In kubernetes a user:password stringd must be base64-encoded. To create an encoded user:password pairs now run the following command:


	$ cat .kubepasswd | openssl base64
	YWRtaW46JGFwcjEkWXdmLkF6Um0kc3owTkpQMi55cy56V2svek43aENtLwoKdXNl
	cjokYXByMSRaU2VKQW1pOSRVV1AvcDdsQy9KSzdrbXBIMXdGL28uCgo=

The output can be used in the traefik middleware confiugration.

#### 2. Define a Traefik Middleware

The following traefik middleware configuration defines a basic authentication layer to be used for ingress definitions:

	apiVersion: traefik.containo.us/v1alpha1
	kind: Middleware
	metadata:
	  name: admin-auth
	spec:
	  basicAuth:
	    secret: authsecret
	
	---
	apiVersion: v1
	kind: Secret
	metadata:
	  name: authsecret
	  namespace: default
	
	data:
	  users: |2
	    YWRtaW46JGFwcjEkWXdmLkF6Um0kc3owTkpQMi55cy56V2svek43aENtLwoKdXNl
	    cjokYXByMSRaU2VKQW1pOSRVV1AvcDdsQy9KSzdrbXBIMXdGL28uCgo=
  
  
Apply your new basicAuth middleware with:

	$ kubectl apply -f basicauth.yaml





#### 3. Secure a Service with Basic Authentication

Now you can use the baicAuth middleware in your own ingress definition. See the following example:

	# IngresRoute http with basicAuth
	---
	kind: IngressRoute
	apiVersion: traefik.containo.us/v1alpha1
	metadata:
	  name: my-service
	  namespace: default
	
	spec:
	  entryPoints: 
	    - web
	  routes:
	  - match: Host(`myservice.foo.com`) 
	    kind: Rule
	    services:
	    - name: my-service
	      port: 80
	    middlewares: 
	    - name: admin-auth




