# KWIC TLS

(**Note:** Please complete the [1-Simple](../1-simple) tutorial before starting this one.)

Demonstrate a KWIC scenario with TLS/SSL.

![KWIC](img/kwic-tls-1.jpg)

In this scenario, connections between the cloud and on-premise instances use TLS, those that are in the red box:

![KWIC](img/kwic-tls-2.jpg)

TLS is used to keep data private, but is also used to establish machine-to-machine trust between the two KWIC instances. The cloud instance presents a server certificate to the on-prem instance, and the on-prem instance presents a client certificate to the cloud instance for mutual authentication.

Communication between the cloud instance with **client A** and **server B** is not encrypted. Similarly, communication between the agent with **server A** and **client B** are also not encrypted. However any traffic between the cloud and on-prem instances is encrypted.

If any clients and servers you use support TLS/SSL, then they can encrypt their communication, just as if they were connected directly. This gives you true end-to-end TLS which intermediaries, including KWIC, cannot decrypt, as shown here:

![KWIC](img/kwic-tls-3.jpg)

With end-to-end TLS, when **client A**, say, connects, **server A** presents its server certificate. This travels down to **client A** to validates and trusts it. If your client and server support client certificates, then **client A** can present its client certificate to **server A** to validate and trust it.

End-to-end TLS is not shown in this tutorial, as configuring that is the responsibility of the endpoint client and server, which is outside the scope of configuring KWIC. In this scenario, you will learn how to configure TLS between the cloud and on-prem instance.

## Configuration

The configuration for the cloud KWIC instance is in [config/cloud-config.xml](config/cloud-config.xml).

The configuration for the on-prem KWIC instance is in [config/onprem-config.xml](config/onprem-config.xml).

This tutorial uses TLS, so all keys, certificates, and other TLS artifacts are generated automatically when the Docker Compose suite starts.

# Requirements

* You will need Docker and Docker Compose.

* If you don't have **netcat** installed on your system (the `nc` command) then you will need to use a netcat substitute.

See the the **Requirements** section in the [main README](../../README.md) for details of the above.

This tutorial does not need any modification to your hosts file.

# Running the tutorial

In this tutorial you will use **netcat** for the TCP clients **client A**, **client B**. You run netcat by specifying a hostname or IP address, and a port. Once it is connected, you can type something and hit Enter, and you will see your message echoed back from the server.

If you are running on Windows, or don't have netcat installed, everywhere you see `nc 192.168.99.100 5551` in the steps below, replace it with the following command:

```bash
docker run -it --rm konjak/netcat 192.168.99.100 5551
```

## Steps

1. In a terminal window, use Docker Compose to launch all of the Docker containers:

    ```bash
    $ docker-compose up
    ```

    It may take a few moments for all of the containers to start. It's probably ready when you see something like the following lines in the log output on the screen (note that these lines may not be grouped together in the output depending on the order Docker starts containers):

    ```
    example.com_1  | INFO  [tcp#1 172.32.0.4:40484] OPENED: (#00000001: kaazing tcp, server, /172.32.0.4:40484 => /172.32.0.6:443)
    onprem_1       | DEBUG SSL session ID [B@51e5a4aa on transport session #1 (#00000001: kaazing tcp, client, /172.32.0.4:40484 => /172.32.0.6:443): cipher TLS_RSA_WITH_AES_256_CBC_SHA, app buffer size 16916, packet buffer size 16921
    example.com_1  | DEBUG SSL session ID [B@6153daf3 on transport session #1 (#00000001: kaazing tcp, server, /172.32.0.4:40484 => /172.32.0.6:443): cipher TLS_RSA_WITH_AES_256_CBC_SHA, app buffer size 16916, packet buffer size 16921
    example.com_1  | DEBUG SSL session ID [B@304b303f on transport session #1 (#00000001: kaazing tcp, server, /172.32.0.4:40484 => /172.32.0.6:443): cipher TLS_RSA_WITH_AES_256_CBC_SHA, app buffer size 16916, packet buffer size 16921
    onprem_1       | INFO  [ssl#2 172.32.0.4:40484] OPENED: (#00000002: kzg ssl, client, ssl://example.com:443 => ssl://example.com:443)
    example.com_1  | INFO  [wsn#4 172.32.0.4:40484] OPENED: (#00000004: kzg wsn, server, ws://example.com:443/kwic => wss://example.com/kwic)
    onprem_1       | INFO  [wsn#4 172.32.0.4:40484] OPENED: (#00000004: kzg wsn, client, ws://example.com:443/kwic => wss://example.com/kwic)
    ```

    Those lines indicate that the on-prem instance established a TLS-based reverse connection to the cloud instance.

1. In another terminal window, test **client A** connecting to **server A** using netcat. Once it is connected, type `hello` and hit Enter. You will see your message echoed back. Type some more messages if you like, pressing Enter each time. When done, press Ctrl-C to exit netcat. Then do the same for **client B**

    If you don't have netcat installed, then do `docker run -it --rm konjak/netcat 192.168.99.100 5551`.

    If you successfully see the message echoed back, then you know there was roundtrip communication from the netcat client, through the cloud KWIC instance, through the on-prem KWIC instance, to the endpoint **server A**, and back. You can also look at the log output in the Docker Compose terminal window to see the connections being created and stopped.

    ```bash
    # Test client A to server A
    $ nc 192.168.99.100 5551
    hello
    hello
    ^C
    # Test client B to server B
    $ nc 192.168.99.100 6661
    world
    world
    ^C
    ```
