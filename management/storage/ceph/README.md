# Ceph Pool

The templates here are used to define a ceph provisioner and the storage class used for  a CephFS.

Before you can deploy the CephFS provisioner into you kubernetes cluster you first need to create a secret and edit the cephfs-storageclass.yaml file.


	
## Create the CEPHFS provisioner

With the following command you can get the ceph admin key out from one of your ceph nodes:

	$ sudo ssh node1 ceph auth get-key client.admin
	ABCyWw9dOUm/FhABBK0A9PXkPo6+OXpOj9N2ZQ==

Copy the key and create a kubernetes secret named ‘ceph-secret’:

	 $ kubectl create secret generic ceph-secret-admin \
	    --from-literal=key='ABCyWw9dOUm/FhABBK0A9PXkPo6+OXpOj9N2ZQ==' \
	    --namespace=kube-system
	secret/ceph-secret created	

Create the provisioner with:

	$ kubectl create -n kube-system -f management/storage/ceph/cephfs-provisioner.yaml



## Create a CEPHFS StorageClass

Edit the file cephfs-storageclass.yaml and create the storageClass with:

	$ kubectl create -f management/storage/ceph/cephfs-storageclass.yaml

		
# Volume Claim Example 

The following is an example how to create a volume claim for the CephFS within a pod.

volumeclaim.yaml:

	kind: PersistentVolumeClaim
	apiVersion: v1
	metadata:
	  name: mydata
	#  namespace: cephfs
	spec:
	  storageClassName: cephfs
	  accessModes:
	    - ReadWriteMany
	  resources:
	    requests:
	      storage: 1Gi


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
	        volumeMounts:
	        - mountPath: /var/lib/myapp/data
	          name: mydata
	      restartPolicy: Always
	      volumes:
	      - name: mydata
	        persistentVolumeClaim:
	          claimName: mydata
	....

	
	
	
	