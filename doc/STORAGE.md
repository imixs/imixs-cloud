# Storage

To run stateful docker images (e.g. a Database like PostgreSQL) you need to define a storage volume along with your service. In general you have two choices.

 1. Run the service on a dedicated node and use a local volume - this avoids the lost of data as kubernetes will not re-schedule your service to another node with a new local volume
 1. Use a distributed storage solution like [longhorn](https://longhorn.io/), [ceph](https://ceph.io/) or [glusterfs](https://www.gluster.org/) storage 

Of course, only the second variant is appropriate for a Kubernetes cluster. Because the idea of Kubernetes is to abstract all hardware to your services. This includes also data volumes. A distributed storage solution means that independent of where your application is running the storage will always be available in the same way.  
 
Due to its simplicity and the very good integration in Kubernetes, we use [Longhorn](https://longhorn.io/) as the preferred storage solution within Imixs-Cloud. But of course you can also integrate other distributed storage systems.
 
<img src="images/storage-longhorn-01.png" />
 


## Quick Setup

For a quick setup check the file /management/longhorn/002-ingress.yaml. This file will provide a placeholder for the Longhonr Web UI. If you have setup this file to your needs you can start Longhorn within the Imixs-Cloud with:

	$ kubectl apply -f management/longhorn/

For a more detailed setup guide see the following sections. 

## Setup of Longhorn
 
Longhorn is a cloud native distributed block storage for Kubernetes. Longhorn delivers simplified, easy to deploy and upgrade, 100% open source, cloud-native persistent block storage without the cost overhead of open core or proprietary alternatives. This makes Longhorn very easy to integrate in a kubernets cluster.


### open-iscsi
	
Make sure that 'open-iscsi' has been installed on all the nodes of the Kubernetes cluster, and the _iscsid_ daemon is running on all the nodes.

For Debian/Ubuntu, use the following command to install open-iscsi: 

	$ sudo apt-get install open-iscsi


### Install Longhorn into your Cluster


You can install Longhorn  into your Kubernetes cluster using this command:

	$ kubectl apply -f https://raw.githubusercontent.com/longhorn/longhorn/master/deploy/longhorn.yaml

This will start Longhorn with the lates release. If you want to have more control you can copy the longhonr.yaml file int your management directory stored in the Imixs-Cloud directory structure. You can change or customize this file.


	$ kubectl apply -f management/longhorn/001-deployment.yaml

The startup can take a while. You can monitor the startup with the [K9s tool](../tools/k9s/README.md).

### The Longhorn-UI

Longhorn comes with a UI web interface to monitor and administrate the cluster. 

You can create a ingress for the Longhorn UI with a traefik ingress route:


	kind: IngressRoute
	apiVersion: traefik.containo.us/v1alpha1
	metadata:
	  name: longhorn-frontend
	  namespace: longhorn-system
	
	spec:
	  entryPoints: 
	    - web
	  routes:
	  - match: Host(`{YOUR-DNS}`) 
	    kind: Rule
	    services:
	    - name: longhorn-frontend
	      port: 8000
	    
	    

Replace {YOUR-DNS} with a DNS name pointing to your cluster and apply the ingress route:


	$ kubectl apply -f management/longhorn/002-ingress.yaml




## Create Longhorn Volumes

Before you create Kubernetes volumes, you must first create a storage class. Use following command to create a StorageClass called longhorn.


	kind: StorageClass
	apiVersion: storage.k8s.io/v1
	metadata:
	  name: longhorn
	provisioner: driver.longhorn.io
	allowVolumeExpansion: true
	parameters:
	  numberOfReplicas: "3"
	  staleReplicaTimeout: "2880" # 48 hours in minutes
	  fromBackup: ""

This storage class definition will automatically create 3 replicas of a persistence volume.   

### Create a Volume Claim

Now you can easily create a Persistence Volume Claim (PVC) within your pod using the new _longhorn_ StorageClass.


	apiVersion: v1
	kind: PersistentVolumeClaim
	metadata:
	  name: dbdata
	spec:
	  accessModes:
	    - ReadWriteOnce
	  storageClassName: longhorn
	  resources:
	    requests:
	      storage: 2Gi


To create the new storage class run:

	$ kubectl apply -f management/longhorn/003-storageclass.yaml




### Data Directory exists but is not empty

It may happen that after you try to run your service you see an error message like in the following postgresql example: 

	initdb: directory "/var/lib/postgresql/data" exists but is not empty It contains a lost+found directory, 
	perhaps due to it being a mount point. Using a mount point directly as the data directory is not recommended. 
	Create a subdirectory under the mount point.

In such a case you just need to add a subPath


	...
	volumeMounts:
	- mountPath: /var/lib/postgresql/data
	  name: test-db-volume
	  subPath: postgres
	...


See more details [here](https://stackoverflow.com/questions/51168558/how-to-mount-a-postgresql-volume-using-aws-ebs-in-kubernete/51174380).


## How to Uninstall Longhorn

To prevent damaging the Kubernetes cluster, it is recommended deleting all Kubernetes workloads using Longhorn volumes (PersistentVolume, PersistentVolumeClaim, StorageClass, Deployment, StatefulSet, DaemonSet, etc) first.

You can create the uninstallation job to clean up CRDs from the system and wait for success:

	$ kubectl create -f https://raw.githubusercontent.com/longhorn/longhorn/master/uninstall/uninstall.yaml
	
The uninstall process can take a while.

Example output:

	$ kubectl create -f https://raw.githubusercontent.com/longhorn/longhorn/master/uninstall/uninstall.yaml
	serviceaccount/longhorn-uninstall-service-account created
	clusterrole.rbac.authorization.k8s.io/longhorn-uninstall-role created
	clusterrolebinding.rbac.authorization.k8s.io/longhorn-uninstall-bind created
	job.batch/longhorn-uninstall created
	
	$ kubectl get job/longhorn-uninstall -w
	NAME                 COMPLETIONS   DURATION   AGE
	longhorn-uninstall   0/1           3s         3s
	longhorn-uninstall   1/1           20s        20s
	^C


Remove remaining components:

	kubectl delete -f https://raw.githubusercontent.com/longhorn/longhorn/master/deploy/longhorn.yaml
	kubectl delete -f https://raw.githubusercontent.com/longhorn/longhorn/master/uninstall/uninstall.yaml



Find details about the uninstall process also [here](https://github.com/longhorn/longhorn#uninstall-longhorn).
	


#### Delete namespace 'longhorn-system'

To remove the longhorn-system namespace you can run the following command:


	$ kubectl get namespace "longhorn-system" -o json \
	  | tr -d "\n" | sed "s/\"finalizers\": \[[^]]\+\]/\"finalizers\": []/" \
	  | kubectl replace --raw /api/v1/namespaces/longhorn-system/finalize -f -
  

