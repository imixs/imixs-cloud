# Longhorn

## Ingress Configuration

To run the Longhorn-UI frontend via an Ingress on NGINX, it is necessary to replace the hostname in the file 030-ingress.yaml.
Replace {YOUR-DOMAIN-NAME} with your own Internet name:

	kind: Ingress
	apiVersion: networking.k8s.io/v1
	metadata:
	  name: longhorn-frontend
	  namespace: longhorn-system
	  annotations:
	    cert-manager.io/cluster-issuer: "letsencrypt-staging"
	spec:
	  tls:
	  - hosts:
	    - {YOUR-DOMAIN-NAME}
	    secretName: tls-longhorn-frontend
	  rules:
	  - host: {YOUR-DOMAIN-NAME}
	    http:
	      paths:
	      - path: /
	        pathType: Prefix
	        backend:
	          service:
	            name: longhorn-frontend
	            port:
	              number: 80

## Deploy

To deploy the longhorn system run:

	$ kubectl apply -f management/longhorn

The deployment may take some minutes. Corresponding to your ingress configuration you can open the Longhorn Web UI to administrate your cluster.


## Authentication

Authentication is not enabled by default. This means anonymous can access the longhorn UI form Internet. To protect you UI follow these steps:

**1. Create a basic auth file**

Using openssl you can create a auth file for basic authentication on your master node.

It’s important the file generated is named 'auth' (actually - that the secret has a key data.auth), otherwise the ingress-controller returns a 503.

	$ USER=<USERNAME_HERE>; PASSWORD=<PASSWORD_HERE>; echo "${USER}:$(openssl passwd -stdin -apr1 <<< ${PASSWORD})" >> auth

**2. Create a secret:**

Next you can create a secet in the longhonr-system namespace named 'basic-auth'

	$ kubectl -n longhorn-system create secret generic basic-auth --from-file=auth


**3. Update the NGINX Ingress**

Now you can update the Ingress manifest longhorn-ingress.yml :

	kind: Ingress
	apiVersion: networking.k8s.io/v1
	metadata:
	  name: longhorn-frontend
	  namespace: longhorn-system
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
	    secretName: tls-longhorn-frontend
	  rules:
	  - host: {YOUR-DOMAIN-NAME}
	    http:
	      paths:
	      - path: /
	        pathType: Prefix
	        backend:
	          service:
	            name: longhorn-frontend
	            port:
	              number: 80

Finally apply you changes

	$ kubectl apply -f management/longhorn/030-ingress.yaml

Further information can be found [here](https://longhorn.io/docs/1.0.0/deploy/accessing-the-ui/longhorn-ingress/)



## open-iscsi
	
Longhorn is based on open-iscsi. So it is necessary to ensure that 'open-iscsi' has been installed on all the nodes of the Kubernetes cluster, and the _iscsid_ daemon is running on all the nodes. 'open-iscsi' is allready part of the Imixs-Cloud setup scripts, so there is no need for extra configuraiton.

If you need to install it anyway you can use the following command to install open-iscsi in debian systems: 

	$ sudo apt-get install open-iscsi

	
	