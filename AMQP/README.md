# AMQP and WebSocket

The following topology graphic depicts how this scenario would be deployed in an enterprise environment.

![amqp](docker-amqp.png)

The Gateway can be configured as an AMQP proxy, accepting WebSocket AMQP client connections and messages and communicating with a backend AMQP broker.  Example configurations are shown for:

* [RabbitMQ](rabbitmq)
* QPID - coming soon
