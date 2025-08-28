##   METALLB : External LoadBalancer 

### Preparation  
If you’re using kube-proxy in IPVS mode, since Kubernetes v1.14.2 you have to enable strict ARP mode.

```
kubectl get configmap kube-proxy -n kube-system -o yaml | \
sed -e "s/strictARP: false/strictARP: true/" | \
kubectl apply -f - -n kube-system
```

### install metallab
```
kubectl apply -f https://raw.githubusercontent.com/metallb/metallb/v0.14.8/config/manifests/metallb-native.yaml
```

### Validate the deployment - Need to have metallb   
```
helm get manifest metallb -n metallb-system |grep "# Source: "
kubectl get crds -A | grep metallb
kubectl api-resources | grep metallb     # Should contain ipaddresspool
```

### Defining the IPs to assign to the Load Balancer services - using IPAddressPool

```
apiVersion: metallb.io/v1beta1
kind: IPAddressPool
metadata:
  name: defaultpool
  namespace: metallb-system
spec:
  addresses:
  - 192.168.1.130/32
  - 192.168.1.131/32
  autoAssign: true
  avoidBuggyIPs: false
```
### This pool will be used by LoadBalancer service's annotation section.
### Example: 
```
metadata: 
  annotations: 
    metallb.universe.tf/ip-allocated-from-pool: defaultpool
```
