# Traefik.io

[traefik.io](http://traefik.io) is a reverse proxy and load balancer to be used within a kubernetes cluster. 


## Configuration

To deploy traefik.io within the imixs-cloud first edit the following files 

#### management/traefik/002-deployment.yaml

replace *{YOUR-E-MAIL}* with a valid email address 

#### management/traefik/003-service.yaml

replace *{MASTER-NODE-IP}* with the ip address of your master node.

#### management/traefik/005-ingress.yaml
 
replace *{YOUR-HOST-NAME}* with a Internet name pointing to your Master Node configured in your DNS 

## Deployment

TO deploy traefik into your Kubernetes Cluster run:

	$ kubectl apply -f management/traefik/
	
to undeploy traefik.io run:

	$ kubectl delete -f management/traefik/

For further information reed the documentation section [Ingress Configuration with Traefik.io](../../INGRESS.md)

