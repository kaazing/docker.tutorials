# Broadcast Netcat to WebSocket Clients

This tutorial describes how to broadcast TCP data to WebSocket clients. [Netcat](https://en.wikipedia.org/wiki/Netcat) is used as a TCP backend server.

### Getting Started

To run this example, you must have Docker installed and have added a host file entry for `kaazing.example.com`, as described [here](../../README.md).

The [docker-compose.yml](docker-compose.yml) describes the two containers it will run: the Gateway and Netcat. These containers will be launched in the following configuration:

![Broadcast architecture](../docker-broadcast.png)

The Gateway container will run a broadcast service that allows WebSocket clients to connect on the front-end. When a TCP message is sent from Netcat, the Gateway will forward that message to all other connected clients. The [Gateway config file](gateway/broadcast-gateway-config.xml) is configured as follows:

```xml
  <service>
    <name>Netcat Broadcast</name>
    <description>
        A service that broadcast from TCP to WebSocket by
        connecting to a TCP Backend listening on tcp://netcat:1000
        and accepting WebSocket connections on ws://kaazing.example.com:8000/
    </description>
    <accept>ws://kaazing.example.com:8000/</accept>
    <connect>tcp://netcat:1000</connect>

    <type>broadcast</type>

    <!-- Restrict cross site constraints before running in production -->
    <cross-site-constraint>
      <!--
        * is not secure for production javascript applications and allows
        access from all origins. See https://developer.mozilla.org/en-US/docs/Web/HTTP/Access_control_CORS
      -->
      <allow-origin>*</allow-origin>
    </cross-site-constraint>
  </service>
```

### Run

1. Start the containers
  ```bash
  docker-compose up -d
  ```

2. Connect to the Gateway in a Web browser via [http://websocket.org/echo.html?location=ws://kaazing.example.com:8000/](http://websocket.org/echo.html?location=ws://kaazing.example.com:8000/)

3. To push data through Netcat run
  ```bash
  docker-compose exec netcat nc -l 1000
  ```
  and then type any message you want to send
  
### Next Steps
  
- Learn how to configure the Gateway to encrypt traffic with WebSocket over TLS: [WSS](../../wss)
