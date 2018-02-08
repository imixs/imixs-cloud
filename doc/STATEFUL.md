
# Stateful Services

This section gives an overview how to run stateful services within the cloud. 


## Using placement constraints

Docker Swarm automatically tries and place containers with a maximum of resiliency within the swarm. So, for example, if you request 3 instances of the same container, Docker Swarm will try and place these on three different machines. Only if resources are unavailable multiple container instances will be placed on the same host. The current placement of containers for a specific service can be checked with:

	docker service ps my_app

Sometimes, however, you need to control where a container will run. This may be for example if only some nodes in your infrastructure providing the necessary resources. The most common case for this requirement are "volume" dependencies of stateful services. Each time Docker Swarm starts a container on one or multiple nodes, the backend resources, such as file system volumes, are served locally from each node. This means that in case for named volumes, each node would use its own unique file system to provide a data volume locally. This also applies to the failover case for a single container. If Docker Swarm restarts a container on a new node, the data volume will be newly created.

For example, if you run a MySQL database service with a data volume, you want usually prevent this Service from being moved from one node to another node by Docker Swarm. The aforementioned resiliency must be restricted here in order to guarantee the data consistency.

To solve this problem, so called 'placement constraints' can be used to tell Docker Swarm to run certain services only on specific nodes within your infrastructure.

### Constraints by Hostname
One solution to run a service on a specific node is to add a placement constraint to a service which tells Docker Swarm to deploy this service only on one specific host. See the following example:

	db:
	    image: mysql:5.5
	    volumes:
	      - db-data:/var/lib/mysql
	    deploy:
	      placement:
	        constraints: [node.hostname == db1.my-cloud.local]

This will ensure that the MySQL service is only deployed on the host 'db1.my-cloud.local'. This solution works for most cases, but it is also limited to just a single node. 


### Constraints by Label
Another solution to run a service only on specific nodes is to define a  placement constraint by a label. 
Instead of defining a constraint to a specific single node you can define also labels and constrain a service to it:


	 tomcat:
	    image: imixs/wildfly
	    deploy:
	      replicas: 2
	      placement:
	        constraints: [node.labels.appserver == true ]

In this example the service will be placed on nodes with the label 'appserver=true'.

To run this service on specific nodes you first need to add the labels to your nodes, to tell Docker Swarm these nodes are suitable:

	$ docker node update --label-add appserver=true appnode1.my-cloud.local

	$ docker node inspect --format '{{ .Spec.Labels }}' appnode1.my-cloud.local

When you restart the service Docker Swarm will look for a node with the matching label. 
