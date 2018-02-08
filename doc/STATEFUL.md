
# Stateful Services

This section gives an overview how to run stateful services within the cloud. 


## Using placement constraints

https://www.sweharris.org/post/2017-07-30-docker-placement/

Docker Swarm will automatically try and place containers to provide maximum resiliency within the service. So, for example, if you request 3 running copies of a container Docker Swarm will try and place these on three different machines. Only if resources are unavailable multiple container instances will be placed on the same host.

The current placement of containers for a specific service can be checked with:

	docker service ps my_app

Sometimes, however, you need to control where a container will run. This may be for example if only some nodes having the necessary resources. The most common case are "volume" dependencies for stateful services. 
This means if Docker Swarm starts a container on one or multiple nodes, the backend resources, such as file system volumes, are served locally from each node.

This means that in case of a named volume each node would use its own unique local file system volume.


### Constraints by Hostname
One soulution is to add a constraint to a service to allow a deployment only on one specific host. See the following example:

	db:
	    image: mysql:5.5
	    volumes:
	      - db-data:/var/lib/mysql
	    deploy:
	      placement:
	        constraints: [node.hostname == db1.my-cloud.local]

This will ensure that the MySQL service is only deployed on the host 'db1.my-cloud.local'. This solution works, but it is also limited to just a single host. 


### Constraints by Label

Instead of defining a constraint to a specific single node you can define a label and constrain it to:


	 tomcat:
	    image: imixs/wildfly
	    deploy:
	      replicas: 2
	      placement:
	        constraints: [node.labels.appserver == true ]

	        
To run this service on specific nodes you now need to add the labels to your nodes, to tell Docker Swarm these nodes are suitable:

	$ docker node update --label-add appserver=true appnode1.my-cloud.local

	$ docker node inspect --format '{{ .Spec.Labels }}' appnode1.my-cloud.local


