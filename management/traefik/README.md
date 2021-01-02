# Traefik.io

[traefik.io](http://traefik.io) is a reverse proxy and load balancer to be used within a kubernetes cluster. 




## Configuration

To deploy traefik.io within the imixs-cloud first edit the following files 

#### management/traefik/020-deployment.yaml

replace *{YOUR-E-MAIL}* with a valid email address 

replace *{MASTER-NODE-IP}* with the ip address of your master node.

#### management/traefik/030-ingress.yaml
 
replace *{YOUR-HOST-NAME}* with a Internet name pointing to your Master Node configured in your DNS 

## Deployment

To deploy traefik into your Kubernetes Cluster run:

	$ kubectl apply -f management/traefik/010-crd_rbac.yaml
	$ kubectl apply -f management/traefik/020-deployment.yaml
	$ kubectl apply -f management/traefik/030-ingress.yaml
	
to undeploy traefik.io run:

	$ kubectl delete -f management/traefik/

For further information reed the documentation section [Ingress Configuration with Traefik.io](../../INGRESS.md)


## The Let's Encrypt Stating Servier

For testing the ACME provider runs on a staging server.

	https://acme-staging-v02.api.letsencrypt.org/directory

You can comment the ACM Staging server from the Let's Encrypt setup section in the file *002-deployment.yaml* after you have tested your cluster setup. 

## Persistence Volume for acme.json 

Optional you can add a persistence volume for the acme.json file. This is recommended to avoid running into the rate limits from let's Encrypt. The persistence volume is durability even if you delete/recreate the traefik deployment

To apply the persistence volume you first need to create a volume named 'traefik-data' in longhorn 

Next uncomment the volumeMounts in the 002-deployment.yaml file

	.....
        # optional storage 
        # enable this option only in case you have defined a persistence volume claim
        volumeMounts:
        - name: traefik-data
          mountPath: /var/lib/traefik
        ....
      ....
      # optional storage
      # enable this option only in case you have defined a persistence volume claim
      volumes:
        - name: traefik-data
          persistentVolumeClaim:
            claimName: traefik-data  
      .....      
        	
Finally you can apply the persitence volume

	$ kubectl apply -f management/traefik/011-persistencevolume.yaml
	$ kubectl apply -f management/traefik/020-deployment.yaml


**Note:** The Longhorn UI depends on Traefik. So you should first disable the persistence volume and start with the Let's Encrypt Staging provider. From this point you can create the persistence volume for traefik in the longhorn-ui. After that you an activate the persistence volume for traefik. Otherwise the deployment will fail because treafik is unable to resolove the volume-claim defined in the *004-persistencevolume.yaml* file.