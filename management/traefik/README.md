# Traefik.io

[traefik.io](http://traefik.io) is a reverse proxy and load balancer to be used within a kubernetes cluster. 

To deploy traefik.io within the imixs-cloud run:

	$ kubectl apply -f management/traefik21/
	
to undeploy traefik.io run:

	$ kubectl delete -f management/traefik21/

For further information reed the documentation section [Ingress Configuration with Traefik.io](../../INGRESS.md)

