# Debugging k0s on ubuntu

## 1. Verify k0s Controller is Running
Find ensure the k0s controller is running on teh host machine:

sudo k0s status
sudo k8s start

## 2. Check API server Accessibility Locally
Test if the API is accessible locally on the controller node: 

```
curl -k https://localhost:16443/version
or
curl -k https://<controller-ip>:16443/version
```

If this fails, check the k0s logs:
```
sudo journalctl -u k8scontroller -f
```

## 3. Verify Network Connectivity

Ensure the oher machine can reach the conroller node:

```
ping <controller-ip>
```

If ping fails, check:
* Network routes/filewall (e.g. ., AWS Security Groups, iptables, etc.).
* The controller node's local firewall (UFW/iptables).

## 4. Check Firewall Rules
If the controller node has a firewall (UFW/iptables/apparmor), allow port 16443"

* UFW (Ubuntu)
```
sudo ufw allow 16443/tcp
sudo ufw reload
```

* iptables
```
sudo iptables -A INPUT -p tcp --dport 16443 -j ACCEPT
```
For persistent rules, install iptables-persistent or save rules.

* apparmor
```
systemctl stop apparmor
systemctl disable apparmor
```

Restart the k0s or containerd/docker service
```
sudo k0s stop
sudo k0s start
systemctl daemon-reload
systemctl restart containerd
```

## 5. Validate k0s Bind Address

Ensure k0s is binding to the correct network interface. Edit the k0s config (/etc/k0s/k0s.yaml)

```
spec:
   api:
      externalAddress: <controller-ip>
      address: <controller-ip>
      port: 16443
```

Restart k0s after changes
```
sudo k0s stop
sudo k0s start
```

## 6. Check the Load Balancer/Proxy
IF using a load balancer (e.g., for HA setups), ensure it routes traffic to port 16443 on the controller.

## 7. Test with kubectl from remote machone
On teh remote machine try kubectl 
```
kubectl --kubeconfig=/path/to/kubeconfig get nodes
```
Ensure the kubeconfig has the correct API server IP:
```
clusters:
- cluster:
     server: https://<controller-ip>:1643
```

## 8. Check for network segmentation

•	If the machines are in different subnets/VPCs, ensure proper routing/NAT rules.
•	For cloud providers (AWS/GCP), check Security Groups/NACLs.

## 9. Debug with netstat/ss

On the controller node, verify 16443 is listening

```
sudo netstat -tunlp | grep 16443

OR

sudo ss -tulnp | grep 16443
```

## 10. Inspect k0s logs

```
sudo journalctl -u k0scontroller -n 50 --no-pager
```



