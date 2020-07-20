# Imixs-Cloud - CI/CD

Continous Integration (CI) and Continous Delivery (CD) are important building blocks for a cloud environment.
The open source project [Concourse](https://concourse-ci.org/) provides a simple mechanic to manage resources, tasks, and jobs and presents a general approach to automation.



## Installation

The installation constist of two parts. 

 - Installation of the concourse server and worker nodes
 - Installation of the command line tool fly
 
Details about the installation can be found in the official [installation guide](https://concourse-ci.org/install.html).

### Generate Keys

Concourse needs a set of key files to securely exchange data between the client and the worker nodes.
You can create the keys using the official concourse Docker containers. 

	
	$ sudo ./management/cicd/generate_keys.sh
	

Use the contents of the keys directory with kubectl to create configmap concourse-config :


	$ kubectl create namespace cicd
	$ kubectl create configmap concourse-config --from-file=./management/cicd/keys -n cicd
	
This config map will be mounted in the concourse.yaml deployment file


## Deployment: 

Concourse comes with a web interface so you can integrate this interface with traefik. Just replace {YOUR-HOST-NAME} in the 002-deployment.yaml and 002-ingress.yaml file with our domain name.

Next you can start the deployment:

	$ kubectl apply -f management/cicd.imixs.com/
	
	