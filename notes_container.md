# How much memory is the container consuming, with pod and container memory limits set.

When you run free -h inside a **Ubuntu 24.04** container in Kubernetes, it incorrectly reports the host's total RAM (say 32 GB) instad of teh pod's actual limit (say 4GB).
Here's why this happens and how to get the real memory constraints.

## 1. Why ```free -h``` is Misleading in Containers

### free Reads Host Memory (Not Container Limits)
** The free command checks ```/proc/meminfo```, which reflects the host’s memory, not the container’s cgroup limits.
** Example Output (Misleading):
      ```
      bash
      $ free -h
               total used free shared buff/cache available
        Mem: 32G 1G 29G 100M 1G 30G
      ```
      This does NOT mean your **container has 32GB** available.
      The kernel exposes the host’s RAM to /proc/meminfo by default.

### The Correct Way to Check Container Memory Limits
    
* (1) Use cat /sys/fs/cgroup/memory/memory.limit_in_bytes**
    ```
    $ cat /sys/fs/cgroup/memory/memory.limit_in_bytes
    4294967296 # 4GB (Pod's actual limit)
    ```
    * This file shows the real memory limit enforced by Kubernetes (4GB in your case).

* (2) Use cgroup2 (If Enabled)**
    ```
    $ cat /sys/fs/cgroup/memory.max
    4294967296 # 4GB
    ```
* (3) Use kubectl (From Outside the Pod)**
    ```
    kubectl get pod <pod-name> -o json | jq '.spec.containers[].resources.limits.memory'
    "4Gi" # Confirms the 4GB limit
    ```

## 2. Why Kubernetes Allows This Behavior
* Containers Share the Host Kernel:
/proc/meminfo is a global kernel interface, not container-aware.
The **real enforcement happens via cgroups**, not /proc.

* free -h is Not Container-Aware:
It reads /proc/meminfo directly, bypassing cgroup limits.

## 3. How to Get Accurate Memory Usage Inside the Pod
* Option 1: Use cgroup Tools
  ```
  # Check memory usage (container-aware)
  cat /sys/fs/cgroup/memory/memory.usage_in_bytes
  ```
* Option 2: Use ps to Check Process-Specific Usage
  ```
  ps aux --sort=-%mem | head
  ```
  Shows per-process memory usage (more accurate than free).

* Option 3: Install cgroup-tools (Debian/Ubuntu)
  ```
  apt update && apt install -y cgroup-tools
  cgget -n -r memory.max /
  * Explicitly checks cgroup-enforced limits.

## 4. What Happens If the Pod Exceeds 4GB?
* Kubernetes Enforces the Limit:
  If the container tries to use >4GB, the OOM Killer terminates it:

  ```
  kubectl describe pod <pod-name> | grep -A 5 "State:"
  
  Output:

  State: Terminated
  Reason: OOMKilled
  Exit Code: 137
  ```
* No Warning in free -h:
  Even if free shows 32GB, the pod cannot actually use more than 4GB.

## 5. Key Takeaways
✅ free -h is unreliable in containers → It shows host memory, not pod limits.

✅ Real limits are in /sys/fs/cgroup/memory/ → Use memory.limit_in_bytes.

✅ Kubernetes kills the pod if it exceeds limits.memory (even if free says otherwise).

✅ For debugging, use kubectl describe pod or cgroup tools.

Need further verification? Run:

```bash
kubectl exec -it <pod-name> -- cat /sys/fs/cgroup/memory/memory.limit_in_bytes
```
This will confirm the actual enforced limit (4GB). 
