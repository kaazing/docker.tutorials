# JMS via ActiveMQ with Kaazing Gateway  ![Enterprise Edition](../../enterprise-feature.png)

This tutorial shows how to connect JMS clients to the JMS broker, ActiveMQ, via the Gateway and over WebSocket.

### Getting Started

To run this example, you must have Docker installed and a host file entry for `kaazing.example.com`, as described [here](../../README.md)

The [docker-compose.yml](docker-compose.yml) file describes the two containers it will run: the Gateway and the ActiveMQ broker.  These containers are launched in the following configuration:

![JMS architecture](../docker-jms.png)

The Gateway container will run a `jms` service that enables WebSocket clients to connect on the front-end.  Clients will connect on a `wss://` address which denotes a TLS-secured websocket URL.  The [Gateway config file](gateway/jms-activemq-gateway-config.xml) is configured with a `jms` service as follows:

```xml
  <service>
    <name>JMS Tutorial Service</name>
    <description>A service that proxys to an JMS backend</description>
    <accept>wss://kaazing.example.com:8000/</accept>

    <type>jms</type>

    <properties>
      <connection.factory.name>ConnectionFactory</connection.factory.name>
      <context.lookup.topic.format>dynamicTopics/%s</context.lookup.topic.format>
      <context.lookup.queue.format>dynamicQueues/%s</context.lookup.queue.format>
      <env.java.naming.factory.initial>org.apache.activemq.jndi.ActiveMQInitialContextFactory</env.java.naming.factory.initial>
      <env.java.naming.provider.url>tcp://activemq:61616</env.java.naming.provider.url>
    </properties>

    <cross-site-constraint>
      <!-- Only WebSockets coming from this origin can access this url -->
      <allow-origin>https://kaazing.example.com:8000/</allow-origin>
    </cross-site-constraint>
  </service>
```

### Run

1. Start the containers
  ```bash
  docker-compose up -d
  ```
  
2. Connect to the Gateway in a Web browser via [https://kaazing.example.com:8000/](https://kaazing.example.com:8000/).  You might see a security error saying the certificate is not trusted. This is the result of using a self-signed certificate. Proceed anyways ((in Chrome this is under the **Advanced** drop-down menu). This step will temporarily add the generated self-signed certificate to your computer's truststore.

3. Change the connect URL of the demo to `wss://kaazing.example.com:8000/` and connect.

4. Subscribe and publish JMS messages as desired.

### Next Steps
  
[See Deployment Scenarios](../../README.md#deployment-scenarios)
