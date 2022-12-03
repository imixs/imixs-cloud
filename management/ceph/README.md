# Ceph 

Ceph is a distributed filesystem which can be used in combination with the *Imixs-Cloud* to run statefull applications. We assume that you have already installed a Ceph cluster and that your Ceph cluster is accessible from each kubernetes worker node. You can find a complete install guide for Ceph [here](https://ralph.blog.imixs.com/2021/10/03/ceph-pacific-running-on-debian-11-bullseye/).

**Note:** As the filesystem is a critical infrastructure component for a productive Kubernetes cluster we recommend to run ceph independent from Kubernetes on separate servers.  

The integration is based on the [ceph-csi plugin](https://github.com/ceph/ceph-csi) and provisioner in [version 3.7.2](https://github.com/ceph/ceph-csi/tree/v3.7.2/deploy/rbd/kubernetes). The ceph-csi plugin is using so called 'Managed rados Block Device (RBD)' images. The provisioner can create RBD images dynamically or connect to to static images to back Kubernetes volumes and maps these RBD images as block devices on worker nodes running pods that reference an RBD-backed volume. This integration includes the ability mounting a file system, with is the usual use case for most static applications. Ceph stripes block device images as objects across the cluster, which means that large Ceph Block Device images have better performance than a standalone server. 

## Setup a Kubernetes Pool 

Before you can integrate Ceph into your kubernetes cluster you need a separate Ceph pool used by Kubernetes. If not yet done, create a pool with the name 'kubernetes'.   This pool can be used for all volumes. 

Run the following ceph command on your Ceph node to intialize the pool:

	$ sudo ceph osd pool create kubernetes
	$ sudo rbd pool init kubernetes

Next create a new client.user for Kubernetes and ceph-csi. This user is used by the CSI Plugin to access your cluster. Execute the following command to create the user and accociate the userid with your new kubernetes pool. 

	# ceph auth get-or-create client.kubernetes mon 'profile rbd' osd 'profile rbd pool=kubernetes' mgr 'profile rbd pool=kubernetes'
	[client.kubernetes]
	   key = CQDgScJgGxxxxxxxxxxxxxxxxxxxxxxxxx+Q==

Record the generated key! This Key is important and needed later.

The ceph-csi requires a ConfigMap object stored in Kubernetes to define the Ceph monitor addresses for the Ceph cluster. To get this data you can run the command *ceph mon dump* which prints out the necessary information:

	$ sudo ceph mon dump
	dumped monmap epoch 3
	epoch 3
	fsid aaaaabbbb-xxxxxxxxxxxxxxxxxxxxxxxxxxx
	last_changed 2021-06-09T17:47:23.921432+0000
	created 2021-06-09T09:14:12.246383+0000
	min_mon_release 15 (octopus)
	0: [v2:10.0.0.3:3300/0,v1:10.0.0.3:6789/0] mon.ceph-1
	1: [v2:10.0.0.5:3300/0,v1:10.0.0.5:6789/0] mon.ceph-2
	2: [v2:10.0.0.4:3300/0,v1:10.0.0.4:6789/0] mon.ceph-3

record the *fsid* and your IP addresses from your mon nodes. Make sure that the ceph monitoring nodes are accessible on port 6789 from your Kubernetes cluster.


## Configure Ceph Kubernetes Objects

In The following section we will create the config map and secrets
	
### 1) Edit the ceph-csi ConfigMap for Kubernetes

First edit the file *csi-config-map.yaml* substituting the fsid for 'clusterID', and the monitor addresses <IP-ADDRESS-1>, <IP-ADDRESS-2>, <IP-ADDRESS-3>


### 2) Create the ceph-csi ceph Secret

Next create the namespace

	$ kubectl create namespace ceph-system

With the key form the generated client.kubernetes user create a secret to access your cluster:

	$ kubectl create secret generic csi-rbd-secret \
	    --from-literal=userID='kubernetes' \
	    --from-literal=userKey='[key-value]' \
	    --namespace=ceph-system	    

Here `[key-value]` is your ceph client.kubernetes key you generated before. You can verify the successful creation with:

	$ kubectl get secrets -n ceph-system 



### 3) Create the Storage Classes

The Kubernetes StorageClass defines a class of storage. In the file "csi-rbd-storageclass.yaml" the new storageClass 'ceph' is provided.

Edit the file *'030-csi-rbd-storageclass.yaml'*  substituting "<clusterID>" with your ceph fsid. You can customize these values if needed. 

If you have more than one ceph clusters to connect, than you need to create a separate StorageClass for each cluster. 


### 4) The csi-provisioner and rdbplugins

The ceph-csi Plugins and the ceph-csi provisioner in the yaml files 02x- are based on [version 3.7.2](https://github.com/ceph/ceph-csi/tree/v3.7.2/deploy/rbd/kubernetes). The csi-plugin and provisioner is needed to access Ceph. If needed you can customize and upgrade the ceph-csi version. Normally changes are not requried here. 	

### 5) Apply the Ceph System

After you have updated the yaml files as describe before you can now apply the Ceph CSI Plugin:

	$ kubectl apply -f management/ceph/v3.7.2/

## Update Cluster Information

In case something changed in your Ceph cluster (e.g. a change of monitor nodes) you need to update the *010-csi-config-map.yaml* values 
from your Ceph cluster and update thh config map using the following command:

	$ kubectl replace -f management/ceph/v3.7.2/010-csi-config-map.yaml

### Multiple Clusters

You can also define more than one Ceph cluster within the ceph-csi-plugin. In the *010-csi-config-map.yaml* you can add multiple entries for each cluster:

	apiVersion: v1
	kind: ConfigMap
	metadata:
	  name: ceph-csi-config
	  namespace: ceph-system
	data:
	  config.json: |-
	    [
	      {
	        "clusterID": "[YOUR-CLUSTER-ID-1]",
	        "monitors": [
	          "10.0.0.3:6789",
	          "10.0.0.5:6789",
	          "10.0.0.4:6789"
	        ]
	      },
	      {
	        "clusterID": "[YOUR-CLUSTER-ID-2]",
	        "monitors": [
	          "10.1.0.3:6789",
	          "10.1.0.5:6789",
	          "10.1.0.4:6789"
	        ]
	      }
	
	    ]
    
In this scenario you need to define also a separate storage class for each cluster with separate csi-rbd secrets for each cluster. Take care that your secrets and storageClasses have unique names. Update the config map and apply the changes:


	$ kubectl replace -f management/ceph/v3.7.2/010-csi-config-map.yaml
	$ kubectl apply -f management/ceph/v3.7.2/


## Create a PersistentVolumeClaim
	
A PersistentVolumeClaim is a request for abstract storage resources by a user. The PersistentVolumeClaim is associated to a Pod resource to provision a PersistentVolume, which would be backed by a Ceph block image. 
Using ceph-csi Filesystem  supports ReadWriteOnce and ReadOnlyMany accessMode claims. You can also create PersistentVolumeClaims for block devices. But mostly you will need Filesystem claims. 

With the StorageClass 'ceph' defined in the file *030-csi-rbd-storageclass.yaml* a PersistentVolume can be created automatically during deployment.
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
        
**Note:** This PersistentVolumeClaim creates dynamically a new image in the ceph pool `kubernetes`. The reclaimPolicy of the StorageClass is 'Delete' which means that the image will be removed when the pod is deleted. 

### Static Persistent Volumes

For stateful applications it is mostly necessary to retain the data generated by an application even if the POD is deleted (e.g. for a version update). 

To avoid the deletion of PersistentVolume you can create an Image within ceph with the command

	# rbd create test-image --size=1024 --pool=kubernetes --image-feature layering

Next you can define a corresponding PersistentVolume together with a matching PersistentVolumeClaim:


	---
	apiVersion: v1
	kind: PersistentVolumeClaim
	metadata:
	  name: rbd-static-pvc
	spec:
	  accessModes:
	  - ReadWriteOnce
	  resources:
	    requests:
	      storage: 1Gi
	  volumeMode: Filesystem
	  volumeName: rbd-static-pv
	  storageClassName: ceph
	
	---
	apiVersion: v1
	kind: PersistentVolume
	metadata:
	  name: rbd-static-pv
	spec:
	  volumeMode: Filesystem
	  storageClassName: ceph
	  persistentVolumeReclaimPolicy: Retain
	  accessModes:
	  - ReadWriteOnce
	  capacity:
	    storage: 1Gi
	  csi:
	    driver: rbd.csi.ceph.com
	    fsType: ext4
	    nodeStageSecretRef:
	      name: csi-rbd-secret
	      namespace: ceph-system
	    volumeAttributes:
	      clusterID: "<clusterID>"
	      pool: "kubernetes"
	      staticVolume: "true"
	      # The imageFeatures must match the created ceph image exactly!
	      imageFeatures: "layering"
	    volumeHandle: test-image 
	
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
	        
You need to substitute the <clusterID> in the PersistentVolume with your cluster ID as defined in the storreage class 'ceph'. The 'volumeHandle' is set to the image created before in ceph. 

This example will reuse the image 'test-image' without deletion if the POD is removed. 



### Resizing Static Persistent Volumes

If you need to resize your ceph image later you also need to resize the ext4 filesystem within your POD. For that you can use the resize2fs command from within your container.

	# resize2fs /dev/rbd[number]

If you don't have the lib in your container image or you have insufficient security privileges you can run the following JOB where you just need to replace the claim name:

	---
	###################################################
	# This job can be used to resize a ext4 filesystem
	# aligned to the given size of the underlying RBD image.
	###################################################
	apiVersion: batch/v1
	kind: Job
	metadata:
	  name: ext4-resize2fs
	spec:
	  template:
	    spec:
	      containers:
	        - name: debian
	          image: debian
	
	          command: ["/bin/sh"]
	          args:
	            - -c
	            - >-
	                echo '******** start resizeing block device  ********' &&
	                echo ...find rbd mounts to be resized.... &&
	                df | grep /rbd &&
	                DEVICE=`df | grep /rbd | awk '{print $1}'` &&
	                echo ...resizing device $DEVICE ... &&
	                resize2fs $DEVICE &&
	                echo '******** resize block device completed ********'
	
	          volumeMounts:
	            - name: volume-to-resize
	              mountPath: /tmp/mount2resize
	          securityContext:
	            privileged: true
	      volumes:
	        - name: volume-to-resize
	          persistentVolumeClaim:
	            claimName: test-pg-dbdata
	      restartPolicy: Never
	  backoffLimit: 1

Make sure that the PV and PVC objects exist before you run the job. Replace the PVC with the name of your PVC to be resized.

	$ kubectl apply -f resize2fs.yaml

Find also details [here](https://ralph.blog.imixs.com/2021/10/01/kubernetes-ceph-and-static-volumes/)

	