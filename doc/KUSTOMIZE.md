# Kustomize Deployments

[Kustomize](https://kubernetes.io/docs/tasks/manage-kubernetes-objects/kustomization/) is a tool that allows you to customize Kubernetes resources through a *kustomization.yaml* file and overlay folders. This tool is integrated in the *kubectl* command-line-tool of Kubernetes, so there is no need for a extra installation.

The following section gives you a brief an simple introduction about how to use Kustomize. You can find more details on the [Kubernetes page](https://kubernetes.io/docs/tasks/manage-kubernetes-objects/kustomization/). 
 

## Create a kustomization.yaml

Fist of all you need to setup a deployment configuration using the yaml files as usual. This is called the *base-deployment* of your service or application. 

By creating the file *kustomization.yaml* you define the resources used by Kustomize. 
This file simply defines all resources to be part of your base-deployment. In the following example the application consist of a 010-deployment.yaml and a 020-service.yaml file:

	resources:
	  - 010-deployment.yaml
	  - 020-service.yaml

With the help of the file *kustomization.yaml* you can now apply your base-deployment with:

	$ kubectl apply --kustomize ./apps/my-app/

## Create a Overlay Configuration

With Kustomize you can now easily create an overlay with custom settings of each base-deployment. 
Each overlay is defined by a custom sub-folder like /apps/my-app/prod/ containing at least a separate kustomization.yaml file. See the following example:

	# Add a new namespace to all resources
	namespace: my-custom-namespace
	
	# The base directory
	bases:
	- ../../my-app

The kustomization.yaml file defines a namespace for your new custom deployment and points into the base directory with the origin configuration. The base directory can also be a web address from a public github repository like:

	
	...
	bases:
	- https://github.com/imixs/imixs-documents/kubernetes/
	....


You can also add additional resources to be added or merged into the base configuration

	....
	resources:
	- 090-ingress.yaml
	
	patchesStrategicMerge:
	- 020-volumes.yaml
	.....

Now you have the following directory structure:


	├── my-app/
	│   ├── 010-deployment.yaml
	│   ├── 020-service.yaml
	│   ├── kustomization.yaml
	│   ├── prod/
	│   │   └── kustomization.yaml

To deploy your overlay run:

	$ kubectl apply --kustomize ./apps/my-app/prod

This will result in a new deployment but within the namespace ‘my-custom-namespace’ defined in the kustomization.yaml.

## Overwriting Settings

You can add any junk of yaml files into an overlay folder to overwrite settings of your base-deployment. In the kustomization.yaml file you specify the path to a yaml file to be merged into the base-deployment.

For example you want to change an environment variable to your deployment, add a new file named custom-env.yaml with the new setting:

	apiVersion: apps/v1
	kind: Deployment
	metadata:
	  name: my-app
	spec:
	  template:
	    spec:
	      containers:
	        - name: app
	          env:
	            - name: CUSTOM_ENV_VARIABLE
	              value: some-value

Merge the new junk yaml file with the option patchesStategicMerge in your /prod/kustomization.yaml file:

	# Add a new namespace to all resources
	namespace: my-custom-namespace
	
	# The base directory
	bases:
	- ../../base
	
	# Patches
	patchesStrategicMerge:
	- custom-env.yaml

This will add the new ‘CUSTOM_ENV_VARIABLE’ with the value ‘some-value’ to the deployment of ‘my-app’.

**Note:** Specify always the full path of the resource setting you want to change.


## Add New Resource Objects

Another way to customize the deployment is adding new resources. You can add additional deployment resources with the *resource* option in the kustomization.yaml.yaml file. See the following example:

	# Add a new namespace to all resources
	namespace: my-custom-namespace
	
	# The base directory
	bases:
	- ../../base
	
	# Additional resources
	resources:
	- 090-ingress.yaml
	
	# Patches
	patchesStrategicMerge:
	- custom-env.yaml

This example will add a new resource ‘090-ingress.yaml‘ to the base-deployment.


## namePrefix

The option *namePrefix* can be defined in a kustomization.yaml file to prepend  a value to the names of all resources used in your base-deployment:

	namePrefix: alices-

This example will change a deployment named "wordpress" into "alices-wordpress".


## nameSuffix

The option *nameSuffix* can be defined in a kustomization.yaml file to append a value to the names of all resources used in your base-deployment:

	nameSuffix: -v2

This example will change a deployment named "wordpress" into "wordpress-v2".

 
## Labels

Custom Labels can be added to all resources and selectors:

	commonLabels:
	  storageType: durable

This example will add the label 'storageType' with the value 'durable' to all resources and selectors.   
  
 
 