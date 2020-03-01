# GlusterFS


## Persistence Volume Example 

The following is an example how to create a volume claim for the GlusterFS within a pod. First you need to create a persistence volume (pv)

gluster-pv.yaml:

	apiVersion: v1
	kind: PersistentVolume
	metadata:
	  # The name of the PV, which is referenced in pod definitions or displayed in various oc volume commands.
	  name: gluster-pv   
	spec:
	  capacity:
	    # The amount of storage allocated to this volume.
	    storage: 1Gi     
	  accessModes:
	    # labels to match a PV and a PVC. They currently do not define any form of access control.
	  - ReadWriteMany    
	  # The glusterfs plug-in defines the volume type being used 
	  glusterfs:         
	    endpoints: gluster-cluster 
	    # Gluster volume name, preceded by /
	    path: /gv0
	    readOnly: false
	  # volume reclaim policy indicates that the volume will be preserved after the pods accessing it terminate.
	  # Accepted values include Retain, Delete, and Recycle.
	  persistentVolumeReclaimPolicy: Retain


The gluser volume must be created before.


## Persistence Volume Claim Example 

The persistent volume claim (PVC) specifies the desired access mode and storage capacity. 
Currently, based on only these two attributes, a PVC is bound to the PV created before. 
Once a PV is bound to a PVC, that PV is essentially tied to the PVC’s project and cannot be bound to by another PVC. 
There is a one-to-one mapping of PVs and PVCs. However, multiple pods in the same project can use the same PVC.


gluster-pvc.yaml:

	apiVersion: v1
	kind: PersistentVolumeClaim
	metadata:
	  name: gluster-claim  
	spec:
	  accessModes:
	  - ReadWriteMany      
	  resources:
	     requests:
	       storage: 1Gi



The claim name is referenced by the pod under its volumes section.


## Deployment Example

Within a deployment you can than mount a volume based on this claim. See the following example:


	apiVersion: apps/v1
	kind: Deployment
	.....
	spec:
	  ....
	  template:
	    ....
	    spec:
	      containers:
	      .....
	        image: postgres:9.6.1
	        # run as root because of glusterfs
           securityContext:
             runAsUser: 0
             allowPrivilegeEscalation: false
          
	        volumeMounts:
	        - mountPath: /var/lib/postgresql/data
	          name: dbdata
	          readOnly: false
	      restartPolicy: Always
	      volumes:
	      - name: dbdata
	        persistentVolumeClaim:
	          claimName: gluster-claim
	....



	
	
	
Find also a more detailed example [here](https://aws-labs.com/kubernetes-complete-glusterfs/). 	