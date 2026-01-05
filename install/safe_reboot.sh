#!/bin/bash
echo "🚀 Starting Graceful Reboot..."

# 2. Stop ArgoCD Controller
echo "⏸️ Scaling down ArgoCD..."
kubectl -n argocd scale statefulset/argocd-application-controller --replicas=0

# 3. Drain the Node (Forcing past PDBs)
echo "🧹 Draining kikiflix-ubuntu ..."
# --disable-eviction is the key to bypassing those Paperless/Immich errors
kubectl drain kikiflix-ubuntu --ignore-daemonsets --delete-emptydir-data --force --grace-period=30 --disable-eviction
# for stuck in Terminating :
kubectl get pods -A | grep Terminating | awk '{print "kubectl delete pod " $2 " -n " $1 " --force --grace-period=0"}' | sh

# 4. Stop K0s engine
echo "🛑 Stopping k0s..."
sudo k0s stop

echo "♻️ Rebooting now..."
sync
sudo reboot

# after reboot
kubectl uncordon kikiflix-ubuntu
kubectl -n argocd scale statefulset/argocd-application-controller --replicas=1
sudo systemctl restart tailscaled
