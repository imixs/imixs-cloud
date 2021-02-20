# How to secure Imixs-Cloud

The following section describes additional security concepts of *Imixs-Cloud*

* [Iptables](#iptables)  
* [NGNX Authentication](#ngnx-authentication)


## Iptables

iptables are the core firewall service build into the Linux kernel. It will monitor traffic from and to your server using tables. These tables can provide various sets of rules, called chains, that will filter incoming and outgoing data packets.

After installing a worker or master node kubernetes already have activated some iptable rules. You can verify the configuration with:

	$ sudo iptables -L 
	Chain INPUT (policy ACCEPT)
	target     prot opt source               destination         
	KUBE-EXTERNAL-SERVICES  all  --  anywhere             anywhere             ctstate NEW /* kubernetes externally-visible service portals */
	KUBE-FIREWALL  all  --  anywhere             anywhere            
	
	Chain FORWARD (policy ACCEPT)
	target     prot opt source               destination         
	KUBE-FORWARD  all  --  anywhere             anywhere             /* kubernetes forwarding rules */
	KUBE-SERVICES  all  --  anywhere             anywhere             ctstate NEW /* kubernetes service portals */
	KUBE-EXTERNAL-SERVICES  all  --  anywhere             anywhere             ctstate NEW /* kubernetes externally-visible service portals */
	
	Chain OUTPUT (policy ACCEPT)
	target     prot opt source               destination         
	KUBE-SERVICES  all  --  anywhere             anywhere             ctstate NEW /* kubernetes service portals */
	KUBE-FIREWALL  all  --  anywhere             anywhere            
	
	Chain KUBE-FIREWALL (2 references)
	target     prot opt source               destination         
	DROP       all  --  anywhere             anywhere             mark match 0x8000/0x8000 /* kubernetes firewall for dropping marked packets */
	DROP       all  -- !127.0.0.0/8          127.0.0.0/8          ! ctstate RELATED,ESTABLISHED,DNAT /* block incoming localnet connections */
	
	Chain KUBE-KUBELET-CANARY (0 references)
	target     prot opt source               destination         
	
	Chain KUBE-PROXY-CANARY (0 references)
	target     prot opt source               destination         
	
	Chain KUBE-EXTERNAL-SERVICES (2 references)
	target     prot opt source               destination         
	
	Chain KUBE-SERVICES (2 references)
	target     prot opt source               destination         
	
	Chain KUBE-FORWARD (1 references)
	target     prot opt source               destination         
	DROP       all  --  anywhere             anywhere             ctstate INVALID
	ACCEPT     all  --  anywhere             anywhere             /* kubernetes forwarding rules */ mark match 0x4000/0x4000
	ACCEPT     all  --  anywhere             anywhere             /* kubernetes forwarding conntrack pod source rule */ ctstate RELATED,ESTABLISHED
	ACCEPT     all  --  anywhere             anywhere             /* kubernetes forwarding conntrack pod destination rule */ ctstate RELATED,ESTABLISHED







## NGNX authentication

*Imixs-Cloud* is using NGNX as a reverse proxy. In this way every request from outside to one of your services must pass the [NGINX Ingress Controller](https://github.com/kubernetes/ingress-nginx). You can find details about how to setup the NGINX Ingress controller [here](INGRESS.md).

If your service does not have its own authentication mechanism, you can use NGNX to authenticate incomming requests. 
The *Basic Authentication mechanism* provided by the NGINX Controller can be used to protect web sites and services:

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



