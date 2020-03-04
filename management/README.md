# Management

The /management/ directory holds the service configuration for the management services running on the management node only.

Each application has its own application directory holding a yml-file to deploy the application.

	$ kubectl apply -f imixs-cloud/management/APPLICATION/DEPLOYMENT.yaml

See the section [How to setup Imixs-Docker-Cloud](SETUP.md) for general setup information.


To delete a deployed application run the delete command:

	$ kubectl delete -f imixs-cloud/management/APPLICATION/DEPLOYMENT.yaml
