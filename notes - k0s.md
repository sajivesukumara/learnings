
## k0s architecture 
It’s built to provide a simplified and lightweight Kubernetes experience. 
The key idea behind it is to combine all the components into a single binary, which is easy to deploy and manage. 
Here's an overview of the k0s architecture and interaction:

### **k0s Architecture Overview:**
1. **Single Binary**:
   - The core concept of k0s is a single binary file that contains all Kubernetes components (API server, controller manager, etcd, scheduler, kubelet, and kube-proxy). This makes it easy to deploy and manage.

2. **Master Node**:
   - k0s is built to have a "single node" control plane and worker model. However, you can scale this out. The master node runs the API server, scheduler, controller-manager, etcd, and optionally the kubelet.
   - The **k0s controller** handles managing Kubernetes components like the API server and scheduling operations.
   
3. **Worker Nodes**:
   - The worker nodes run the kubelet and kube-proxy for orchestrating and managing containers. In a multi-node setup, they connect back to the master node to receive commands.

4. **ETCD**:
   - Etcd is included within the k0s binary as a key-value store, but you can configure it to use an external etcd instance for larger production setups.

5. **Networking**:
   - It uses a flexible networking model, and different CNI plugins can be configured depending on your needs (e.g., Calico, Cilium, Flannel).

6. **High Availability**:
   - In larger clusters, the control plane can be replicated across multiple nodes for high availability.

---

### **Interaction Diagram**:

- **Client/User Interaction**:
   - Users interact with the Kubernetes cluster via `kubectl` commands or the Kubernetes API server.
   - The API server sends requests to the appropriate controller (e.g., deployment controller, scheduler).

- **Control Plane Interaction**:
   - The control plane (running on the master node) consists of components like the API server, scheduler, and controller manager. These components interact with each other and manage the desired state of the cluster (e.g., scheduling pods, scaling deployments).
   - The **k0s controller** ensures that the components in the control plane are properly running.

- **Data Store**:
   - The API server communicates with etcd to store cluster state (pods, deployments, services, etc.).
   
- **Worker Node Interaction**:
   - Worker nodes are responsible for running containers. They have a kubelet that communicates with the API server to fetch instructions about what containers to run.
   - The kube-proxy manages network routing for the services running on the cluster.

---

### **Diagram Sketch**:
```
   +------------------+        +------------------+      +------------------+
   | kubectl/user     | <----> | API Server       | <--> | Controller       |
   | Commands         |        | (REST Interface) |      | Manager /        |
   +------------------+        +------------------+      | Scheduler        |
                              +------------------+       +------------------+
                                    | |
                             +--------------------+ 
                             | etcd               | 
                             +--------------------+
                                      |
          +------------------+ +------------------+ 
          | Worker Node      | | Worker Node      | 
          | (kubelet +       | | (kubelet +       | 
          | Kube-proxy)      | | Kube-proxy)      |
          +------------------+ +------------------+
```


- **User/Client**: Sends requests to the API server via `kubectl`.
- **API Server**: Acts as the main entry point for all user requests. It queries etcd for cluster state and communicates with other control plane components.
- **Controller Manager / Scheduler**: Responsible for managing the desired state (e.g., scheduling pods to nodes, managing deployments).
- **etcd**: The data store for Kubernetes, storing configuration data, state information, etc.
- **Worker Nodes**: Contain the kubelet (manages containers) and kube-proxy (handles network routing).

