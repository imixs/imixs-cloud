# Ceph Pool

The templates here are used to define a ceph storage class.

## Create the RBD provisioner

Create the provisioner with:

	$ kubectl create -n kube-system -f rbd-provisioner.yaml 

	
### Admin Secret

With the following command you can get the ceph admin key out from one of your ceph nodes:

	$ sudo ssh node1 ceph auth get-key client.admin
	ABCyWw9dOUm/FhABBK0A9PXkPo6+OXpOj9N2ZQ==

Copy the key and create a kubernetes secret named ‘ceph-secret’:

	 $ kubectl create secret generic ceph-secret \
	    --type="kubernetes.io/rbd" \
	    --from-literal=key='ABCyWw9dOUm/FhABBK0A9PXkPo6+OXpOj9N2ZQ==' \
	    --namespace=kube-system
	secret/ceph-secret created	
	
### Create a Ceph Pool and a User Key

Create a separate Ceph pool for Kubernetes:

	$ sudo ssh node-1 ceph --cluster ceph osd pool create kube 16 16
	pool 'kube' created

For this new pool you can create a user key:

	sudo ssh node-1 "ceph auth get-or-create client.kube mon 'allow r' osd 'allow rwx pool=kube'"
	[client.kube]
		key = CDEgU1BeVMyDJxAA7+ufUoqTdvmZUUR8tJeGnEg==

create a separate kubernetes secret for this user:

	$ kubectl create secret generic ceph-secret-kube \
	    --type="kubernetes.io/rbd" \
	    --from-literal=key='ABCyWw9dOUm/FhABBK0A9PXkPo6+OXpOj9N2ZQ==' \
	    --namespace=kube-system

Both kubernetes secrets ‘ceph-secret’ and ‘ceph-secret-kube’ are used for the StorageClass yaml file!



### Create a RBD StorageClass

Edit the file pool-1-storageclass.yaml and create the storageClass with:

	$ kubectl create -n kube-system -f pool-1-storageclass.yaml 
	
	
	
	
## Create the CEPHFS provisioner


Create the dedicated namespace for CephFS

	$ kubectl create ns cephfs


With the following command you can get the ceph admin key out from one of your ceph nodes:

	$ sudo ssh node1 ceph auth get-key client.admin
	ABCyWw9dOUm/FhABBK0A9PXkPo6+OXpOj9N2ZQ==

Copy the key and create a kubernetes secret named ‘ceph-secret’:

	 $ kubectl create secret generic ceph-secret-admin \
	    --from-literal=key='ABCyWw9dOUm/FhABBK0A9PXkPo6+OXpOj9N2ZQ==' \
	    --namespace=cephfs
	secret/ceph-secret created	
	
Create the provisioner with:

	$ kubectl create -n cephfs -f cephfs-provisioner.yaml



### Create a CEPHFS StorageClass

Edit the file cephfs-storageclass.yaml and create the storageClass with:

	$ kubectl create -f cephfs-storageclass.yaml 
	
		
	