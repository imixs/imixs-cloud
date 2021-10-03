# CEPH


[Ceph](https://ceph.io/) provides an object storage and block device interface and also a traditional file system interface with POSIX semantics. This makes it a powerful storage solution for Kuberentes. In the *Imixs-Cloud* environment we are using the [Ceph CSI-Plugin](https://github.com/ceph/ceph-csi) to access a Ceph cluster.

It is recommended to run a Ceph cluster independent from Kuberenetes on separate nodes. In this architecture you run the ceph monitor nodes in a public network and use only a private network for the internal replication:

<img src="images/ceph-network-768x354.png" />

This allows access form different Kubernetes clusters and makes the handling more easily. 

## Installation

The installation of the latest Ceph pacific release is quite simple using the *cephadm tool*. The official installation guide how to bootstrap a new Ceph cluster can be found [here](https://docs.ceph.com/en/pacific/cephadm/install). Also take a look on the installation tutorial for Debian Bullsey [here](https://ralph.blog.imixs.com/2021/10/03/ceph-pacific-running-on-debian-11-bullseye/).

### Ceph CSI Plugin

After your Ceph Cluster is up and running you can install the Ceph CSI Plugin to access the cluster from your *Imixs-Cloud* environment.

Follow the setup guide [here](../management/ceph/README.md).

 