# Ingress Configuration with Traefik.io

In general services running in a kubernetes cluster are not visible from outside your cluster or the Internet. To gain access to a service running inside your cluster from the Internet, you need a so called [Ingress Network](https://kubernetes.io/docs/concepts/services-networking/ingress/).   

_Imixs-Cloud_  provides you with a ready to use Ingress Configuration based on [Traefik.io](http://traefik.io) in combination with the ACME provider [Let's Encrypt](https://letsencrypt.org/). This makes it easy to publish services to the Internet in a secure way. 

The following section describe the setup of the Traefik.io configuration for  _Imixs-Cloud_ .Traefik.io provides a lot of features to route traefik from outside into a specific services running within your Kubernetes cluster. You will find detailed information how to configure traefik.io in the [official documentation](https://docs.traefik.io/)

		

## Configuration

The traefik setup of  _Imixs-Cloud_  consists of a set of resource yaml files which can be customized and extended.

 - 001-rbac.yaml - defines the roles needed by Traefik.io
 - 002-deployment.yaml - defines the Traefik.io deployment object including the Let's Encrypt configuration
 - 003-services.yaml - defines the services for http/https and the dashboard
 - 004-middleware.yaml - optional definition of middlewares (e.g. HTTPS Redirect)
 - 005-ingress.yml - optional definition for a ingress to the dashboard

### 1. The Deployment Configuration

The file _002-deployment.yaml_ contains the deployment configuration for Traefik.io and also the ACME provider [Let's Encrypt](https://letsencrypt.org/).  Before your apply the Traefik.io configuration to your cluster, first edit this file and replace the place holder _{YOUR-E-MAIL}_ with the e-mail address of your organization.

For testing the ACME provider  runs on a staging server. You can comment the ACM Staging server from the Let's Encrypt setup section after you have tested your cluster setup. The staging setup is just simulating certificates but not creating one. 

        # comment staging server for production
        - --certificatesresolvers.default.acme.caserver=https://acme-staging-v02.api.letsencrypt.org/directory
        - --certificatesresolvers.default.acme.email={YOUR-E-MAIL}


### 2. The Service Configuration  

The file _003-service.yaml_ contains the service configuration for the Taefik.io service.  
The spec defines a external IP address which is used to route external requests to one cluster node. Traffic that ingresses into the cluster with the external IP (as destination IP), on the Service port, will be routed to one of the Service endpoints. External IPs are not managed by Kubernetes and are the responsibility of the cluster administrator. Find more details [here](https://kubernetes.io/docs/concepts/services-networking/service/#external-ips).

So before you apply the traefik configuration replace the _{MASTER-NODE-IP}_ with the Node IP address of one of your kubernetes cluster nodes used to ingress external traefik. This should typically be the IP address from your master node.
 
	spec:
	  externalIPs:
	  - {MASTER-NODE-IP} 
	  
### 4. The Middleware Configuration

The file _004-middleware.yam_ contains optional middleware configurations. This can be used to secure services (e.g. the Traefik Web Dashboard) with a basic authentication. Read the section [Security](SECURITY.md) for more information.


### 5. The Ingress Configuration

In the 'insecure' mode you can open the Traefik.io Web Dashboard from your master node on Port 8100.

After testing you should disable the insecure mode and configure a Ingress Network as explained in the  [Security](SECURITY.md) section. The file _005-ingress.yaml_ proovides you with a template. 

	  
### 4. Apply Your Configuration
	  
After you have configured the resource yaml files you can apply your changes to the kubernetes cluster:

	$ kubectl apply -f management/traefik/


You can access the Traefik.io dashboard either in the insecure mode or a Ingress configuration:

	http://{MASTER-NODE-IP}:8100
	http://{YOUR-TRAEFIK-HOST-NAME} 



## Ingress 

Now as you have deployed Traefik.io into your cluster you can define your own Ingress within  your POD to gain access from the Internet.
The following example shows a simple Ingress configuration 


	kind: Ingress
	apiVersion: networking.k8s.io/v1beta1
	metadata:
	  name: myingress
	  annotations:
	    traefik.ingress.kubernetes.io/router.entrypoints: web, websecure
	spec:
	  rules:
	  - host: example.foo.com
	    http:
	      paths:
	      - path: /
	        backend:
	          serviceName: whoami
	          servicePort: 80

With the annotation "traefik.ingress.kubernetes.io/router.entrypoints" you define that your service  should be routed by traefik. 
HTTP requests will be automatically forwarded to HTTPS due to the Let's Encrypt configuration. 

To test your traefik setup you can deploy the 'whoami' service which is part of the _/apps/_ .
Edit the file /apps/whoami/003-ingress.yaml and apply your configuration:

	$ kubectl apply -f whoami/

You can control your ingress configuration from the Traefik.io web ui:

<img src="images/traefik-ui-ingress.png" />



## Middleware

With the concept of [middlewares](https://docs.traefik.io/routing/routers/#middlewares) you can refine the routing of a ingress rule. 
For example you can add a basic authentication to secure your service. 

<img src="images/traefik-ui-middleware.png" />


### Adding Basic Authentication

The [Middleware BasicAuth](https://docs.traefik.io/middlewares/basicauth/) is a quick way to restrict access to your services to known users. 
The middleware can be configured with a list of user/password pairs. 


#### 1. Generate a password file

First generate a password file on your master node with your user:password pairs. You can use the commadline tool 'htpasswd' which is part of the apache2-utils.
The following command will add a new user:password pair to a local stored password file named '.kubepasswd'

	$ htpasswd -nb admin adminadmin >> .kubepasswd
	$ htpasswd -nb user password >> .kubepasswd

In kubernetes a user:password string must be base64-encoded. To create an encoded user:password pairs from your password file run the following command:


	$ cat .kubepasswd | openssl base64
	YWRtaW46JGFwcjEkWXdmLkF6Um0kc3owTkpQMi55cy56V2svek43aENtLwoKdXNl
	cjokYXByMSRaU2VKQW1pOSRVV1AvcDdsQy9KSzdrbXBIMXdGL28uCgo=

The output is needed for the traefik middleware configuration.

#### 2. Define a Traefik Middleware

The following middleware definition creates a basic authentication layer in the file admin-auth.yaml:

	apiVersion: traefik.containo.us/v1alpha1
	kind: Middleware
	metadata:
	  name: basic-auth
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

Below the section data.users paste your own encoded user password file content.  
  
Apply your new basicAuth middleware with:

	$ kubectl apply -f admin-auth.yaml



#### 3. Secure a Service with Basic Authentication

To apply the baicAuth middleware you just need to add the annotation in your ingress objects:


	kind: Ingress
	apiVersion: networking.k8s.io/v1beta1
	metadata:
	  name: myingress
	  annotations:
	    traefik.ingress.kubernetes.io/router.entrypoints: web
	    traefik.ingress.kubernetes.io/router.middlewares: default-basic-auth@kubernetescrd
    ....


**Note:** the name of the middelware need to be praefixed with 'default-' and suffixed with '@kubernetescrd' 





## IngressRoute

IngresRoute is a specific object defined by traefik. In general you can use kubernetes ingress objects as explained in the section above. But of course you can use also the traefik specific IngressRoute object to define an Ingress if needed. Within the general traefik setup we activated both - the kubernetes-crd provider and the kuberntes-ingress provider.

You can find more about traefik ingressRoute objects [here](https://docs.traefik.io/providers/kubernetes-crd/) 

See the following example defining a traefik Ingres Route for a service:


	# IngresRoute http
	---
	kind: IngressRoute
	apiVersion: traefik.containo.us/v1alpha1
	metadata:
	  name: whoami-notls
	  namespace: default
	
	spec:
	  entryPoints: 
	    - web
	  routes:
	  - match: Host(`example.foo.com`) 
	    kind: Rule
	    services:
	    - name: whoami
	      port: 80
	    # add basic auth
	    #middlewares: 
	    #- name: basic-auth
    
    
