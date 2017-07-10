BUild the image:

```bash
$ docker build -t ca-generator:root .
```

To see the parameters:

```bash
$ docker run --rm --name ca-generator-container ca-generator:root --help
```

Accept the defaults:

```bash
$ docker run --rm -v `pwd`/root-ca:/certs --name ca-generator-container ca-generator:root
```

To set your own values:

```bash
$ docker run --rm -v `pwd`/root-ca:/certs --name ca-generator-container ca-generator:root \
     --root-key    ca.key.pem \
     --root-cert   ca.cert.pem \
     --ca-password capass \
     --days        365 \
     --country     US \
     --state       California \
     --org         Kaazing \
     --org-unit    "Kaazing Demo Certificate Authority" \
     --common-name "Kaazing Demo Root CA"
```

Using a named volume:

docker run --rm -v `pwd`/root-ca:/certs --name ca-generator-container ca-generator:root

Copy the generared files:

docker cp ca-generator-container:/certs /tmp/b

Remove the container:

docker rm ca-generator-container
