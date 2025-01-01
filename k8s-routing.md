# Create Istio Ingress Gateway and VirtualService

create the Istio Ingress gateway that only expose traffic through port 80 and create routes to expose atlas-ui, authz and atlas-rest (nb-rest) services.


![image](https://github.com/user-attachments/assets/89c2f955-ad0e-4e75-8158-c418583f4528)


### Gateway Proxy
This is a load balancer operating at the edge of the mesh receiving incoming and outgoing HTTP connections. 
Istio deploys a Gateway Proxy called istio-ingressgateway in the istio-system namespace. 
We have configured this as a NodePort since we dont have a FQDN available for the host string.

### Gateway Configuration
This configuration describes a set of ports that should be exposed, the type of protocol to use, SNI configuration for the load balancer, etc., This will be used to configure the Gateway Proxy. It is often simply called a Gateway in Istio documentation.  In fact, when we create one of these resources, we provide a value of **Gateway** to the Kind property of the resource. You can’t configure application-layer routing rules here (this is what Virtual Services are for). A VirtualService can then be bound to a gateway to control the forwarding of traffic arriving at a particular host or gateway port.

### Virtual Service
A Virtual Service defines a set of request routing rules that can be used to distribute traffic to different destinations in the service mesh. Specifically, Virtual Services define application-layer traffic routing rules, meaning that HTTP requests can be routed to different destinations based on properties like URI, request method, and headers. 
Similar to Gateway resources discussed above, VirtualService resources are not standalone services running on their own set of pods, instead they are simply configuration that is applied to the proxies in the mesh that actually accept and send requests. 
Virtual Services can be applied either to the Gateway Proxy, or to the sidecar Envoy proxies that run alongside the services for your application that are running in the mesh.

### Destination Rule
Destination Rules define routing policies applied to traffic that has already been routed to a particular service. Additionally, we can use Destination Rules to define service subsets, which allow us to group the instances of our service by version, giving us the ability to route traffic intelligently between multiple active versions of a service without changing anything in our service code.

### Istio Sidecar
This is the Envoy Proxy that runs alongside each instance of your deployed service, if enabled. Traffic to and from your service is intercepted by this proxy.
We have enabled istio injection for namespaces.

### Application Service
This is the microservice application, deployed to a Kubernetes cluster as a standard Kubernetes service. Instances of this service run in pods alongside instances of the MyApplication Sidecar proxy.


Kubernetes uses Ingress controllers to handle traffic from the outside to the cluster. This is no longer the case while using Istio. Istio gateways use new Gateway resources and VirtualServices resources to control ingress traffic. They work together to route traffic to the service mesh.

This is how a request reach its target application:

1) The client sends a request on a specific port.
2) The Server Load Balancer (SLB) listens to this port and forwards the request to the cluster (on the same port or another port).
3) Within the cluster, the request is routed to the port forwarded by the SLB which was listened to by the Istio IngressGateway service.
4) The Istio IngressGateway service forwards the request (on the same port or another port) to the corresponding pod.
5) Gateway resources and VirtualService resources are configured on the IngressGateway pod. The port, protocol, and related security certificates are configured on the Gateway. The VirtualService routing information is used to find the correct service.
6) The Istio IngressGateway pod routes the request to the corresponding application service based on the routing information.
7) The application service routes the request to the corresponding application pod.


![k8s-service-flow (1)](https://github.com/user-attachments/assets/06f12321-21e7-4785-b9f7-1ed764e57eb2)


Every Gateway is backed by a service of type LoadBalancer. The external load balancer IP and ports for this service are used to access the gateway. 
Kubernetes services of type LoadBalancer are supported by default in clusters running on most cloud platforms

```
DNS -> Load Balancer -> API gateway -> Backend service
```
**Load Balancer** : is the servie attached with the Gateway using select name

**API Gateway**: has rules defined in the VS for routing traffic to relevent backend service/pod.

**Backend Service**: Receives the traffic from the istio-gateway (image: proxy) pod and sends to application pod.


#### Create a Gateway with selector defined with unique name that would be used in the LoadBalancer
```
spec:
  selector:
      name: my-ingress-gateway
      service.istio.io/**canonical-name: my-ingress-gateway**
```

##### Define a service of type LoadBalancer and selector with "istio:devel-platform-gateway"
```  
  ports:
  - name: https
    nodePort: 32143
    port: 443
    protocol: TCP
    targetPort: 443
  selector:
    app: devel-platform-gateway
    **istio: my-ingress-gateway**
  sessionAffinity: None
  type: **LoadBalancer**
status:
  **loadBalancer**:
    ingress:
    - ip: 10.10.10.101     // An external IP can defined in DNS with a FQDN
    - 
```

### Istio Proxy Pods in each of the application pods also handle the ingress traffic

![image](https://github.com/user-attachments/assets/f1a800bf-8f0b-4935-b614-65a644be0bd3)

