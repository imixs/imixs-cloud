# Monitoring

The *Imixs-Cloud* monitoring is based on the [Prometheus Operator project](https://github.com/prometheus-operator/prometheus-operator).
All metrics collected form the Imixs-Cloud kubernetes cluster can be monitored in a [Grafana](https://grafana.com/) dashboard.

## The Prometheus Operator

The [Prometheus Operator project](https://github.com/prometheus-operator/prometheus-operator) provides Kubernetes native deployment and management of Prometheus and related monitoring components. The purpose of the project is to simplify and automate the configuration of a Prometheus based monitoring stack for Kubernetes clusters.

## Kube Prometheus

Based on Prometheus Operator the project [kube-prometheus](https://github.com/prometheus-operator/kube-prometheus) provides example configurations for a complete cluster monitoring stack. 
The goal of *kube prometheus* is to simplify the deployment and configuration of Prometheus, Alertmanager, and related monitoring components. 
The *Imixs-Cloud* monitoring is based on the latest version of the *kube-prometheus* so no additional configuration is need here.



## Deployment

*kube prometheus* is intended to be used as a library. So all you need to do is to checkout the project form github on your master-node.

	
	# Checkout the project form Github
	$ cd
	$ git clone https://github.com/prometheus-operator/kube-prometheus.git
	$ cd kube-prometheus
	# Create the namespace and CRDs, and then wait for them to be availble before creating the remaining resources
	$ kubectl create -f manifests/setup
	$ until kubectl get servicemonitors --all-namespaces ; do date; sleep 1; echo ""; done
	$ kubectl create -f manifests/



## Ingress

To access the grafana dashboard from your Internet domain you can use the traefik reverse proxy configured in *Imixs-Cloud*. Just edit the file *imixs-cloud-ingress.yaml* and replace [YOUR-DNS-NAME] whit the name of you monitoring Internet domain name. 

To apply the ingress configuration run:

	$ kubectl apply -f imixs-cloud-ingress.yaml

## Grafana Boards

The  *kube prometheus*  project provide a large number of Grafana dashboards which can be access from the dashboard configuration page.
