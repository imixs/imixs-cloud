# Deployment

For a quick setup we use the official install.yaml file form the argo-cd github page. 

	$ kubectl create namespace argocd
	$ kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml
	
In the official [Getting Started Guide](https://argo-cd.readthedocs.io/en/stable/getting_started/) of the Argo CD project you will find additional information.


## The Ingress Configuration

For the Ingress configuration edit the file '030-ingress.yaml' and replace '{YOUR-DOMAIN-NAME}' with your Internet domain name.

Next deploy the Ingress configuration with:

	$ kubectl apply -f management/argo-cd/030-ingress.yaml

For the login argo-cd generates a random password for the user 'admin'. The password can be retrieved with the command:

	$ kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d



## First Login

For the first  login argo-cd generates a random password for the user 'admin'. The password can be retrieved with the command:

	$ kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d; echo
	

## SSH Git Repos

To allow argo-cd to access a private git repos you need a SSH key. 
To create a modern ssh key with Ed25519 the algorithm you can run the following command on your master node:

	$ mkdir -p management/argo-cd/.ssh
	$ ssh-keygen -t ed25519 -C "gitops@imixs.com" -f management/argo-cd/.ssh/id_ed25519

Do not enter a password, as the login need to be password less. 
The new keys will be copied into the directory:  

	management/argo-cd/.ssh

Before argo-cd is allowed to access our Git repo, you need to manually transfer the public key to your git server. For example with the `ssh-copy-id` command: 

	$ ssh-copy-id -f -i management/argo-cd/.ssh/id_ed25519.pub git@<YOUR-GIT-SERVER>
	
The key will be copied into your git server in the file  `~/.ssh/authorized_keys` 

After that, you can now connect your Git repository via the argo-cd Web UI by creating a new SSH connection in the Web UI with 

	name: <YOUR-GIT-SERVER>
	project: default
	repo URL: ssh://git@<YOUR-GIT-SERVER>/<YOUR-REPO>
	SSH Private key : .......copy the private Key from management/argo-cd/.ssh/.............
	Skip server verification : YES
