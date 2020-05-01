# Monitoring

This stack provides a Prometheus and a Grafana Service for monitoring the *Imixs-Cloud*. You can find general information about Docker and Prometeus [here](https://docs.docker.com/config/thirdparty/prometheus/). 


## Configuration

Before you start edit the file 009-grafana-ingress.yaml and replace 

replace *{YOUR-HOST-NAME}* with a Internet name pointing to your Master Node configured in your DNS 


## Deployment

Next run:

	$ kubectl apply -f management/monitoring/

to undeploy traefik.io run:

	$ kubectl delete -f management/monitoring/