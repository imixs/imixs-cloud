# GitOps with Argo CD

Argo CD is a declarative, GitOps continuous delivery tool for Kubernetes. We use Argo CD within Imixs-Cloud to provide a convenient way to control application definitions, configurations, and environments in a declarative way. The Imixs-Cloud project already provide the core concept of *Infrastructure as Code*. All objects are provided in a root git repository:

	/-
	 |+ management/
	    |- monitoring/
	    |- registry/
	    |- nginx/
	 |+ apps/
	    |+ MY-APP/
	       |  001-deployment.yaml
	    .....

So with adding Argo CD you extend the way to control all your applications running with Imixs-Cloud.

## Quick Setup

For a quick setup check the directory */management/arco-cd*.  This directoy includes kustomize configuration including an ingress configuration based on the [ingress-nginx controller](./INGRESS.md).


	$ kubectl create namespace argocd
	$ kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml
	
In the official [Getting Started Guide](https://argo-cd.readthedocs.io/en/stable/getting_started/) of the Argo CD project you will find additional information.


### The Ingress Configuration

For the Ingress configuration edit the file '030-ingress.yaml' and replace '{YOUR-DOMAIN-NAME}' with your Internet domain name.

Next deploy the Ingress configuration with:

	$ kubectl apply -f management/argo-cd/030-ingress.yaml

### First Login

For the first login argo-cd generates a random password for the user 'admin'. The password can be retrieved with the command:

	$ kubectl get pods -n argocd -l app.kubernetes.io/name=argocd-server -o name | cut -d'/' -f 2

Using the username admin and the password from above, you can login to Argo CD's Web UI.

<img src="images/argocd-001.png" />





