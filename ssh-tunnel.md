## Creating a ssh tunnel between

Create a SSH Tunnel from localhost to remote host (Host2) via a SSH Server (Host1)

<pre>

+---------------------+    SSH Connection (sajive@host1:22)            +---------------------+
| Your Local Machine  | <--------------------------------------------> |       Host1         |
|                     |                                                |  (SSH Server)       |
|  Local Port 38351   |                                                |                     |
|  (e.g.,ssh -p 38351 |                                                |                     |
|    localhost)       |                                                |                     |
|        |            |                                                |                     |
|        V            |                                                |                     |
|    Traffic to       |                                                |                     |
|  localhost:38351    |                                                |                     |
+--------|------------+                                                +-------|-------------+
         |                                                                     |
         |  (Forwarded through SSH tunnel)                                     |  (Host1 connects to Host2)
         +=====================================================================+
                                                                               |
                                                                               V
                                                                     +---------------------+
                                                                     |       Host2         |
                                                                     | (Destination Server)|
                                                                     |   Port 22 (SSH)     |
                                                                     +---------------------+

</pre>

### Flow of Connection: 

1.	Initiation: You run the ssh command on "Your Local Machine".
2.	SSH Tunnel Establishment: An SSH connection is established from "Your Local Machine" to "Host1" on port 22, authenticating as sajive. This connection is sent to the background (-f) and doesn't open a shell (-N).
3.	Local Listening Port: On "Your Local Machine", SSH starts listening on port 38351.
4.	Traffic Redirection: When you (or any application on your local machine) try to connect to localhost:38351, that traffic is intercepted by the SSH client.
5.	Secure Forwarding: The SSH client encrypts this traffic and sends it through the established SSH tunnel to "Host1".
6.	Proxying by Host1: "Host1" receives the encrypted traffic, decrypts it, and then initiates a new connection from itself to "Host2" on port 22.
7.	Destination Reached: "Host2" receives the connection from "Host1" on its port 22.
8.	Return Path: The response from "Host2" travels back to "Host1", then through the SSH tunnel to "Your Local Machine", and finally to the application that originally connected to localhost:38351.



### The command 
```
sshpass -p 'mypassword' ssh -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no -p 22 sajive@host1 -fNL 38351:host2:22
```

establishes a secure SSH connection to a remote server (***host1***) and sets up a local port forwarding tunnel. 
This tunnel allows you to access a service on a third machine (host2) through host1, as if it were running on your local machine.

Let's break down each part of the command:

  * ssh: This is the command to initiate the Secure Shell (SSH) client, which is used for secure remote access.
	*	-o UserKnownHostsFile=/dev/null: This option tells SSH not to read or write host keys to the known_hosts file. By setting it to /dev/null, any host key presented by host1 will not be saved, and SSH will not check for a previously saved key. This is often used in automated scripts or temporary connections where saving host keys is not desired.
	*	-o StrictHostKeyChecking=no: This option disables strict host key checking. When set to no, SSH will automatically accept the host key presented by host1 without prompting the user for confirmation, even if it's a new or changed key. Combining this with UserKnownHostsFile=/dev/null completely bypasses host key verification, which reduces security by making "man-in-the-middle" attacks harder to detect.
	*	-p 22: This specifies the port number on the remote host (host1) to connect to. Port 22 is the standard port for SSH.
	*	sajive@host1:
		*	sajive is the username used to authenticate on the remote SSH server.
		*	host1 is the hostname or IP address of the remote SSH server you are connecting to.
	*	-f: This option sends the SSH process to the background before command execution. This means that after successful authentication and tunnel setup, the SSH client will run in the background, freeing up your local terminal.
	*	-N: This option tells SSH not to execute a remote command. It's used when the primary purpose of the SSH connection is solely for port forwarding, not to open an interactive shell or run commands on the remote server.
	*	-L 38351:host2:22: This is the core of the local port forwarding setup:
	  *	-L: Indicates local port forwarding. SSH will listen on a specified port on your local machine.
		*	38351: This is the local port number on your machine. Any traffic directed to localhost:38351 on your local machine will be forwarded through the SSH tunnel.
		*	host2: This is the destination hostname or IP address that host1 will connect to. This could be another server on the same network as host1, or even host1 itself (though less common in this specific -L format).
		*	22: This is the port on the host2 machine that host1 will connect to. In this case, it's port 22, suggesting you are forwarding to an SSH service on host2.

### In summary:

This command creates a secure, backgrounded SSH connection from your Local Machine to host1 using the user ***sajive***. 
It then sets up a tunnel such that any connection made to port 38351 on your Local Machine (e.g., ssh -p 38351 localhost) will be securely forwarded through host1 to port 22 on host2. This effectively allows your local machine to connect to host2:22 indirectly via host1. The -o options explicitly disable host key checking for convenience, which is generally not recommended for security unless in controlled environments.


### Testing the tunnel

* Check if the SSH proces is running on your local machine
```
ps aux | grep "ssh -o UserKnownHostsFile"
```

* Check if local port 38531 is listening on the local machine

```
netstat -tuln | grep 38351
```

* Test the tunnel by connecting and running the echo 1 command 
   From the localhost, run the following command using the same port used to create the tunnel.

```
shpass -p  'mypassword' ssh -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no -p 38351 root@localhost echo 1
```

This command if successful will print the number 1 to the console.

