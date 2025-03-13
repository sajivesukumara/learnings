# Websocket examples using netty java library

## Echoserver example
<pre>
Path : grails-websocket/app/src/main/java/org/echoserver 
Files: EchoServer.java EchoServerHandler.java
</pre>

```
cd $HOME/groovy-projects
git clone  git@github.com:sajivekumar/learnings.git
cd learnings/websocket-stomp/grails-websocket/echoserver
gradle build
gradle run 
```


## ChatServer - broadcast messages
<pre>
Path : grails-websocket/app/src/main/java/org/chatserver
</pre>

```
cd $HOME/groovy-projects
git clone  git@github.com:sajivekumar/learnings.git
cd learnings/websocket-stomp/grails-websocket/chatserver
gradle build
gradle run 
```

From the browser open : http://localhost:8080, which opens a login window (credentials are dummy).
Once you login, you can type in messages, but the messages dont reach any other chat cleint or server.
You could open the link in a new browser and start messaging. 
This would be a broadcast message.



## NOTES

### To remove progress messages with gradle run do the following 
From command line / Terminal
```
set TERM=bumb or use --console=plain
Example 
gradle run --console=plain
```

Set the following flag in the gradle.properties
```
org.gradle.console=plain
```
