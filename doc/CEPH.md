# Ceph - Quick Install Guide

In this section you will find a Quick Install Guide for a Ceph cluster. [Ceph](https://ceph.io/) provides an distributed object storage and block device interface. This makes it a powerful storage solution for Kubernetes. In the *Imixs-Cloud* environment we are using the [Ceph CSI-Plugin](https://github.com/ceph/ceph-csi) to access a Ceph cluster. If you already have a Ceph cluster up and running and you just want to connect it to your Kubernetes Cluster, than you may jump directly to the management section [ceph-csi plugin](../management/ceph/README.md).

## Architecture

It is recommended to run a Ceph cluster independent from Kubernetes on separate nodes. In this architecture you run the ceph monitor nodes in a public network and use only a private network for the internal replication, as it is recommended from the official ceph install guide:

<img src="images/ceph-network-768x354.png" />

This allows access form different Kubernetes clusters and makes the handling more flexible and independent from your Kubernetes cluster. 

## Installation

The installation of the latest Ceph pacific release is quite simple using the *cephadm tool*. The official installation guide how to bootstrap a new Ceph cluster can be found [here](https://docs.ceph.com/en/pacific/cephadm/install). Also take a look on the installation tutorial for Debian Bullsey [here](https://ralph.blog.imixs.com/2021/10/03/ceph-pacific-running-on-debian-11-bullseye/). In the following we will give a Quick Guide how to setup a public Ceph cluster



### Network

In the following setup we assume that your ceph nodes are accessible form the Internet as we want to connect our Kubernetes Cluster. Of course you can also use a private Network instead. In most tutorials it is recommended that your Ceph cluster has at least one private Network for the internal OSD communication. The OSD is the core of a Ceph cluster and responsible to replicate your data amongst different nodes. But note: a second private network makes only sense if is notedly faster than your public network. If you do not have a separate network adapter in your hardware you can run your cluster also only with a public network. You just need to take care about firewall settings (see below). 

In the following example we asume that you have a private Network 1.0.0.0/24 with 3 nodes. Also each node has its own public IP address to connect your Kubernetes clients. 

	Hostname	FQDN		Public IP	Private IP
	node1 		node1.foo.com	x.y.a.b		10.0.0.2
	node2 		node2.foo.com	x.y.a.c		10.0.0.3
	node3 		node3.foo.com	x.y.a.d		10.0.0.4

For a correct setup make sure that you can ping each of your cluster nodes by the hostname and the FQDN from each node in your ceph cluster. The hostname sould resolve the private network address. The FQDN the public address. You may need to update your /etc/hosts on each node separately, which should look something like this:

	127.0.0.1	localhost
	127.0.1.1	node1.foo.com node1
	10.0.0.3	node2
	10.0.0.4	node3
	x.y.a.c		node2.foo.com
	x.y.a.d		node3.foo.com

The hostname for the current node is set to the loopback address 127.0.1.1.The private address for each cluster node is set to short hostname within the private network, and the full qualified domain name (FQDN) is set to its public IP. The later is to avoid failures form unreachable DNS services. See also details [here](https://docs.ceph.com/en/pacific/cephadm/host-management/#fully-qualified-domain-names-vs-bare-host-names)


### Installing Ceph

When your Network is ready make sure your have an unprivileged user as you should not run the install script as root. 
We provide a setup Script for Ceph running in Debian 11 (Bullseye) located under `/management/ceph/scripts/ceph_setup.sh`.

Run the Script on each node with sudo rights:

	$ sudo ./ceph_setup.sh

The script will install the cephadm tool and the Docker runtime. 	



### Bootstrap Your Cluster

Now as you have prepared your nodes, you can bootstrap your cluster by starting on the first node (in this example this is node1).

	$ sudo cephadm bootstrap --mon-ip <PUBLIC-IP> --initial-dashboard-user admin --initial-dashboard-password YOURPASSWORD --dashboard-password-noupdate --skip-mon-network

Replace `<PUBLIC-IP>` with the public IP address of your first manager node within your cluster (node1). The password you give here is used for the Web Admin Dashboard.

The cephadmin tool starts now downloading the docker images to startup a minimal Ceph cluster in docker. The command will take some seconds. When it finished, it will print out the access URL for the dashboard::

	INFO:cephadm:Ceph Dashboard is now available at:

             URL: https://node1:8443/
            User: admin
        Password: 07jab2z550

	INFO:cephadm:You can access the Ceph CLI with:

        sudo ./cephadm shell --fsid 2d2fd136-6df1-11ea-ae74-002590e526e8 -c /etc/ceph/ceph.conf -k /etc/ceph/ceph.client.admin.keyring

	INFO:cephadm:Bootstrap complete.


Finally set now internal cluster network for your new ceph cluster from the cephadm shell:

	# sudo ceph config set mon cluster_network 10.0.0.0/16

### The Dashboard

You can do a first check of your setup via web browser:

	https://<your-pulic-ip>:8443/
	
<img src="./images/ceph-setup-web-ui-001-768x481.png" />	

Use the admin password you have passed in your bootstrap command.

At this moment your cluster is still not ready as it only consists of one node without any data volumes. So the next step is to expand your cluster.
Expending the Cluster

You can expand your cluster by adding additional nodes and providing object storage devices (OSD). At least your ceph cluster should have 3 nodes.

### Sharing the Ceph SSK Key

Before you can add a new node to your cluster, you need to copy the ceph ssh key from your manager node into each new server. This key is needed so that cephadm can proceed the setup on the new host. From the root of your first node (node1) run:

	$ ssh-copy-id -f -i /etc/ceph/ceph.pub root@node2

This will copy the public ceph key from your manager node (node1) into the new server node (node2) . You will be asked for the root password on your new host to perform this command. After this you can now add the new node:

	$ sudo ceph orch host add node2

**Note:** It takes some time until the new node is visible from your manager node. So don’t be to impatient. Wait 1-5 minutes.

You can repeat the same steps with your third cluster node.

### Add Monitors

Ceph monitors (mon) are connected from your clients to access the ceph data. It is recommend to deploy monitors on each of your nodes in your cluster. As we want to access the monitors via the public network we disable the automated monitor deployment and label all nodes with the lable ‘mon’ to indicate them as monitor nodes:

	$ sudo ceph orch apply mon --unmanaged
	$ sudo ceph orch host label add node1 mon 
	$ sudo ceph orch host label add node2 mon 
	$ sudo ceph orch host label add node3 mon 

Next add each monitor with its public IP to the ceph cluster:

	$ sudo ceph orch daemon add mon node2:<PUBLIC-IP>
	$ sudo ceph orch daemon add mon node3:<PUBLIC-IP>

Replace <PUBLIC-IP> with the public IP address of your node. Repeat this setup for each node. You should have now at least 3 monitors.

**Note:** In this setup, using public Internet IPs, you must **not** set the ceph into the managed mode with `ceph orch apply mon 3`, because in this mode, ceph tries to place the monitors automatically into the private network which will not make sense.

Now you can verify the status of your cluster in parallel from the Ceph Web UI

<img src="./images/ceph-setup-web-ui-002-768x377.png" />	

### Adding Storage

Finally you need to add the Object Store Devices ( OSDs) to the Ceph cluster. **Note:** Each OSD on a node is a separate hard disc which is NOT mounted!

You can check the status of available hard discs via the Web dashboard or you can list the current status of available devices with the following ceph command:

	$ sudo ceph orch device ls
	Hostname      Path      Type  Serial    Size   Health   Ident  Fault  Available  
	node-1  /dev/sdb  hdd   11680847  21.4G  Unknown  N/A    N/A    No         
	node-2  /dev/sdb  hdd   11680881  21.4G  Unknown  N/A    N/A    Yes        
	node-3  /dev/sdb  hdd   11680893  21.4G  Unknown  N/A    N/A    Yes

To add a device of a cluster node run:

	$ sudo ceph orch daemon add osd [node1]:/dev/[sdb]

Replace [node1] with the name of you node and [sdb] with the corresponding device on your cluster node. In the following example I am adding the sdb of node2 into my ceph cluster:

	$ sudo ceph orch daemon add osd node2:/dev/sdb
	Created osd(s) 0 on host 'node2'

### Verify Cluster Status

Adding new disks may take some while. You can verify the status of your cluster with the ceph command:

	$ sudo ceph status
	  cluster:
	    id:     5ba20356-7e36-11ea-90ca-9644443f30b
	    health: HEALTH_OK
	 
	  services:
	    mon: 1 daemons, quorum node1 (age 2h)
	    mgr: node1.zknaku(active, since 2h), standbys: node2.xbjpdi
	    osd: 3 osds: 3 up (since 100m), 3 in (since 100m)
	 
	  data:
	    pools:   2 pools, 33 pgs
	    objects: 2 objects, 0 B
	    usage:   3.0 GiB used, 117 GiB / 120 GiB avail
	    pgs:     33 active+clean

Now finally also in the web dashboard the cluster status should now indicate ‘HEALTH_OK:


<img src="./images/ceph-setup-web-ui-003-768x383.png" />


### Using cephadmin on Additional Nodes

After bootstrapping the ceph cluster the cephadm tool can only be used from the first node. If something went wrong with this node it may be necessary to use the cephadm tool also from the other nodes.

To install the cephadm tool an a second ceph node you need to share the ceph ssh keys. First create the /ect/ceph directory on the second node

	$ sudo mkdir /etc/ceph

Next copy the ceph.* files from your bootstrap node to the second node:

	$ sudo scp /etc/ceph/ceph.* root@node2:/etc/ceph

Now you can install the cephadm tool on the second node as done on the first node before using the install script.


## Firewall Setup

As explained in the beginning my ceph nodes are available on public internet addresses. This requires some security considerations. We want to avoid that unauthorized users can access our cluster.

Ceph includes additional monitoring services like prometheus and grafana used for internal monitoring and alerting. And these service are also available on the public network.

    Grafana -> https://<PUBLIC-IP>:3000
    Prometheus -> http://<PUBLIC-IP>:9095

Unfortunately, these services allow untrusted users access per default. As our setup is available via Internet it is necessary to protect this. The necessary ports to be opened are:

    22 – SSH
    6789 – Ceph Monitor Daemon
    10.0.0.0/16 allow all from private network 

To protect the ceph cluster nodes we can use the firewall tool *ufw*. You should familiarize yourself with the ufw tool to prevent you from locking yourself out of your server.

To enable the firewall with *ufw* you can use the script *setup_ufw.sh* also located in the management/ceph/scripts/ directory

You need to edit the script frist and add your public IPs from your Kubernetes Nodes. Then your can activate the firewall rules on each node:

	$ sudo ./setup_ufw.sh

Repeat the step on each node. 

To disable the firewall run:

	$ sudo ufw disable



## Ceph CSI Plugin

After your Ceph Cluster is up and running you can install the Ceph CSI Plugin to access the cluster from your *Imixs-Cloud* environment.

Follow the setup guide for the Ceph CSI Plugin [here](../management/ceph/README.md).

 