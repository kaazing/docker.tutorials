# Echo Service with WSS

This tutorial shows how to secure a websocket service with TLS/SSL.

### Getting Started

To run this you must have installed docker and have added a host file entry for kaazing.example.com, as described [here](../../README.md)

The [docker-compose.yml](docker-compose.yml) describes one container: the gateway.  

![wss](../docker-wss.png)

The gateway container will run a echo service that allows WebSocket clients to connect on the front end.  Clients will connect on a "wss" address which denotes a TLS secured websocket url.  The [gateway config file](gateway/echo-wss-gateway-config.xml) is configured with an echo service as follows:

```xml
    <service>
    <name>WSS Echo</name>
    <description>A service that echo's messages back for WSS</description>
    <accept>wss://kaazing.example.com:8000/</accept>

    <type>echo</type>

    <cross-site-constraint>
      <!-- Only websockets coming from this origin can access this url -->
      <allow-origin>https://kaazing.example.com:8000/</allow-origin>
    </cross-site-constraint>
  </service>
```

A security section is added to the config that provides the TLS private key to the gateway:

```xml
  <security>
    <keystore>
      <type>JCEKS</type>
      <file>keystore.db</file>
      <password-file>keystore.pw</password-file>
    </keystore>
  </security>
```

This keystore.db is populated with a private key for kaazing.example.com in the [Dockerfile](gateway/Dockerfile):

```
keytool -genkeypair -keystore conf/keystore.db -storetype JCEKS -keypass ab987c -storepass ab987c -alias kaazing.example.com -keyalg RSA -dname "CN=kaazing.example.com, OU=Example, O=Example, L=Mountain View, ST=California, C=US"
```

This private key will be a self-signed certificate, and we will trust it in the browser UI.  If you would prefer to use a Trusted Certificate or to add the self-signed certificate to your truststore you find directions [here](http://kaazing.com/doc/5.0/security/p_tls_trusted/) and [here](http://kaazing.com/doc/5.0/security/p_tls_selfsigned/index.html)

Lastly, in the Dockerfile we have added logic to pull in and build a javascript client example.  We then serve this page from a secure origin via a directory service that is add to the [gateway config](gateway/echo-wss-gateway-config.xml).

```xml
  <service>
    <name>Directory Service</name>
    <description>
        Directory Service to serve up secure pages with, file
        in web directory are available via https
    </description>

    <accept>https://kaazing.example.com:8000/</accept>

    <type>directory</type>

    <properties>
      <directory>/javascript.client.tutorials/ws</directory>
      <welcome-file>index.html</welcome-file>
    </properties>
  </service>
```

### Run

1. Start the containers
  ```bash
  docker-compose up -d
  ```

2. Connect to the gateway in a web browser via [https://kaazing.example.com:8000/].  You will see a security error saying the certificate is not trusted.  This is because we are using a self-signed certificate.  Proceed anyways (in chrome this is under the advanced drop down displayed).  This will temporarily add the generated self-signed certificate to you truststore.

3. Change the connect url of the demo to `wss://kaazing.example.com:8000/` and connect

4.  When you send a message it should be echo back to you.

### Next Steps
  
- [See how to configure user authentication with WebSocket](../../user-auth)
- [See how to configure AMQP and WebSocket](../../AMQP)
- [See how to configure JMS and WebSocket](../../JMS)
