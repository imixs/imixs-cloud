# Storrage

To run statefull docker images (e.g. a Database like PostgreSQL) you have two choices.

 - run the service on a dedicated node - this avoids the lost of data if kubernetes re-schedules your server to another node
 - use a ceph or glusterfs storrage 
 

# Gluster

Gluster is a scalable network filesystem. This allows you to create a large, distributed storage solution on common hard ware. You can connect a gluster storage to Kubernetes to abstract the volume from your services. 

## Install

You can install Glusterfs on any node this includes the kubernetes worker nodes. 

The following guide explains how to intall Glusterfs on Debian 9. You will find more information about insallation [here](https://docs.gluster.org/en/latest/Install-Guide/Overview/).

 
Run the following commands as root:

	$ su
	
	# Add the GPG key to apt:
	$ wget -O - https://download.gluster.org/pub/gluster/glusterfs/7/rsa.pub | apt-key add -
	
	# Add the source (s/amd64/arm64/ as necessary):	
    $ echo deb [arch=amd64] https://download.gluster.org/pub/gluster/glusterfs/7/LATEST/Debian/stretch/amd64/apt stretch main > /etc/apt/sources.list.d/gluster.list
    
    # Install...
    $ apt-get update
    $ apt-get install glusterfs-server
	
	
To test the gluster status run:

	$ service glusterd status	
	
Repeat this installation on each node you wish to joing your gluster network storrage.


## Setup Gluster Network

Now you can check form one of your gluster nodes if you can reach each other node


	$ gluster peer probe [gluster-node-ip]

where 	gluster-node-ip is the IP Adress or the DNS name of one of your gluster nodes.

Now you can check the peer status on each node:

	$ gluster peer status
	Uuid: vvvv-qqq-zzz-yyyyy-xxxxx
	State: Peer in Cluster (Connected)
	Other names:
	[YOUR-GLUSTER-NODE-NAME]

	
## Setup a Volume

Now you can set up a GlusterFS volume. For that create a data volume on all servers:

	$ mkdir -p /data/glusterfs/brick1/gv0

From any single worker node run:

	$ gluster volume create gv0 replica 2 [GLUSTER-NODE1]:/data/glusterfs/brick1/gv0 [GLUSTER-NODE2]:/data/glusterfs/brick1/gv0
	volume create: gv0: success: please start the volume to access data

replace [GLUSTER-NODE1] with the gluster node dns name or ip address. 

**Note:** the directory must not be on the root partition. At leaset you should provide 3 gluster nodes. 

Now you can start your new volume 'gv0': 


	$ gluster volume start gv0
	volume start: gv0: success

With the following command you can check the status of the new volume:

	$ gluster volume info
	
Find more about the setup [here}(https://docs.gluster.org/en/latest/Quick-Start-Guide/Quickstart/).


 	
# Kubernetes


	