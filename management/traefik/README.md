# Traefik.io

[traefik.io](http://traefik.io) is a reverse proxy and load balancer to be used within a kubernetes cluster. 

To deploy traefik.io within the imixs-cloud first edit the files 

 - management/traefik/002-deployment.yaml
 - management/traefik/003-ingress.yaml
 
and replace {YOUR-E-MAIL} with a valid email address and {MASTER-NODE-IP} with the ip address of your master node.

Next run:

	$ kubectl apply -f management/traefik/
	
to undeploy traefik.io run:

	$ kubectl delete -f management/traefik/

For further information reed the documentation section [Ingress Configuration with Traefik.io](../../INGRESS.md)

