#!/bin/bash

# Kubernetes Certificate Renewal Script
# This script should be run annually or when certificates expire
# Run this script on the master node

set -e

WORKERS=("worker-1" "worker-2" "worker-3")
MASTER="master-1"

echo "========================================="
echo "Kubernetes Certificate Renewal Script"
echo "========================================="

# Step 1: Renew all certificates on master
echo "Step 1: Renewing certificates on master node..."
sudo kubeadm certs renew all
sudo kubeadm init phase kubeconfig all

echo "Step 2: Restarting control plane components..."
# Restart control plane pods by moving manifests temporarily
sudo mv /etc/kubernetes/manifests/kube-apiserver.yaml /tmp/
sudo mv /etc/kubernetes/manifests/kube-controller-manager.yaml /tmp/
sudo mv /etc/kubernetes/manifests/kube-scheduler.yaml /tmp/

echo "Waiting 30 seconds for pods to stop..."
sleep 30

# Move manifests back
sudo mv /tmp/kube-apiserver.yaml /etc/kubernetes/manifests/
sudo mv /tmp/kube-controller-manager.yaml /etc/kubernetes/manifests/
sudo mv /tmp/kube-scheduler.yaml /etc/kubernetes/manifests/

echo "Waiting 120 seconds for control plane to restart..."
sleep 120

# Wait for API server to be ready
echo "Waiting for API server to be ready..."
for i in {1..30}; do
    if kubectl --kubeconfig=/etc/kubernetes/admin.conf get nodes &>/dev/null; then
        echo "API server is ready!"
        break
    fi
    echo "API server not ready yet, waiting 10 seconds... ($i/30)"
    sleep 10
done

# Step 3: Fix worker nodes
echo "Step 3: Fixing worker node certificates..."

for worker in "${WORKERS[@]}"; do
    echo "Processing $worker..."
    
    # Create kubelet config for this worker
    sudo cp /etc/kubernetes/admin.conf /tmp/kubelet-${worker}.conf
    sudo sed -i "s/kubernetes-admin/system:node:${worker}/g" /tmp/kubelet-${worker}.conf
    
    # Copy to worker and restart
    scp /tmp/kubelet-${worker}.conf ${worker}:/tmp/
    
    ssh ${worker} "
        sudo rm -f /var/lib/kubelet/pki/kubelet-client-* 2>/dev/null || true
        sudo rm -f /var/lib/kubelet/pki/kubelet-server-* 2>/dev/null || true
        sudo cp /tmp/kubelet-${worker}.conf /etc/kubernetes/kubelet.conf
        echo 'KUBELET_EXTRA_ARGS=--kubeconfig=/etc/kubernetes/kubelet.conf --bootstrap-kubeconfig=/etc/kubernetes/kubelet.conf' | sudo tee /etc/sysconfig/kubelet
        sudo systemctl restart kubelet
    "
    
    echo "$worker processed."
done

echo "Step 4: Waiting 60 seconds for CSRs and approving them..."
sleep 60

# Approve all pending CSRs
pending_csrs=$(kubectl --kubeconfig=/etc/kubernetes/admin.conf get csr | grep Pending | awk '{print $1}' || true)
if [ -n "$pending_csrs" ]; then
    echo "Approving pending CSRs..."
    echo "$pending_csrs" | xargs kubectl --kubeconfig=/etc/kubernetes/admin.conf certificate approve
    echo "CSRs approved."
else
    echo "No pending CSRs found."
fi

echo "Step 5: Verifying cluster health, waiting 30 seconds..."
sleep 30

# Check nodes
echo "Node status:"
kubectl --kubeconfig=/etc/kubernetes/admin.conf get nodes

# Check control plane pods
echo "Control plane status:"
kubectl --kubeconfig=/etc/kubernetes/admin.conf get pods -n kube-system | grep -E "(apiserver|controller-manager|scheduler|etcd)"

# Check for authentication errors
echo "Checking for authentication errors in API server..."
api_pod=$(kubectl --kubeconfig=/etc/kubernetes/admin.conf get pods -n kube-system | grep kube-apiserver | awk '{print $1}')
auth_errors=$(kubectl --kubeconfig=/etc/kubernetes/admin.conf logs $api_pod -n kube-system --tail=50 | grep "authentication.go" | grep "certificate has expired" | wc -l)

if [ "$auth_errors" -eq 0 ]; then
    echo "✅ No authentication errors found!"
else
    echo "⚠️  Still $auth_errors authentication errors found. May need manual intervention."
fi

echo "========================================="
echo "Certificate renewal completed!"
echo "========================================="
echo ""
echo "IMPORTANT: Schedule this script to run annually, about 1-2 weeks before"
echo "certificate expiration (check with: sudo kubeadm certs check-expiration)"
echo ""
echo "To set up automatic renewal, add to crontab:"
echo "# Run certificate renewal annually (first week of May)"
echo "0 2 1 5 * /path/to/this/script.sh >> /var/log/k8s-cert-renewal.log 2>&1"

