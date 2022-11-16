# NGINX Ingress Controller

The [NGINX Ingress Controller](https://github.com/kubernetes/ingress-nginx)  is an Ingress controller for Kubernetes using NGINX as a reverse proxy and load balancer.
The NGINX Ingress Controller is maintained by the Kubernetes community.


## Deployment cert-manager

The deployment configuration in *Imixs-Cloud* contains already a setup for TLS certificates issued by Let’s Encrypt. So there is no further configuration needed to use Let’s Encrypt. To support certificates the [cert-manager](https://cert-manager.io) is needed. This service can be deployed from the cert-manager repo on Github:

	$ kubectl apply -f https://github.com/cert-manager/cert-manager/releases/download/v1.10.0/cert-manager.yaml

Verify the installation of the cert-manager with:

	$ kubectl get pods --namespace cert-manager
	NAME                                      READY   STATUS    RESTARTS   AGE
	cert-manager-5597cff495-z454k             1/1     Running   0          6h23m
	cert-manager-cainjector-bd5f9c764-vxlbf   1/1     Running   0          6h23m
	cert-manager-webhook-5f57f59fbc-cpgp2     1/1     Running   0          6h23m


## Deployment NGINX

The deployment of the NGINX Ingress Controller is based on kustzomize. In this way you can control and customize the deployment in an easy way. The deployment is based on the official cloud provider configuration maintained on Github. The origin deployment template can be found [here](https://raw.githubusercontent.com/kubernetes/ingress-nginx/controller-v0.43.0/deploy/static/provider/cloud/deploy.yaml)

Before you deploy just edit the file *020-service.yaml* and replace {YOUR_CLUSTER_IP} with the ip address of your master node

In the file *030-cluster-issuer.yaml* replace the email address with a valid address from your organization. This email address will become the issuer for the  Let’s Encrypt certificates.



Next you can start the deployment using kustomize:

	$ kubectl apply --kustomize  management/nginx
	
The deployment may take some seconds. You can verify the deployment process with: 	
		
	$ kubectl wait --namespace ingress-nginx \
	  --for=condition=ready pod \
	  --selector=app.kubernetes.io/component=controller \
	  --timeout=120s
	  
	...
	pod/ingress-nginx-controller-56c75d774d-rm27c condition met



# Let's Encrypt

The Let's Encrypt integration is configured in the file 030-cluster-issuer.yaml. This file defines separate configuration for staging and production

The Let’s Encrypt staging server has no rate-limits for requests made against it, so for testing purposes you should use the staging configuration. If everything works fine you can change to the production cluster-issuer.
 
 
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


You can track the state of the Ingress with a describe:

    $ kubectl describe ingress


## Certificates

The cert-manager has the concept of Certificates that define a desired x509 certificate which will be renewed and kept up to date. 

The certificates are stored in the corresponding secret defined in the ingress definition. You can describe the secret for further information:

	$ kubectl describe secret tls-whoami
	Name:         tls-whoami
	Namespace:    default
	Labels:       <none>
	Annotations:  cert-manager.io/alt-names: whoami.ixbunic.imixs.com
	              cert-manager.io/certificate-name: tls-whoami
	              cert-manager.io/common-name: whoami.ixbunic.imixs.com
	              cert-manager.io/ip-sans: 
	              cert-manager.io/issuer-group: cert-manager.io
	              cert-manager.io/issuer-kind: ClusterIssuer
	              cert-manager.io/issuer-name: letsencrypt-staging
	              cert-manager.io/uri-sans: 
	
	Type:  kubernetes.io/tls
	
	Data
	====
	tls.crt:  3570 bytes
	tls.key:  1679 bytes
	

Once a certificate has been successfully created, you can run a describe for further information:

	$ kubectl describe certificate tls-whoami
	.....
	.......
	Events:
	  Type    Reason     Age    From          Message
	  ----    ------     ----   ----          -------
	  Normal  Issuing    5m19s  cert-manager  Issuing certificate as Secret does not exist
	  Normal  Generated  5m19s  cert-manager  Stored new private key in temporary Secret resource "tls-whoami-b5x84"
	  Normal  Requested  5m19s  cert-manager  Created new CertificateRequest resource "tls-whoami-hxdmz"
	  Normal  Issuing    5m17s  cert-manager  The certificate has been successfully issued


Find more information about the cert-manager [here](https://cert-manager.io/docs/concepts/certificate/). 




# Upgrade the Cert Manager

It is recommend upgrading the cert-manager one minor version at a time, always choosing the latest patch version for the minor version. Find a detailed description [here](https://cert-manager.io/docs/installation/upgrading/).

## Backup

To backup all of your cert-manager configuration resources, run:

	$ kubectl get --all-namespaces -oyaml issuer,clusterissuer,cert > cert-manager-backup.yaml

Find more details [here](https://cert-manager.io/docs/tutorials/backup/).


## Upgrade

The cert-manager can be upgraded in a similar way to how you first installed them.

To begin the upgrade process run:

	$ kubectl apply -f https://github.com/cert-manager/cert-manager/releases/download/<version>/cert-manager.yaml

Replace <version> with the version number you want to install:

Once you have deployed the new version of cert-manager, you can verify the installation by checking the cert-manager namespace for running pods:

	$ kubectl get pods --namespace cert-manager




	
# More info:

https://www.digitalocean.com/community/tutorials/how-to-set-up-an-nginx-ingress-with-cert-manager-on-digitalocean-kubernetes

https://www.linuxtechi.com/setup-nginx-ingress-controller-in-kubernetes/

https://blog.dbi-services.com/setup-an-nginx-ingress-controller-on-kubernetes/