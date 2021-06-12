# CockroachDB

In Imixs-Cloud we run the CockroachDB as a DaemonSet which is a similar deployment setup like for [Longhorn](../../doc/LONGHORN.md).
The concept of [Node affinities](https://kubernetes.io/docs/concepts/scheduling-eviction/assign-pod-node/#node-affinity) and [Taints and Tolerations](https://kubernetes.io/docs/concepts/scheduling-eviction/taint-and-toleration/) gives you a fine grained way to define which nodes in your cluster should be part of your CockroachDB. 

You can find general information how to run CockroachDB in a Kuberentes Cluster [here](https://www.cockroachlabs.com/docs/v21.1/kubernetes-performance#running-in-a-daemonset). A basic tutorial can be found [here](https://ralph.blog.imixs.com/2021/04/22/cockroachdb-kubernetes/). 

## The Deployment

To deploy a new CockroachDB cluster follow these steps:

### Configure your DaemonSet

First you need to edit the file *020-daemoenset.yaml* so that it fits into your cluster environment. 

**1.) The --join Flag**

The flag *--join* will allow nodes to join the cluster even if they were not part of your initial setup. 
You can enter IP addresses or DNS aliases of your nodes. Specify the addresses of 3-5 initial nodes. Cockroach will automatically distribute the rest of the node addresses.

        command:
          - "/bin/bash"
          - "-ecx"
          - "exec 
             /cockroach/cockroach 
             start 
             --logtostderr 
             --certs-dir /cockroach/cockroach-certs 
             --http-addr 0.0.0.0 
             --cache 25% 
             --max-sql-memory 25% 
             --join=worker-1,worker-2,worker-3"

Replace the 'worker-1' with the host name of your nodes. The port number 26257 is the default port used for the DaemonSet. 

**2.) The nodeSelector**

Optional uncomment and edit the 'nodeSelector' section to define on which nodes cockroachDB should be deployed. You can add additional selector criteria.  

      nodeSelector:
        app: cockroachdb

Find out more details about the concept of [Node affinities](https://kubernetes.io/docs/concepts/scheduling-eviction/assign-pod-node/#node-affinity) and [Taints and Tolerations](https://kubernetes.io/docs/concepts/scheduling-eviction/taint-and-toleration/)


**3.) Resource Limits** 

You should also uncomment the he resource limits for the CPU and memory usage on each node.

        resources:
          requests:
            cpu: "2"
            memory: "2Gi"
          limits:
            cpu: "16"
            memory: "2Gi"

**4.) The Data Directory** 

Finally edit the file location for the *hostPath* datadir. Replace "/var/lib/cockroachdb" with the path where you want CockroachDB's data stored on your Kubernetes nodes.

      volumes:
      - name: datadir
        hostPath:
          path: /var/lib/cockroachdb


### The Ingress Configuration

CockroachDB provides a Web Frontent. You need to edit the file *020-ingress.yaml* before you start the deployment.
Replace *{YOUR-DOMAIN-NAME}* with the a public Internet domain name to access the Cockroach Web UI. 

		spec:
		  tls:
		  - hosts:
		    - cockroach.foo.com
		    secretName: tls-cockroachdb-ui
		  rules:
		  - host: cockroach.foo.com
		  

### Deploy the DaemonSet 

Now you can start the deployment of your Cockroach cluster. The deployment takes place in 3 steps:

 1. Deploy the nodes & approve the certificates
 2. Init the cluster
 3. Install the cockroach client
 

**1.) Deploy the Nodes & approve the certificates**

To deploy the CockroachDB nodes into your cluster run:

	$ kubectl apply -f management/cockroachdb

The cockroachDB PODs in your cluster are not yet starting. First your need to approve the certificates created during the deployment. You can check the status of the new certificates of each node with:

	$ kubectl get csr
	NAME                             AGE   SIGNERNAME                     REQUESTOR                                   CONDITION
	cockroach.node.worker-1   1s    kubernetes.io/legacy-unknown   system:serviceaccount:default:cockroachdb   Pending
	cockroach.node.worker-2   1s    kubernetes.io/legacy-unknown   system:serviceaccount:default:cockroachdb   Pending
	cockroach.node.worker-3   1s    kubernetes.io/legacy-unknown   system:serviceaccount:default:cockroachdb   Pending

To approve the certificates run:

	$ kubectl certificate approve cockroach.node.worker-1
	$ kubectl certificate approve cockroach.node.worker-2
	$ kubectl certificate approve cockroach.node.worker-3

After your have approved the certificates the coackroach PODs will start automatically. 


**2.) Init the Cluster**

Now you can initialize the cluster. For that one-time step you first need to edit the file *scripts/cluster-init-secure.yaml*. Replace the HOST_IP_ADDR  with the IP address of your first worker node (dont use the node-name here!). 

	....
        command:
          # TODO: Replace the HOST_IP_ADDR  with the first of of your worker nodes
          - "/cockroach/cockroach"
          - "init"
          - "--certs-dir=/cockroach-certs"
          - "--host=HOST_IP_ADDR"         

Next you can init the cluster with:

	$ kubectl create -f management/cockroachdb/scripts/cluster-init-secure.yaml
	
This script generates also the client certificate needed to use the Cockroach Client later. You need to approve this certificate also:

	$ kubectl certificate approve cockroach.client.root


Now after a moment you should be able to access the CockroachDB Web UI from your browser:

	https://cockroachdb.foo.com
 
You will see the login screen. But you first need to create a admin user account. For this you need to install the cockroach client.

## The Cockroach Client
 
The cockroach client provides a command line tool to administrate your cluster and to open a SQL client shell to create and edit databases and table schemas. The client can be run as a separate POD within your Kubernetes Cluster. The client installs a client certificate to access the cluster in a secure way. 

**Install the Client**

To install the client run:
 
	$ kubectl create -f management/cockroachdb/scripts/client-secure.yaml
 
This command starts the client POD. This POD uses the same client certificate *cockroach.client.root* as already created during initializing the cluster.

After the client was created, you can can ssh into the client POD

	$ kubectl exec -it -n cockroach cockroachdb-client-secure -- bash
	
and from within the client POD you can for example verify the status of your cockroach cluster:

	$ cockroach node status --certs-dir=/cockroach-certs --host=cockroachdb-public
	
	  id |     address    |  sql_address   |  build  |            started_at            |            updated_at            | locality | is_available | is_live
	-----+----------------+----------------+---------+----------------------------------+----------------------------------+----------+--------------+----------
	   1 | worker-1:26257 | worker-1:26257 | v20.2.8 | 2021-04-24 22:46:36.099951+00:00 | 2021-04-25 12:28:27.123469+00:00 |          | true         | true
	   2 | worker-2:26257 | worker-2:26257 | v20.2.8 | 2021-04-24 22:46:37.273769+00:00 | 2021-04-25 12:28:23.885033+00:00 |          | true         | true
	   3 | worker-3:26257 | worker-3:26257 | v20.2.8 | 2021-04-24 22:46:38.742714+00:00 | 2021-04-25 12:28:25.349116+00:00 |          | true         | true


To enter the SQL client, run:

	$ cockroach sql --certs-dir=/cockroach-certs --host=cockroachdb-public
	
	# Welcome to the CockroachDB SQL shell.
	# All statements must be terminated by a semicolon.
	# To exit, type: \q.
	#
	# Server version: CockroachDB CCL v20.2.8 (x86_64-unknown-linux-gnu, built 2021/04/23 13:54:57, go1.13.14) (same version as client)
	# Cluster ID: d49fa52b-4fee-4599-9aed-a5798fdf1b35
	#
	# Enter \? for a brief introduction.
	#
	root@cockroachdb-public:26257/defaultdb>


To connect to a specific database run:


	$ cockroach sql --certs-dir=/cockroach-certs --host=cockroachdb-public -d my-database	
	

## Manage User Accounts

To be able to access the Web UI you need first to set the root password. This can be done form within the client SQL command line tool:


	$ ALTER USER root WITH PASSWORD 'YOUR-NEW-PASSWORD';	

With the new password and the user 'root' you can now login to the Web Frontend.

### Create a new Admin Account

To create a new user with admin rights, run the SQL command:

	$ CREATE USER roach WITH PASSWORD 'YOUR-USER-PASSWORD';
	$ GRANT admin TO roach;
	
### Create a new Database Account

To create a new user with all rights to a specific database, run the SQL command:

	$ CREATE USER my_user WITH PASSWORD 'MY-USER-PASSWORD';
	$ GRANT ALL ON DATABASE my_database TO my_user;
	$ GRANT ALL ON TABLE * TO my_user;

## Create a Database

To create a new database run:

	$ CREATE DATABASE mydatabase;




## Joining a new Worker Node

If you setup an additional CockroachDB cluster node you need to approve the auto generated certificate after the first deployment. You can see the command in the log file of the pod:


	$ kubectl certificate approve default.node.my-worker-4
	
		
## Mark a dead node as decommissioned

Run the cockroach node decommission command against the address of any live node, specifying the ID of the dead node:

	$ cockroach node decommission <id of the dead node> --certs-dir=/cockroach-certs --host=cockroachdb-public

## Remove a single node (dead)



