# Ingress Configuration with Traefik.io

Imixs-Cloud provides a Ingress Configuration based on [Traefik.io](http://traefik.io).
Traefik.io is a reverse proxy and load balancer to be used within a kubernetes cluster. Traefik provides Custom Resource Definitions (CRD) for routing HTTP/HTTPS requests from outside of your cluster to particular services. 

To deploy traefik.io within the imixs-cloud run:

	$ kubectl apply -f management/traefik21/
	
to undeploy traefik.io run:

	$ kubectl delete -f management/traefik21/



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

	$ kubectl apply -f management/traefik21/



## Adding Basic Authentication

The BasicAuth middleware is a quick way to restrict access to your services to known users. Passwords must be encoded using MD5, SHA1, or BCrypt.
You can use _htpasswd_ to generate the passwords.


See also [here](https://docs.traefik.io/middlewares/basicauth/).



## HTTP to HTTPS Redirect

For redirection from HTTP to HTTPS a router middleware is configured in the 003-ingress.yaml file:


	# Redirect http -> https
	---
	apiVersion: traefik.containo.us/v1alpha1
	kind: Middleware
	metadata:
	  name: redirect
	spec:
	  redirectScheme:
	    scheme: https

This middleware can be used to redirect a service automatically form http to https. You just need to add the redirect to the routes definition of your ingressRoute:

	...
	  routes:
	  - kind: Rule
	    match: Host(`{YOUR-INTERNET-DNS-NAME}`)
	    services:
	    - name: your-service
	      port: 80
	    # apply auto redirect
	    middlewares: 
	    - name: redirect
    ....
    


More information about redirection and redirection on domain can be found [here](https://docs.traefik.io/migration/v1-to-v2/#http-to-https-redirection-is-now-configured-on-routers).




## Find more....

Find out more about Ingress and Traefik:

 - https://docs.traefik.io
 - https://ralph.blog.imixs.com/2020/02/01/kubernetes-setup-traefik-2-1/