# NGINX Ingress Controller

The [NGINX Ingress Controller](https://github.com/kubernetes/ingress-nginx)  is an Ingress controller for Kubernetes using NGINX as a reverse proxy and load balancer.
The NGINX Ingress Controller is maintained by the Kubernetes community.


## Deployment

The deployment is based on kustzomize. In this way you can control and customize the deployment in an easy way. The deployment is based on the official cloud provider configuration maintained on Github. The origin deployment template can be found [here](https://raw.githubusercontent.com/kubernetes/ingress-nginx/controller-v0.43.0/deploy/static/provider/cloud/deploy.yaml)

To deploy, first edit the file *020-service.yaml* and replace {YOUR_CLUSTER_IP} with the ip address of your master node

Next you can start the deployment using kustomize:

	$ kubectl apply --kustomize  management/nginx
	
The deployment may take some seconds. You can verify the deployment process with: 	
		
	$ kubectl wait --namespace ingress-nginx \
	  --for=condition=ready pod \
	  --selector=app.kubernetes.io/component=controller \
	  --timeout=120s
	  
	...
	pod/ingress-nginx-controller-56c75d774d-rm27c condition met

The deployment configuration contains already a setup for TLS certificates issued by Let’s Encrypt. So there is no further configuration needed to use Let’s Encrypt. See the next section for more details.


	



# Let's Encrypt

https://www.digitalocean.com/community/tutorials/how-to-set-up-an-nginx-ingress-with-cert-manager-on-digitalocean-kubernetes



## 1. Install  cert-manager

	$ kubectl apply -f https://github.com/jetstack/cert-manager/releases/download/v1.1.0/cert-manager.yaml

Verify installation with:

	$ kubectl get pods --namespace cert-manager




### Staging Certificates

To issue a staging TLS certificate for your domains, we’ll annotate echo_ingress.yaml with the ClusterIssuer created in Step 4. This will use ingress-shim to automatically create and issue certificates for the domains specified in the Ingress manifest.

Open up echo_ingress.yaml in your favorite editor:






### Production Certificates
 
 
 
 
## Ingress

Now you can issue a TLS certificate for your domains. You can use the Let's Encrypt ClusterIssuer either in the staging or in the production mode.
In a Ingress manifest just add the annotation for the corresponding cluster-issue and also add a 'tls' configuration. See the following example for the whoami service:

	kind: Ingress
	apiVersion: networking.k8s.io/v1
	metadata:
	  name: myingress
	  annotations:
	    cert-manager.io/cluster-issuer: "letsencrypt-staging"
	spec:
	  tls:
	  - hosts:
	    - whoami.foo.com
	    secretName: echo-tls
	  rules:
	  - host: whoami.foo.com
	    http:
	      paths:
	      - path: /
	        pathType: Prefix
	        backend:
	          service:
	            name: whoami
	            port:
	              number: 80


To apply the update of the ingress configuration run:

    $ kubectl apply -f apps/whoami/030-ingress.yaml




## Testing




Open up echo_ingress.yaml in your favorite editor:

You can track the state of the Ingress:

    kubectl describe ingress

Once the certificate has been successfully created, you can run a describe for further information:

    $ kubectl describe certificate
	Events:
	  Type    Reason     Age    From          Message
	  ----    ------     ----   ----          -------
	  Normal  Requested  64s    cert-manager  Created new CertificateRequest resource "echo-tls-vscfw"
	  Normal  Issuing    40s    cert-manager  The certificate has been successfully issued



	
# More info:


https://www.linuxtechi.com/setup-nginx-ingress-controller-in-kubernetes/

https://blog.dbi-services.com/setup-an-nginx-ingress-controller-on-kubernetes/