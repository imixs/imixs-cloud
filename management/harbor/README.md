# Harbor

[Harbor](https://goharbor.io/) is a secure, performant, scalable, and available cloud native repository for Kubernetes. It can be installed using the *helm* tool. Find more information in the [Harbor Setup Guide](../../doc/REGISTRY.md).

## Installation

Harbor consists of several services. To make it easy to install Harbor the right way you can use `helm`. If you have not yet installed helm, follow the install guide [here](../tools/helm/README.md)

### Add the harbor helm repository

First add the Helm repository for Harbor

	$ helm repo add harbor https://helm.goharbor.io

Now you can install Harbor using the corresponding chart. 


### Install Harbor 

The Harbor Helm chart comes with a lot of parameters which can be applied during installation using the values.yaml file. See the [Harbor Helm Installer](https://github.com/goharbor/harbor-helm) for more information.

The file 'values.yaml' contains a setup to expose harbor via the NGINX Ingress Controller into the *Imixs-Cloud*. You can customize the settings in this file. Replace{YOUR-DOMAIN-NAME} with your Internet domain name Harbor should be exposed.

If you have setup the values.yaml file install Harbor with the following command:

	$ helm install -f management/harbor/values.yaml registry harbor/harbor -n harbor --namespace harbor

The deployment may take some seconds. After installation you can access the Harbor Web UI from your web browser. 

	https://{YOUR-DOMAIN-NAME}

The default password for the user 'admin' is 'Harbor12345. 

Harbor gives you beside the ingress configuration a lot of additional configuration options. You can find all possible settings for the helm chart in the file 'values-full.yaml'


### Ingress NGINX

The ingress configuration is defined in the values.yaml file by the expose type 'ingress'. Replace {YOUR-DOMAIN-NAME} with your Internet domain name. 

	....
	expose:
	  type: ingress
	  # NGINX Ingress confiugration
	  ingress:
	    hosts:
	      core: "{YOUR-DOMAIN-NAME}"
	    annotations:
	      ingress.kubernetes.io/ssl-redirect: "true"
	      ingress.kubernetes.io/proxy-body-size: "0"
	      nginx.ingress.kubernetes.io/ssl-redirect: "true"
	      nginx.ingress.kubernetes.io/proxy-body-size: "0"
	      # choose letsencrypt-staging or letsencrypt-prod
	      cert-manager.io/cluster-issuer: "letsencrypt-staging"
	      # To be used for the nginx ingress on AKS:
	      #kubernetes.io/ingress.class: nginx
	  tls:
	    enabled: true
	    certSource: secret
	    secret: 
	      secretName: "tls-harbor"
	
	# The external URL for Harbor core service.
	externalURL: "https://{YOUR-DOMAIN-NAME}"
	....

Note that you can switch betwen the Let's Encrypt staging server or the prod server. 
Read the section [NGINX](../nginx/README.md) for more information about the Ingress NGINX Controller used in *Imixs-Cloud*.
	
	
	
### Persistence Volumes

Harbor will automatically create data volumes using the Longhorn default storage class. The volumes will not be deleted until you delete the namespace 'harbor'. So even after a undeploy and redeploy your data is available.

	...
	persistence:
	  enabled: true
	  # Setting it to "keep" to avoid removing PVCs during a helm delete
	  # operation. Leaving it empty will delete PVCs after the chart deleted
	  # (this does not apply for PVCs that are created for internal database
	  # and redis components, i.e. they are never deleted automatically)
	  resourcePolicy: "keep"
	...  

You can ignore the persistence of data by setting the 'persistence.enabled' flag in the values.yaml file to 'false:

	...
	persistence:
	  enabled: false
	...
	

### Disable Scanners

The harbor scanners are useful to scan docker images for vulnerability. But these services also generates a lot of CPU load. If you want to start Harbor with a minimum of features you can disable the scanners in the values.yaml file

	....
	notary:
	  enabled: false
	trivy:
	  enabled: false
	clair:
	  enabled: false
	chartmuseum:
	  enabled: false
	persistence:
	  enabled: false
	....



### Upgrade Harbor

Before you upgrade harbor make sure that you have backuped your data. 

Than run:

	$ helm repo update
	$ helm upgrade registry harbor/harbor -f management/harbor/values.yaml -n harbor


### Uninstall Harbor	

To uninstall/delete the registry deployment:

	$ helm uninstall registry --namespace harbor	
	
Finally remove the namespace

	$ kubectl delete namespace harbor	