# CockroachDB

In Imixs-Cloud we run the CockraochDB as a DaemonSet. You can find information how to run CockroachDB in a Kuberentes Cluster [here](https://ralph.blog.imixs.com/2021/04/22/cockroachdb-kubernetes/). General install information can be found [here](https://www.cockroachlabs.com/docs/v21.1/kubernetes-performance#running-in-a-daemonset). 

## Deployment

To deploy a new CockroachDB cluster follow these steps:

### Edit the 020-daemoenset.yaml File

First you need to edit the daemonset so that it fits to your cluster environment.  

**1)** Edit the file '020-deaemonset.yaml' and add some of your worker nodes as a value into the --join parameter:

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
             --join=worker-1:26257,worker-2:26257,worker-3:26257"

Replace the 'worker-1' with the host name of your nodes. The port number 26257 is the default port used for the daemonset. 

**2)** Optional uncomment and edit the 'nodeSelector' section to define on which nodes cockroachDB should be deployed. You can add additional selector criteria.  

      nodeSelector:
        app: cockroachdb

Find details about the nodeSelector [here](https://kubernetes.io/docs/concepts/workloads/controllers/daemonset/#running-pods-on-select-nodes).

**3)** Change the resource limits to your needs.

        resources:
          requests:
            cpu: "2"
            memory: "2Gi"
          limits:
            cpu: "16"
            memory: "2Gi"

**4)** Edit the file location for the datadir

Replace "/var/lib/cockroachdb" with the path where you want CockroachDB's data stored on your Kubernetes nodes.

      volumes:
      - name: datadir
        hostPath:
          path: /var/lib/cockroachdb


### Edit the 020-ingress.yaml File

Change the host to a public Internet domain name in the 020-ingress.yam file. 

		spec:
		  tls:
		  - hosts:
		    - cockroach.foo.com
		    secretName: tls-cockroachdb-ui
		  rules:
		  - host: cockroach.foo.com
		  

### Deploy the daemonSet 

To deploy the CockraochDB nodes into your cluster run:

	$ kubectl apply -f management/cockroachdb

Now the cockroachDB is not yet initialized. To init the cluster folloe these steps:

First you need to approve the certificates created during the deployment. You can check the status of the new certificates with:

	$ kubectl get csr
	NAME                             AGE   SIGNERNAME                     REQUESTOR                                   CONDITION
	default.node.cockroachdb-0   1s    kubernetes.io/legacy-unknown   system:serviceaccount:default:cockroachdb   Pending
	default.node.cockroachdb-1   1s    kubernetes.io/legacy-unknown   system:serviceaccount:default:cockroachdb   Pending
	default.node.cockroachdb-2   1s    kubernetes.io/legacy-unknown   system:serviceaccount:default:cockroachdb   Pending

To approve the certificates run:

	$ kubectl certificate approve default.node.cockroachdb-0
	$ kubectl certificate approve default.node.cockroachdb-1
	$ kubectl certificate approve default.node.cockroachdb-2


Next edit the file scripts/cluster-init-secure.yaml and replace the HOST_IP_ADDR  with the first of of your worker nodes. Than init the cluster with:


	$ kubectl create -f management/cockroachdb/scripts/cluster-init-secure.yaml
 
Now after a moment you should be able to access the CockroachDB Web Frontend with your browser:

	https://cockroachdb.foo.com
 
 
## Get the Cluster Status

To get the status of your cluster ssh into one of the running cockroach nodes and run:

	$ ./cockroach node status \
	--certs-dir cockroach-certs
	


## The SQL Client

With the cockroach-client you can enter the SQL command line tool to inspect, create and update database objects.

To enter the SQL command line tool run:


	$ kubectl create \
	-f https://raw.githubusercontent.com/cockroachdb/cockroach/master/cloud/kubernetes/client-secure.yaml

you can exit the tool with

	$ \q



## Manage User Accounts

To change the root password, run the SQL command:

	$ ALTER USER root WITH PASSWORD 'YOUR-NEW-PASSWORD';	

To create a new user, run the SQL command:

	$ CREATE USER roach WITH PASSWORD 'YOUR-USER-PASSWORD';
	$ GRANT admin TO roach;

## Create a Database

To create a new database run:

	$ CREATE DATABASE mydatabase;




## Joining a new Worker Node

If you setup an additional CockroachDB cluster node you need to approve the auto generated certificate after the first deployment. You can see the command in the log file of the pod:


	$ kubectl certificate approve default.node.test-worker-4
	
		
## Mark a dead node as decommissioned

Run the cockroach node decommission command against the address of any live node, specifying the ID of the dead node:

	$ cockroach node decommission <id of the dead node> --certs-dir=certs --host=<address of any live node>
	
