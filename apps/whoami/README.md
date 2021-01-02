# Whoami Service

The [whoami service](https://github.com/EmileVauge/whoamI) is a tiny Go webserver that responses with os information and HTTP request data.

The deployment provides a ingress pointing to a Internet domain name. Change the file '030-ingress.yaml' and replace {YOUR-DOMAIN-NAME}  with a valid DNS record

To start this service in the imixs-cloud run: 

	$ kubectl apply -f apps/whoami/

	