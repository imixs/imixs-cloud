# Concourse

## Generate Keys

Concourse needs a set of key files to securely exchange data between the client and the worker nodes.
You can create the keys using the official Concourse Docker containers. 

	
	$ sudo ./management/cicd/generate_keys.sh
	

Use the contents of the keys directory with kubectl to create configmap concourse-config :


	$ kubectl create namespace cicd
	$ kubectl create configmap concourse-config --from-file=./keys -n cicd
	
This config map will be mounted in the Concourse deployment.yaml file


## Deployment: 

After you have created the config-map you can deploy Concourse:

	$ kubectl apply -f management/cicd/
	

For more information see the [documentation](https://github.com/imixs/imixs-cloud/blob/master/doc/CICD.md).
	