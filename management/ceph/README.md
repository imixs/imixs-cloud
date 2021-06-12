# Ceph 

You can use Ceph as distributed filesystem for *Imixs-Cloud*. We assume that you have already installed a Ceph cluster and your Ceph cluster is running independent from your kubernetes cluster. We also assume that and you can access your Ceph nodes from each kubernetes worker nodes via a private network. 

This integration is based on the 'Managed rados Block Device (RBD)' images which dynamically provisions RBD images to back Kubernetes volumes and maps these RBD images as block devices on worker nodes running pods that reference an RBD-backed volume. This integration also allows mounting a file system contained within the image, with is the usual use case. Ceph stripes block device images as objects across the cluster, which means that large Ceph Block Device images have better performance than a standalone server. 


**Note:** The official integration guides form the ceph homepage for the releases 'octopus' and 'pacific' are both outdated in some important details. For that reason this guide is based on the [latest release guide for 'Block Devices and Kubernetes'](https://docs.ceph.com/en/latest/rbd/rbd-kubernetes/) - based on June 2021.

You can find a complete install guide for Ceph [here](https://ralph.blog.imixs.com/2020/04/14/ceph-octopus-running-on-debian-buster/).


## Setup a Kubernetes Pool 

Before you can integrate Ceph into your kubernetes cluster you need a Ceph pool used by Kubernetes. If not yet done, create a pool with the name 'kubernetes': 

On the Ceph manager node enter the *cephadm shell* to create a pool for Kubernetes volume storage. This pool can be used for all volumes

	# ceph osd pool create kubernetes

Next initialize the pool

	# rbd pool init kubernetes

Next create a new client.user for Kubernetes and ceph-csi. Execute the following command in the cephadm shell to create the user and accociate the userid with your new rbd pool. 

	# ceph auth get-or-create client.kubernetes mon 'profile rbd' osd 'profile rbd pool=kubernetes' mgr 'profile rbd pool=kubernetes'
	[client.kubernetes]
	   key = CQDgScJgGxxxxxxxxxxxxxxxxxxxxxxxxx+Q==

Record the generated key! This Key is important and needed later.

The ceph-csi requires a ConfigMap object stored in Kubernetes to define the Ceph monitor addresses for the Ceph cluster. To get this data you can run the command *ceph mon dump* which prints out the necessary information:

	# ceph mon dump
	dumped monmap epoch 3
	epoch 3
	fsid aaaaabbbb-xxxxxxxxxxxxxxxxxxxxxxxxxxx
	last_changed 2021-06-09T17:47:23.921432+0000
	created 2021-06-09T09:14:12.246383+0000
	min_mon_release 15 (octopus)
	0: [v2:10.0.0.3:3300/0,v1:10.0.0.3:6789/0] mon.ceph-1
	1: [v2:10.0.0.5:3300/0,v1:10.0.0.5:6789/0] mon.ceph-2
	2: [v2:10.0.0.4:3300/0,v1:10.0.0.4:6789/0] mon.ceph-3

record the *fsid* and your IP addresses from your mon nodes (which should be in your private network accessible form your Kubernetes cluster).



## Configure Ceph Kubernetes Objects

In The following section you can see how the Kubernetes objects, needed to use Ceph as a filesystem need to be setup.
	
### 1) Edit the ceph-csi ConfigMap for Kubernetes

First edit the file *csi-config-map.yaml* substituting the fsid for "<clusterID>", and the monitor addresses <IP-ADDRESS-1>, <IP-ADDRESS-2> and <IP-ADDRESS-3>


### 2) Create the ceph-csi ceph Secret

First create the namespace

	$ kubectl create namespace ceph-system

With the key form the generated client.kubernetes user create a now a secret 

	$ kubectl create secret generic csi-rbd-secret \
	    --from-literal=userID='kubernetes' \
	    --from-literal=userKey='<key-value>' \
	    --namespace=ceph-system	    

Where <key-value> is your ceph client.kubernetes key. You can verify the cuccessfull creation with:

	$ kubectl get secrets ceph-admin-secret -n ceph-system 



### 3) Create the Storage Classes

The Kubernetes StorageClass defines a class of storage. In the file "csi-rbd-storageclass.yaml" we provide to classes

 - ceph - for  dynamic storage claims
 - ceph-durable -  a durable pv for static storage claims 

Edit the file *'030-csi-rbd-storageclass.yaml'*  substituting "<clusterID>" with your ceph fsid.

You can customize these classes if needed. For example you can create additional pools for specific storage classes. 


### 4) The csi-provisioner and rdbplugins

The ceph-csi Plugins and the ceph-csi provisioner in the yaml files 02x- are needed to access Ceph.  With the possible exception of the ceph-csi container release version, these objects do not necessarily need to be customized for your Kubernetes environment and therefore can be used as-is from the ceph-csi deployment YAMLs. But you can check the files content before deployment from the origin urls

You can find the origin versions of these kubernetes objects on github:

	https://github.com/ceph/ceph-csi/tree/devel/deploy/rbd/kubernetes
	

## Apply the Ceph System

After you have updated the yaml files as describe before you can now apply the Ceph Storage:

	$ kubectl apply -f management/ceph/


## Create a PersistentVolumeClaim
	
A PersistentVolumeClaim is a request for abstract storage resources by a user. The PersistentVolumeClaim would then be associated to a Pod resource to provision a PersistentVolume, which would be backed by a Ceph block image. 
Using ceph-csi Filesystem  supports ReadWriteOnce and ReadOnlyMany accessMode claims. You can also create PersistenceVolume Clains for block devices. But mostly you will need Filesystem claims. 

See the following example for a Ceph PersistentVolumeClaim and a example application

	---
	apiVersion: v1
	kind: PersistentVolumeClaim
	metadata:
	  name: rbd-pvc
	spec:
	  accessModes:
	    - ReadWriteOnce
	  volumeMode: Filesystem
	  resources:
	    requests:
	      storage: 1Gi
	  storageClassName: ceph
	---
	apiVersion: v1
	kind: Pod
	metadata:
	  name: csi-rbd-demo-pod
	spec:
	  containers:
	    - name: web-server
	      image: nginx
	      volumeMounts:
	        - name: mypvc
	          mountPath: /var/lib/www/html
	  volumes:
	    - name: mypvc
	      persistentVolumeClaim:
	        claimName: rbd-pvc
	        readOnly: false
        







	