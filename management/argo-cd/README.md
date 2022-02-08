# Deployment

For a quick setup we use the official install.yaml file form the argo-cd github page. 

	$ kubectl create namespace argocd
	$ kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml
	
In the official [Getting Started Guide](https://argo-cd.readthedocs.io/en/stable/getting_started/) of the Argo CD project you will find additional information.


## The Ingress Configuration

For the Ingress configuration edit the file '030-ingress.yaml' and replace '{YOUR-DOMAIN-NAME}' with your Internet domain name.

Next deploy the Ingress configuration with:

	$ kubectl apply -f management/argo-cd/030-ingress.yaml

	