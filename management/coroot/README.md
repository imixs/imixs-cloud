# Coroot Monitoring

[Coroot](https://coroot.com) is an open-source observability platform based on eBPF.
It provides metrics, logs, traces, and profiles without any code changes to your applications.

We use the **Community Edition** which is fully self-hosted with no external cloud connections.

## Prerequisites

- Kubernetes cluster with Helm installed
- nginx Ingress Controller
- cert-manager with a ClusterIssuer `letsencrypt-prod`
- A StorageClass providing RWO volumes (e.g. Ceph RBD)

## Installation

### 1. Add Helm Repository

```bash
helm repo add coroot https://coroot.github.io/helm-charts
helm repo update
```

### 2. Install the Coroot Operator

The Coroot Operator must be installed first as it provides the required CRDs:

```bash
helm install -n coroot coroot-operator coroot/coroot-operator \
  --create-namespace
```

### 3. Adapt values.yaml

Copy `values.yaml` and replace the following placeholders with your own values:

| Placeholder            | Description                                                |
| ---------------------- | ---------------------------------------------------------- |
| `YOUR_STORAGE_CLASS`   | Name of your StorageClass (e.g. `ceph-ssd`)                |
| `YOUR_MONITORING_HOST` | Hostname for the Coroot UI (e.g. `monitoring.example.com`) |

### 4. Adapt ingress.yaml

Replace `YOUR_MONITORING_HOST` in `ingress.yaml` with your hostname.

### 5. Install Coroot Community Edition

```bash
helm upgrade --install -n coroot coroot coroot/coroot-ce \
  -f values.yaml
```

### 6. Apply Ingress

```bash
kubectl apply -f ingress.yaml
```

Coroot is then available at: https://YOUR_MONITORING_HOST

## Configuration Files

**values.yaml** - Helm chart configuration:

- Storage sizes and StorageClass for Coroot, Prometheus and ClickHouse
- ClickHouse keeper storage (required for internal coordination)

**ingress.yaml** - Ingress with TLS via cert-manager

## Upgrade

```bash
helm repo update
helm upgrade -n coroot coroot coroot/coroot-ce \
  -f values.yaml
```

## Notes

- ClickHouse requires 3 keeper replicas for its internal coordination – these need their
  own PVCs with an explicit StorageClass. Make sure to set `clickhouse.keeper.storage.className`
  in your `values.yaml`, otherwise the PVCs will remain in `Pending` state.
- The AI Root Cause Analysis feature requires an optional Coroot Cloud account –
  this is **not enabled** in this setup. No data is sent to any external service.
- After first install, Prometheus needs a few minutes to synchronize its cache –
  this is normal and the warning in the UI will disappear automatically.
