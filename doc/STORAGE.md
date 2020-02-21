# Storage

To run statefull docker images (e.g. a Database like PostgreSQL) you have two choices.

 - run the service on a dedicated node - this avoids the lost of data if kubernetes re-schedules your server to another node
 - use a distributed storage solution like [ceph](https://ceph.io/) or [glusterfs](https://www.gluster.org/) storage 
 

# Gluster

Gluster is a scalable network filesystem. This allows you to create a large, distributed storage solution on common hard ware. You can connect a gluster storage to Kubernetes to abstract the volume from your services. 

## Install

You can install Glusterfs on any node this includes the kubernetes worker nodes. 

The following guide explains how to intall Glusterfs on Debian 9. You will find more information about installation [here](https://docs.gluster.org/en/latest/Install-Guide/Overview/).

 
Run the following commands as root:

	$ su
	
	# Add the GPG key to apt:
	$ wget -O - https://download.gluster.org/pub/gluster/glusterfs/7/rsa.pub | apt-key add -
	
	# Add the source (s/amd64/arm64/ as necessary):	
    $ echo deb [arch=amd64] https://download.gluster.org/pub/gluster/glusterfs/7/LATEST/Debian/stretch/amd64/apt stretch main > /etc/apt/sources.list.d/gluster.list
    
    # Install...
    $ apt-get update
    $ apt-get install glusterfs-server
	
	
To test the gluster status run:

	$ service glusterd status	
	
Repeat this installation on each node you wish to joing your gluster network storage.


## Setup Gluster Network

Now you can check form one of your gluster nodes if you can reach each other node


	$ gluster peer probe [gluster-node-ip]

where 	gluster-node-ip is the IP Adress or the DNS name of one of your gluster nodes.

Now you can check the peer status on each node:

	$ gluster peer status
	Uuid: vvvv-qqq-zzz-yyyyy-xxxxx
	State: Peer in Cluster (Connected)
	Other names:
	[YOUR-GLUSTER-NODE-NAME]

	
## Setup a Volume

Now you can set up a GlusterFS volume. For that create a data volume on all servers:

	$ mkdir -p /data/glusterfs/brick1/gv0

From any single worker node run:

	$ gluster volume create gv0 replica 2 [GLUSTER-NODE1]:/data/glusterfs/brick1/gv0 [GLUSTER-NODE2]:/data/glusterfs/brick1/gv0
	volume create: gv0: success: please start the volume to access data

replace [GLUSTER-NODE1] with the gluster node dns name or ip address. 

**Note:** the directory must not be on the root partition. At leaset you should provide 3 gluster nodes. 

Now you can start your new volume 'gv0': 


	$ gluster volume start gv0
	volume start: gv0: success

With the following command you can check the status of the new volume:

	$ gluster volume info
	
Find more about the setup [here}(https://docs.gluster.org/en/latest/Quick-Start-Guide/Quickstart/).


 	




# Ceph

Ceph is a scalable network filesystem. This allows you to create a large, distributed storage solution on common hard ware. You can connect a Ceph storage to Kubernetes to abstract the volume from your services. 

## Install

You can install Ceph on any node this includes the kubernetes worker nodes. 

The following guide explains how to install Ceph on Debian 9. You will find detailed information about installation [here](https://docs.ceph.com/docs/luminous/install/).

	
## Install ceph-deploy

First install the ceph-depploy service on your master node. ceph-deploy will be used to install the ceph software on your worker nodes.

https://docs.ceph.com/docs/master/start/quick-start-preflight/

**Note:** In the following example I will use 'node1' 'node2' 'node3' as node names. Make sure to replace this names with the short names of your cluster nodes. 

On your Kubernetes master node run as non root user:

	
	$ wget -q -O- 'https://download.ceph.com/keys/release.asc' | sudo apt-key add -
	$ echo deb https://download.ceph.com/debian-luminous/ $(lsb_release -sc) main | sudo tee /etc/apt/sources.list.d/ceph.list
	$ sudo apt-get update && sudo apt-get install ceph-deploy ntp
	$ sudo /etc/init.d/ntp restart


Check the Ceph-Deploy version:

	$ ceph-deploy --version


### Create a Ceph Deploy User


The ceph-deploy utility must login to a Ceph node as a user that has passwordless sudo privileges, because it needs to install software and configuration files without prompting for passwords. 

** Note:**
In Imixs-Cloud you should always work with an unprivileged cluster user defined on your master node and also on all your worker nodes. 
So if you did not have created a cluster-user you should first create a ssh user on all your ceph nodes. You can find details it the [Setup section](SETUP.md). For background information see also [here](https://docs.ceph.com/docs/master/start/quick-start-preflight/#create-a-ceph-deploy-user).


## Install a Ceph Cluster

Now as you have installed ceph-deplyo and created ssh access to your ceph nodes you can create a new ceph cluster. You can find details about this procedure [here](https://docs.ceph.com/docs/master/start/quick-ceph-deploy/). 

First create a working directory to store you configurations.

	$ mkdir ceph-cluster
	$ cd ceph-cluster


On your master node from the directory you created start to create the cluster:

	$ ceph-deploy new node1 node2 node3


You can verify the Ceph configuration in the file 'ceph.conf'

	$ cat ceph.conf
	

Next install Ceph packages:
	
	
	$ ceph-deploy install --release luminous node1 node2 node3

The ceph-deploy utility will install Ceph on each node.

**Note:** The release must match the release you have installed on your master node!


Deploy the initial monitor(s) and gather the keys:
	
	$ ceph-deploy mon create-initial

Use ceph-deploy to copy the configuration file and admin key to your admin node and your Ceph Nodes

	$ ceph-deploy admin node1 node2 node3


Deploy a manager daemon. (Required only for luminous+ builds):

	$ ceph-deploy mgr create node1



### Create Object Store Daemons (OSDs)


Now you can create the OSDs on your ceph nodes. For the purposes of these instructions, we assume you have an unused disk in each node called /dev/vdb. Be sure that the device is not currently in use and does not contain any important data.

	ceph-deploy osd create --data {device} {ceph-node}

**Note:** the device does not have to be mounted in a directory.

For example:

	ceph-deploy osd create --data /dev/vdb node1
	ceph-deploy osd create --data /dev/vdb node2
	ceph-deploy osd create --data /dev/vdb node3


Check your cluster’s health.

	$ ssh node1 sudo ceph health
	HEALTH_OK
	
You ceph cluster is now ready to use!



## Starting over

If at any point you run into trouble and you want to start over, execute the following to purge the Ceph packages, and erase all its data and configuration:

	$ sudo ceph-deploy purge node1 node2
	$ ceph-deploy purgedata node1 node2
	$ ceph-deploy forgetkeys
	$ rm ceph.*

If you execute purge, you must re-install Ceph. The last rm command removes any files that were written out by ceph-deploy locally during a previous installation.


### remove logical volumes from a ceph-node

If you need to remove a logical volume from a ceph-node you can use the following procedure (Note: this will erase all content from your device!)

List all logical volumes on a node:

	$ sudo ceph-volume lvm list


Wipout a logical device. (replace [device-name] with you device e.g. sdb)

	$ sudo dmsetup info -C
	# copy the ceph dm name
	$ sudo dmsetup remove [dm_map_name]
	
	$ sudo wipefs -fa /dev/[device-name]
	$ sudo dd if=/dev/zero of=/dev/[device-name] bs=1M count=1
	$ sudo ceph-volume lvm zap /dev/[device-name] --destroy



## Kubernetes

In the following steps we create a kubernetes rdb provisoner and a ceph pool applied to a storageClass. Find also more details [here](https://ralph.blog.imixs.com/2020/02/21/kubernetes-storage-volumes-with-ceph). 

First create the provisioner with:

	$ kubectl create -n kube-system -f 001-rbd-provisioner.yaml 

To check your new deployment run:

	$ kubectl get pods -l app=rbd-provisioner -n kube-system
	NAME                               READY   STATUS    RESTARTS   AGE
	rbd-provisioner-7ab15f45bd-rnxx8   1/1     Running   0          96s

### Get the client.admin Secret Key

To allow kubernetes to access your ceph cluster you need to provide the ceph admin key. With the following command you can get the ceph admin key out from one of your ceph nodes:

	$ sudo ssh node1 ceph auth get-key client.admin
	ABCyWw9dOUm/FhABBK0A9PXkPo6+OXpOj9N2ZQ==

Copy the key and create a kubernetes secret named ‘ceph-secret’:

	 $ kubectl create secret generic ceph-secret \
	    --type="kubernetes.io/rbd" \
	    --from-literal=key='ABCyWw9dOUm/FhABBK0A9PXkPo6+OXpOj9N2ZQ==' \
	    --namespace=kube-system
	secret/ceph-secret created

### Create a Ceph Pool and a User Key

Now create a separate Ceph pool for Kubernetes:

	$ sudo ssh node-1 ceph --cluster ceph osd pool create kube 16 16
	pool 'kube' created

For this new pool you can create a user key:

	sudo ssh node-1 "ceph auth get-or-create client.kube mon 'allow r' osd 'allow rwx pool=kube'"
	[client.kube]
		key = CDEgU1BeVMyDJxAA7+ufUoqTdvmZUUR8tJeGnEg==

Also for this user key we create a separate kubernetes secret:

	$ kubectl create secret generic ceph-secret-kube \
	    --type="kubernetes.io/rbd" \
	    --from-literal=key='ABCyWw9dOUm/FhABBK0A9PXkPo6+OXpOj9N2ZQ==' \
	    --namespace=kube-system

Both kubernetes secrets ‘ceph-secret’ and ‘ceph-secret-kube’ are used for the StorageClass created in the next step.
The StorageClass

Next a storage class definition holds the information about the ceph cluster environment. Replace {node-ip} with the ip addresses of you cluster nodes:

	apiVersion: storage.k8s.io/v1
	kind: StorageClass
	metadata:
	  name: fast-rbd
	provisioner: ceph.com/rbd
	parameters:
	  monitors: {node-1}:6789, {node-2}:6789, {node-3}:6789
	  adminId: admin
	  adminSecretName: ceph-secret
	  adminSecretNamespace: kube-system
	  pool: kube
	  userId: kube
	  userSecretName: ceph-secret-kube
	  userSecretNamespace: kube-system
	  imageFormat: "2"
	  imageFeatures: layering

Take care of the ‘adminSecretName’ and the ‘userSecretName’ which we generated before.

Now you can apply the new StorageClass:

	$ kubectl create -f pool-1-storageclass.yaml

### The PersistentVolumeClaim

As you now have created a ceph pool and the corresponding storageClass you are ready to define a so called PersistentVolumeClaim (PVC). A PVC is part of your pods. The PVC will create the persistence volume automatically associated with your pod.

	kind: PersistentVolumeClaim
	apiVersion: v1
	metadata:
	  name: testclaim
	spec:
	  accessModes:
	    - ReadWriteOnce
	  resources:
	    requests:
	      storage: 1Gi
	  storageClassName: fast-rbd

create the claim:

	$ kubectl create -f test-pvc.yaml

and finally you can test the status of your persistent volume claim:

	$ kubectl get pvc
	NAME          STATUS    VOLUME                                     CAPACITY   ACCESS MODES   STORAGECLASS   AGE
	testclaim     Bound     pvc-060e5142-f915-4385-8e86-4166fe2980f6   1Gi        RWO            fast-rbd       27m


