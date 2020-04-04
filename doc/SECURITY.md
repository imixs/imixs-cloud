# How to secure Imixs-Cloud

The following section describes additional security concepts of Imixs-Cloud

See also [here](https://docs.traefik.io/middlewares/basicauth/).




## Traefik: Setup Basic Authentication 

You can secure any service routed through the traefik LoadBalancer by defining a middlware for basic authentication. 
Take a look into the [ingress](INGRESS.md) section of how to setup the middleware 'basic-auth'.


## Traefik: Dashboard

The traefik web front-end in its default configuration provides the dashboard in the 'insecure' mode. This means that no authentication is needed to access the dashboard.

To secure the dashboard you can apply a internet host and an IngresRoute for accessing the dashboard, through Traefik itself.

#### 1. Disable the inscure mode

In the file managmeent/traefik/002-deployment.yaml you need to set the api option  _'api.insecure'_  to  _'false'_

    ...
    spec:
      containers:
      - args:
        - --api.insecure=false
        - --api.dashboard=true
     ....

#### 2. Create a IngressRoute

Next create a ingress route to access the trafik dashboard throgh your Internet host name and with a middleware for basic authentication:

	apiVersion: traefik.containo.us/v1alpha1
	kind: IngressRoute
	metadata:
	  name: traefik-dashboard
	spec:
	  routes:
	  - match: Host(`{YOUR-HOST-NAME}`)
	    kind: Rule
	    services:
	    - name: api@internal
	      kind: TraefikService
	    middlewares:
	      - name: https-redirect
	
	
	# IngresRoute https
	---
	kind: IngressRoute
	apiVersion: traefik.containo.us/v1alpha1
	metadata:
	  name: traefik-dashboard-tls
	spec:
	  routes:
	  - match: Host(`{YOUR-HOST-NAME}`) 
	    kind: Rule
	    services:
	    - name: api@internal
	      kind: TraefikService
	    middlewares: 
	    - name: basic-auth
	  tls:
	    certResolver: default


Take a look into the [ingress](INGRESS.md) section of how to setup the middleware 'basic-auth'.
