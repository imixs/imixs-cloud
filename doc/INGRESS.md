# Ingress Configuration with Traefik.io

Imixs-Cloud provides a Ingress Configuration based on [Traefik.io](http://traefik.io).
Traefik.io is a reverse proxy and load balancer to be used within a kubernetes cluster. Traefik provides Custom Resource Definitions (CRD) for routing HTTP/HTTPS requests from outside of your cluster to particular services. 

To deploy traefik.io within the imixs-cloud run:

	$ kubectl apply -f management/traefik/
	
to undeploy traefik.io run:

	$ kubectl delete -f management/traefik/



## Configuration

The traefik setup consists of three resource yaml files.

### Deployment Configuration

The 002-deployment.yaml file contains the deployment configuration for Traefik.io. This also includes Let's Encrypt setup. 

Before your apply the traefik configuration please replace the place holder _{YOUR-E-MAIL}_ with the e-mail address of your organisation.

Also comment the ACM Staging server from the Let's Encrypt setup after you have tested your cluster setup. 

        # comment staging server for production
        - --certificatesresolvers.default.acme.caserver=https://acme-staging-v02.api.letsencrypt.org/directory
        - --certificatesresolvers.default.acme.email={YOUR-E-MAIL}


### Ingress Configuration  

The 003-ingressroute.yaml file contains the ingress configuration for the Taefik.io service.  
The spec defines a external IP address which is used to route external requests to one cluster node. Traffic that ingresses into the cluster with the external IP (as destination IP), on the Service port, will be routed to one of the Service endpoints. externalIPs are not managed by Kubernetes and are the responsibility of the cluster administrator. Find more details [here](https://kubernetes.io/docs/concepts/services-networking/service/#external-ips).

So before you apply the traefik configuration please replace the _{MASTER-NODE-IP}_ with the Node IP address of one of your kubernetes cluster nodes used to ingress external traefik. This should typically be the IP address from your master node.
 
	spec:
	  externalIPs:
	  - {MASTER-NODE-IP} 
	  
	  
### Apply Configuration
	  
After you have configured the resource yaml files you can apply your changes to the kubernetes cluster:

	$ kubectl apply -f management/traefik/



## Middleware

With the concept of [middlewares](https://docs.traefik.io/routing/routers/#middlewares) you can refine the routing of a ingress rule. 
For example you can redirect a HTTP request to HTTPS or your can add a basic authentication to secure your service. 


### Adding Basic Authentication

The [BasicAuth middleware](https://docs.traefik.io/middlewares/basicauth/) is a quick way to restrict access to your services to known users. 
The middleware can be configured with a list of user/password pairs. 


#### 1. Generate a password file

First generate a password file with your user:password pairs. You can use the commadline tool 'htpasswd' which is part of the apache2-utils.
The following command will add a new user:password pair to a local stored password file named '.kubepasswd'

	$ htpasswd -nb admin adminadmin >> .kubepasswd
	$ htpasswd -nb user password >> .kubepasswd

In kubernetes a user:password string must be base64-encoded. To create an encoded user:password pairs from your password file run the following command:


	$ cat .kubepasswd | openssl base64
	YWRtaW46JGFwcjEkWXdmLkF6Um0kc3owTkpQMi55cy56V2svek43aENtLwoKdXNl
	cjokYXByMSRaU2VKQW1pOSRVV1AvcDdsQy9KSzdrbXBIMXdGL28uCgo=

The output can be used in the traefik middleware configuration.

#### 2. Define a Traefik Middleware

The following middleware definition creates a basic authentication layer in the file admin-auth.yaml:

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

	$ kubectl apply -f admin-auth.yaml



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





### HTTP to HTTPS Redirectscheme

The [Middleware RedirectScheme](https://docs.traefik.io/middlewares/redirectscheme/)  is used for a redirection from HTTP to HTTPS:


	# Redirect http -> https
	---
	apiVersion: traefik.containo.us/v1alpha1
	kind: Middleware
	metadata:
	  name: https-redirect
	spec:
	  redirectScheme:
	    scheme: https

To apply the HTTP->HTTPS Redirectscheme you just need to add the redirect to the routes definition of your ingressRoute:

	...
	  routes:
	  - kind: Rule
	    match: Host(`{YOUR-INTERNET-DNS-NAME}`)
	    services:
	    - name: your-service
	      port: 80
	    # apply auto redirect
	    middlewares: 
	    - name: https-redirect
    ....
    

### Middleware Chains

The [Middlware Chain](https://docs.traefik.io/middlewares/chain/) enables you to define reusable combinations of middleware.
So for example you can define a Chain Middleware to secure your service and to redirect HTTP->HTTPS. See the following example:

	# Secure and Redirect...
	---
	apiVersion: traefik.containo.us/v1alpha1
	kind: Middleware
	metadata:
	  name: secured
	spec:
	  chain:
	    middlewares:
	    - name: admin-auth
	    - name: https-redirect


If you set this middleware in your ingress definition, your service will be secured and redirected form HTTP to HTTPS.


