FROM openjdk:8-jdk-alpine

# Install bash and openssl
RUN apk add --update --no-cache bash openssl && rm -rf /var/cache/apk/*

COPY entrypoint.sh /
RUN chmod u+x /*.sh && mkdir /conf
COPY conf/* /conf/

ENTRYPOINT ["/entrypoint.sh"]
