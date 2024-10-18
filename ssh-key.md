# ssh private and public key usages

## How do SSH keys work?
The SSH key pair is used to authenticate the identity of a user or process that wants to access a remote system using the SSH protocol.
The public key is used by both the user and the remote server to encrypt messages. On the remote server side, it is saved in a public key file. On the user’s side, 
it is stored in SSH key management software or in a file on their computer. 
The private key remains only on the system being used to access the remote server and is used to decrypt messages.

When a user or process requests a connection to the remote server using the SSH client, a challenge-response sequence is initiated to complete authentication. 
The SSH server recognizes that a connection is being requested and sends an encrypted challenge request using the shared public key information. 
The SSH client then decrypts the challenge message and responds back to the server. The user or process must respond correctly to the challenge to be granted access. 
This challenge-response sequence happens automatically between the SSH client and server without any manual action by the user.

## 
