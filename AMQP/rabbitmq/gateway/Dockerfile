FROM kaazing/enterprise-gateway:latest

# Generate Keystore entry for kaazing.example.com
RUN keytool -genkeypair -keystore conf/keystore.db -storetype JCEKS -keypass ab987c -storepass ab987c -alias kaazing.example.com -keyalg RSA -dname "CN=kaazing.example.com, OU=Example, O=Example, L=Mountain View, ST=California, C=US"

# Add and Build Javascript Client tutorials to web directory so we can test it from a browser,
# TODO pull in built tutorials when they are released

RUN set -ex \
  && for key in \
    9554F04D7259F04124DE6B476D5A82AC7E37093B \
    94AE36675C464D64BAFA68DD7434390BDBE9B9C5 \
    0034A06D9D9B0064CE8ADF6BF1747F4AD2306D93 \
    FD3A5288F042B6850C66B31F09FE44734EB7990E \
    71DCFD284A79C3B38668286BC97EC7A07EDE3FC1 \
    DD8F2338BAE7501E3DD5AC78C273792F7D83545D \
    B9AE9905FFD7803F25714661B63B535A4C206CA9 \
    C4F0DFFF4E8C1A8236409D08E73BC641CC11F4C8 \
  ; do \
    gpg --keyserver ha.pool.sks-keyservers.net --recv-keys "$key"; \
  done

ENV NODE_VERSION 0.10.45

RUN curl -LOk  https://github.com/kaazing/javascript.client.tutorials/files/324463/websocket-amqp-tutorial.zip \
    && unzip ./websocket-amqp-tutorial.zip \
    && mkdir -p ./web/javascript.client.tutorials/amqp \
    && cp -r ./websocket-amqp-tutorial/* ./web/javascript.client.tutorials/amqp/

# Add rabbitmq client libs
ADD https://github.com/rabbitmq/rabbitmq-server/releases/download/rabbitmq_v3_6_2/rabbitmq-java-client-bin-3.6.2.tar.gz lib/ext/

# Add gateway config
COPY amqp-rabbitmq-gateway-config.xml conf/gateway-config.xml

