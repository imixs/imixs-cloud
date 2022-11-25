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

	$ kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d; echo
	