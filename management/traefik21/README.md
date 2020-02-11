# Traefik.io

[traefik.io](http://traefik.io) can be used as a reverse proxy for your kubernetes cluster

To deploy traefik.io within the imixs-cloud run:

	$ kubectl apply -f management/traefik21/
	
to undeploy traefik.io run:

	$ kubectl delete -f management/traefik21/


Find out more about Ingress and Traefik:

 - https://docs.traefik.io
 - https://ralph.blog.imixs.com/2020/02/01/kubernetes-setup-traefik-2-1/