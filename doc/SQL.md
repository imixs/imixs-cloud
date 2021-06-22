# SQL Databases

SQL Databases are often an important part of business applications. This is also true if you run your application in Kubernetes. As explained in the section [Storage](STORAGE.md) you need to provide a separate solution to persist data. Espacially for SQL Datbases there are different solutions.


## PostgreSQL

To run a PostgreSQL database within Kubernetes requires a storage solution the database can work with. With [Longhorn](LONGHORN.md) or [Ceph](CEPH.md) you can run PostgreSQL in a reasonable way. You only need to map the PostgreSQL data directory to a distributed data volume as provided by Longhorn and Ceph. See the following example:

	---
	###################################################
	# Deployment PostgreSQL
	###################################################
	apiVersion: apps/v1
	kind: Deployment
	metadata:
	  name: postgres
	  labels: 
	    app: postgres
	spec:
	  replicas: 1
	  selector: 
	    matchLabels:
	      app: postgres
	  strategy:
	    type: Recreate
	  template:
	    metadata:
	      labels:
	        app: postgres
	    spec:
	      containers:
	      - env:
	        - name: POSTGRES_DB
	          value: office
	        - name: POSTGRES_PASSWORD
	          value: xxxx
	        - name: POSTGRES_USER
	          value: user
	        image: postgres:9.6.1
	        name: postgres
	        ports:
	          - containerPort: 5432        
	        volumeMounts:
	        - mountPath: /var/lib/postgresql/data
	          name: dbdata
	          subPath: postgres
	      restartPolicy: Always
	      volumes:
	      - name: dbdata
	        persistentVolumeClaim:
	          claimName: dbdata
	
	---
	###################################################
	# Persistence Volume for DB
	###################################################
	kind: PersistentVolume
	apiVersion: v1
	metadata:
	  name: dbdata
	spec:
	  capacity:
	    storage: 100Gi
	  volumeMode: Filesystem
	  accessModes:
	    - ReadWriteOnce
	  claimRef:
	    name: dbdata
	  csi:
	    driver: driver.longhorn.io
	    fsType: ext4
	    volumeHandle: dbdata
	  storageClassName: longhorn-durable
	
	---
	###################################################
	# Persistence Volume Claim for DB
	###################################################
	apiVersion: v1
	kind: PersistentVolumeClaim
	metadata:
	  name: dbdata
	spec:
	  storageClassName: longhorn-durable
	  accessModes:
	    - ReadWriteOnce
	  resources:
	    requests:
	      storage: 100Gi
	  volumeName: "dbdata"



          


## Cockroach

The [CockroachDB](https://www.cockroachlabs.com/) is a distributed SQL database with a build in replication mechanism. 
The database can be used as a central database cluster running as part of the Imixs-Cloud. 

Cockroach provides  a build in replication mechanism. This means that the data is replicated automatically over several nodes in a database cluster. This increases the scalability and resilience in the case that a single node fails. With its Automated-Repair feature the database also detects data inconsistency and automatically fixes faulty data on disks. The project is Open Source and hosted on [Github](https://github.com/cockroachdb/cockroach).


### Web Frontend

Cockroach provides a Web Frontend with a dashboard to monitor all metrics about the running database cluster. 

<img src="images/cockroach-screen-01-768x451.png" />



### How to Install

To install CockroachDB into your Imixs-Cloud environment follow the [install guide](../management/cockroachdb/README.md).
You can run  CockroachDB on all your cluster nodes or you can define specific selection criterias with the concept of [Node affinities](https://kubernetes.io/docs/concepts/scheduling-eviction/assign-pod-node/#node-affinity) and [Taints and Tolerations](https://kubernetes.io/docs/concepts/scheduling-eviction/taint-and-toleration/).

### The Cockroach Client

The cockroach client provides a command line tool to administrate the cluster and to open a SQL client shell to create and edit databases and table schemas. The client is installed as a separate POD within your Kubernetes Cluster. 

To access the client your need a ssh into the client POD

	$ kubectl exec -it -n cockroach cockroachdb-client-secure -- bash

From there you can enter the SQL client:

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
	

### JDBC

Cockroach supports the PostgreSQL wire protocol and can be used out of the box for the Java Enterprise Applications and Microservices using the standard PostgresSQL JDBC driver.

Cockroach runs in the namespace 'cockroach'. To access the database from a java application you can use a JDBC connection like in the following example:

	jdbc:postgresql://cockroachdb-public.cockroach:26257/YOUR-DATABASE


### ACIC Transactions

**Note:** CockroachDB does not support the same isolation level in ACID transactions like PostgreSQL. This means guaranteed atomicity, isolation, consistency, and durability of data can be a problem if CockroachDB is used in combination with Jakarta EE and JPA. 


	
