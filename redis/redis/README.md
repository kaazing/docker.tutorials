# Redis with Kaazing Gateway

This tutorial shows how to connect websocket clients to a redis server

### Getting Started

To run this you must have installed docker and have added a host file entry for kaazing.example.com, as described [here](../../README.md)

The [docker-compose.yml](docker-compose.yml) describes two containers it will run: the gateway and the redis server.  These will be launched in the following configuration

![redis architecture](../redis.png)

The gateway container will run a redis service that allows WebSocket clients to connect on the front end.  Clients will connect on a "ws" address.  The [gateway config file](gateway/jms-redis-gateway-config.xml) is configured with a jms service as follows:

```xml
  <service>
    <name>REDIS Tutorial Service</name>
    <description>A service that proxys to an redis backend</description>
    <accept>ws://kaazing.example.com:8000/</accept>
    <connect>tcp://redis:6379</connect>
    
    <type>redis</type>
    <properties>
        <inactivity.timeout>0</inactivity.timeout>
    </properties>
    
    <cross-site-constraint>
      <!-- Only websockets coming from this origin can access this url -->
      <allow-origin>*</allow-origin>
    </cross-site-constraint>
  </service>
```

### Run

1. Start the containers
  ```bash
  docker-compose up -d
  ```
  
2. Connect to the gateway in a web browser via [http://kaazing.example.com:8000/](http://kaazing.example.com:8000/).  
3. Change the connect url of the demo to `ws://kaazing.example.com:8000/` and connect

4. Subscribe/Publish redis messages as desired

### Note

Redis doesn't support transactions. As such, the client used, which is the JMS client as well, won't work for transactions.
