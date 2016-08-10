FROM kaazing/development-enterprise-gateway:5.1.0-RC004

# Generate Keystore entry for kaazing.example.com

RUN keytool -genkeypair -keystore conf/keystore.db -storetype JCEKS -keypass ab987c -storepass ab987c -alias kaazing.example.com -keyalg RSA -dname "CN=kaazing.example.com, OU=Example, O=Example, L=Mountain View, ST=California, C=US"

RUN  curl -L --insecure `curl -sL https://github.com/kaazing/javascript.client.tutorials/releases/latest | grep -i websocket-jms-tutorial.zip | cut -d '"' -f 2 -` -o ./web/websocket-jms-tutorial.zip
RUN  unzip ./web/websocket-jms-tutorial.zip -d ./web
# Add gateway config
COPY jms-redis-gateway-config.xml conf/gateway-config.xml

ADD http://central.maven.org/maven2/org/apache/geronimo/specs/geronimo-jms_1.1_spec/1.1/geronimo-jms_1.1_spec-1.1.jar lib/ext/
