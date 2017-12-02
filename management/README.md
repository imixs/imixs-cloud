# Management

The /management/ directory holds the service configuration for the management services running on the management node only.

Each application has its own application directory holding a docker-compose.yml file to start the application.

	$ docker stack deploy -c apps/MANAGEMENT-APP/docker-compose.yml MANAGEMENT-APP

See the section [How to setup Imixs-Docker-Cloud](SETUP.md) for general setup information.
