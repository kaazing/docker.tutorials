# Redis with Kaazing Gateway  ![Enterprise Edition](../../enterprise-feature.png)

This tutorial shows how to connect WebSocket clients to a Redis server over WebSocket via the Gateway.

### Getting Started

To run this you must have Docker installed and have added a host file entry for `kaazing.example.com`, as described [here](../../README.md)

The [docker-compose.yml](docker-compose.yml) describes two containers it will run: the Gateway and the Redis server.  These will be launched in the following configuration:

![redis architecture](../docker-redis.png)

The Gateway container will run a Redis service that allows WebSocket clients to connect on the front-end.  Clients will connect on a `ws` address.  The [Gateway config file](gateway/jms-redis-gateway-config.xml) is configured with a `redis` service as follows:

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
      <!-- Only WebSockets coming from this origin can access this url -->
      <allow-origin>*</allow-origin>
    </cross-site-constraint>
  </service>
```

### Run

1. Start the containers
  ```bash
  docker-compose up -d
  ```
  
2. Connect to the Gateway in a Web browser via [http://kaazing.example.com:8000/](http://kaazing.example.com:8000/).  
3. Change the connect URL of the demo to `ws://kaazing.example.com:8000/` and connect.

4. Subscribe and publish JMS messages as desired.

### Note

Redis doesn't support transactions. As such, the JMS client will not work for transactions.

### Next Steps
  
[See Deployment Scenarios](../../README.md#deployment-scenarios)
