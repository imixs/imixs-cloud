# Testing

These are some test deployments for a filesystem storage volume and a blocks torage volume

Test a persistence volume with a filesystem:

	$ kubectl apply -f management/ceph/testing/010-filesystem-test.yaml

Test a persistence volume with a block storage:

	$ kubectl apply -f management/ceph/testing/010-blockstorage-test.yaml



		