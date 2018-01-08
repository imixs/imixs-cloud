# Whoami Service

The [whoami service](https://github.com/EmileVauge/whoamI) is a tiny Go webserver that responses with os information and HTTP request data.

The docker-compose.yml file can be used to start this service in the imixs-cloud. 

**Note:** change the label 'traefik.frontend.rule=Host' to a valid DNS name.

To start the service run:

	docker stack deploy -c apps/whoami/docker-compose.yml whoami