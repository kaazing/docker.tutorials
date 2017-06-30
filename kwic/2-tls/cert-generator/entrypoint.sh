#!/bin/bash

OUTPUT_DIR=/x509
CONF_DIR=/conf

CMD_NAME=$(basename $0)

# Save the args, minus the command.
ARGS=("$@")

# Used for logging.
DATE=`date +"%Y-%m-%d %T"`

# Format date so it can be used as a filename.
DATE_SANITIZED=${DATE//:/-}
DATE_SANITIZED=${DATE_SANITIZED// /_}

LOG_DIR=${OUTPUT_DIR}/log
LOG_FILE=${LOG_DIR}/${DATE_SANITIZED}.log
# $1 is the path and filename of the cert. e.g. certs/example.com.cert.pem

SERVER_HOSTNAME=example.com

DAYS=10

SERVER_ROOT_CA_NAME=server-root-ca
SERVER_ROOT_PW=rootpass
SERVER_ROOT_SUBJECT="/C=US/ST=California/O=Kaazing/OU=Kaazing Demo Server CA/CN=Kaazing Demo Server Root CA"

SERVER_SIGNING_CA_NAME=server-signing-ca
SERVER_SIGNING_PW=signingpass
SERVER_SIGNING_SUBJECT="/C=US/ST=California/O=Kaazing/OU=Kaazing Demo Server CA/CN=Kaazing Demo Server Signing CA"

SERVER_SUBJECT="/C=US/ST=California/O=Kaazing/OU=Kaazing Demo/CN=*.${SERVER_HOSTNAME}"

KEYSTORE_NAME=keystore
KEYSTORE_PW=ab987c
TRUSTSTORE_NAME=truststore
TRUSTSTORE_PW=changeit
TRUST_CA_ALIAS=kaazingdemoserverca

# $1 is the path and filename of the cert. e.g. certs/example.com.cert.pem
function print_cert()
{
  CERT=$1
  echo ""
  echo "------------------------------------------------------------------------------"
  echo "Printing certificate ${CERT}"
  echo "------------------------------------------------------------------------------"
  openssl x509 -noout -text -in ${CERT}
}

# $1 is the path and filename of the ca cert or chain bundle. e.g. private/rootca.cert.pem
# $2 is the path and filename of the server cert. e.g. certs/example.com.cert.pem
function verify_chain_of_trust()
{
  CA_CERT=$1
  SERVER_CERT=$2
  echo ""
  echo "------------------------------------------------------------------------------"
  echo "Verifying chain of trust for ${SERVER_CERT} using ${CA_CERT}"
  echo "------------------------------------------------------------------------------"
  # openssl verify -verbose -purpose sslserver -policy_check -CAfile ${CA_CERT} ${SERVER_CERT}
  openssl verify -verbose -policy_check -CAfile ${CA_CERT} ${SERVER_CERT}
}

function create_root_ca()
{

  # This environment variable is referenced in the openssl conf file, so must be exported.
  export ROOT_CA=$1

  ROOT_PW=$2
  ROOT_SUBJECT=$3

  ROOT_KEY=${OUTPUT_DIR}/ca/${ROOT_CA}/private/${ROOT_CA}.key
  ROOT_CSR=${OUTPUT_DIR}/ca/${ROOT_CA}.csr
  ROOT_CERT=${OUTPUT_DIR}/ca/${ROOT_CA}.crt
  ROOT_CRL=${OUTPUT_DIR}/crl/${ROOT_CA}.crl
  ROOT_DER=${OUTPUT_DIR}/ca/${ROOT_CA}.der

  mkdir -p ${OUTPUT_DIR}/ca/${ROOT_CA}/private \
           ${OUTPUT_DIR}/ca/${ROOT_CA}/db \
           ${OUTPUT_DIR}/crl \
           ${OUTPUT_DIR}/certs
  # chmod 700 ca/${ROOT_CA}/private

  # Create database, if it doesn't exist
  if [ ! -f ${OUTPUT_DIR}/ca/${ROOT_CA}/db/${ROOT_CA}.db ]; then
    cp /dev/null ${OUTPUT_DIR}/ca/${ROOT_CA}/db/${ROOT_CA}.db
    cp /dev/null ${OUTPUT_DIR}/ca/${ROOT_CA}/db/${ROOT_CA}.db.attr
    echo 01 > ${OUTPUT_DIR}/ca/${ROOT_CA}/db/${ROOT_CA}.crt.srl
    echo 01 > ${OUTPUT_DIR}/ca/${ROOT_CA}/db/${ROOT_CA}.crl.srl
  fi

  echo ""
  echo "------------------------------------------------------------------------------"
  echo "Root CA: Creating the keypair: ${ROOT_KEY}"
  echo "------------------------------------------------------------------------------"
  openssl genrsa -aes256 -passout pass:${ROOT_PW} -out ${ROOT_KEY} 4096

  if (( $? )); then echo -e "\nSomething went wrong, exiting" >&2; exit 1; fi

  echo ""
  echo "------------------------------------------------------------------------------"
  echo "Root CA: Creating the signing request: ${ROOT_CSR}"
  echo "------------------------------------------------------------------------------"
  openssl req -new \
              -config ${CONF_DIR}/root-ca.conf \
              -key ${ROOT_KEY} -passin pass:${ROOT_PW} \
              -subj "${ROOT_SUBJECT}" \
              -out ${ROOT_CSR}

  if (( $? )); then echo -e "\nSomething went wrong, exiting" >&2; exit 1; fi

  echo ""
  echo "------------------------------------------------------------------------------"
  echo "Root CA: Creating the certificate (CSR self-signed): ${ROOT_CERT}"
  echo "------------------------------------------------------------------------------"
  openssl ca -selfsign \
             -config ${CONF_DIR}/root-ca.conf \
             -extensions root_ca_ext \
             -days ${DAYS}  \
             -in ${ROOT_CSR} \
             -passin pass:${ROOT_PW} -batch \
             -out ${ROOT_CERT}

  if (( $? )); then echo -e "\nSomething went wrong, exiting" >&2; exit 1; fi

  #print_cert ${ROOT_CERT}
}

function create_signing_ca()
{

  # This environment variable is referenced in the openssl conf file, so must be exported.
  export SIGNING_CA=$1

  SIGNING_PW=$2
  SIGNING_SUBJECT=$3

  SIGNING_KEY=${OUTPUT_DIR}/ca/${SIGNING_CA}/private/${SIGNING_CA}.key
  SIGNING_CSR=${OUTPUT_DIR}/ca/${SIGNING_CA}.csr
  SIGNING_CERT=${OUTPUT_DIR}/ca/${SIGNING_CA}.crt
  SIGNING_CRL=${OUTPUT_DIR}/crl/${SIGNING_CA}.crl
  SIGNING_DER=${OUTPUT_DIR}/ca/${SIGNING_CA}.der

  SIGNING_CHAIN=${OUTPUT_DIR}/ca/${SIGNING_CA}-chain.pem

  # Create directories"
  mkdir -p ${OUTPUT_DIR}/ca/${SIGNING_CA}/private \
           ${OUTPUT_DIR}/ca/${SIGNING_CA}/db \
           ${OUTPUT_DIR}/crl \
           ${OUTPUT_DIR}/certs\
           ${OUTPUT_DIR}/pkcs12
  # chmod 700 ca/${SIGNING_CA}/private

  # Create database"
  if [ ! -f ${OUTPUT_DIR}/ca/${SIGNING_CA}/db/${SIGNING_CA}.db ]; then
    cp /dev/null ${OUTPUT_DIR}/ca/${SIGNING_CA}/db/${SIGNING_CA}.db
    cp /dev/null ${OUTPUT_DIR}/ca/${SIGNING_CA}/db/${SIGNING_CA}.db.attr
    echo 01 > ${OUTPUT_DIR}/ca/${SIGNING_CA}/db/${SIGNING_CA}.crt.srl
    echo 01 > ${OUTPUT_DIR}/ca/${SIGNING_CA}/db/${SIGNING_CA}.crl.srl
  fi

  echo ""
  echo "------------------------------------------------------------------------------"
  echo "Signing CA: Creating the keypair: ${SIGNING_KEY}"
  echo "------------------------------------------------------------------------------"
  openssl genrsa -aes256 -passout pass:${SIGNING_PW} -out ${SIGNING_KEY} 4096

  if (( $? )); then echo -e "\nSomething went wrong, exiting" >&2; exit 1; fi

  echo ""
  echo "------------------------------------------------------------------------------"
  echo "Signing CA: Creating the signing request: ${SIGNING_CSR}"
  echo "------------------------------------------------------------------------------"
  # TODO: Make -subj into a variable
  openssl req -new \
              -config ${CONF_DIR}/signing-ca.conf \
              -key ${SIGNING_KEY} -passin pass:${SIGNING_PW} \
              -subj "${SIGNING_SUBJECT}" \
              -out ${SIGNING_CSR}

  if (( $? )); then echo -e "\nSomething went wrong, exiting" >&2; exit 1; fi

  echo ""
  echo "------------------------------------------------------------------------------"
  echo "Signing CA: Creating the certificate (CSR signed with root CA): ${SIGNING_CERT}"
  echo "------------------------------------------------------------------------------"
  openssl ca -config ${CONF_DIR}/root-ca.conf \
             -extensions signing_ca_ext \
             -days ${DAYS}  \
             -in ${SIGNING_CSR} \
             -passin pass:${ROOT_PW} -batch \
             -out ${SIGNING_CERT}

  if (( $? )); then echo -e "\nSomething went wrong, exiting" >&2; exit 1; fi

  #print_cert ${SIGNING_CERT}

  echo ""
  echo "------------------------------------------------------------------------------"
  echo "Signing CA: Create the certificate chain: ${SIGNING_CHAIN}"
  echo "------------------------------------------------------------------------------"
  cat ${SIGNING_CERT} ${ROOT_CERT} > ${SIGNING_CHAIN}

}

function create_server_cert()
{

  SERVER_KEY=${OUTPUT_DIR}/certs/${SERVER_HOSTNAME}.key
  SERVER_CSR=${OUTPUT_DIR}/certs/${SERVER_HOSTNAME}.csr
  SERVER_CERT=${OUTPUT_DIR}/certs/${SERVER_HOSTNAME}.crt

  KEYSTORE=${OUTPUT_DIR}/stores/${KEYSTORE_NAME}-cloud.jceks
  KEYSTORE_PW_FILE=${OUTPUT_DIR}/stores/${KEYSTORE_NAME}-cloud.pw
  TRUSTSTORE=${OUTPUT_DIR}/stores/${TRUSTSTORE_NAME}-onprem.jceks
  TRUSTSTORE_PW_FILE=${OUTPUT_DIR}/stores/${TRUSTSTORE_NAME}-onprem.pw

  mkdir -p ${OUTPUT_DIR}/stores

  # This environment variable is referenced in the openssl conf file, so must be exported.
  export SAN="DNS:${SERVER_HOSTNAME},DNS:*.${SERVER_HOSTNAME},DNS:example.net,DNS:*.example.net,DNS:example.org,DNS:*.example.org"

  echo ""
  echo "------------------------------------------------------------------------------"
  echo "Server cert: Creating the certificate signing request: ${SERVER_CSR}"
  echo "------------------------------------------------------------------------------"
  openssl req -new \
              -config ${CONF_DIR}/server.conf \
              -keyout ${SERVER_KEY} \
              -subj "${SERVER_SUBJECT}" \
              -out ${SERVER_CSR}

  if (( $? )); then echo -e "\nSomething went wrong, exiting" >&2; exit 1; fi

  echo ""
  echo "------------------------------------------------------------------------------"
  echo "Server cert: Creating the certificate (CSR signed with signing CA): ${SERVER_CERT}"
  echo "------------------------------------------------------------------------------"
  openssl ca -config ${CONF_DIR}/signing-ca.conf \
             -extensions server_ext \
             -days ${DAYS}  \
             -passin pass:${SIGNING_PW} -batch \
             -in ${SERVER_CSR} \
             -out ${SERVER_CERT}

  if (( $? )); then echo -e "\nSomething went wrong, exiting" >&2; exit 1; fi

  #print_cert ${SERVER_CERT}

  #verify_chain_of_trust ${SIGNING_CHAIN} ${SERVER_CERT}

  PKCS12=${OUTPUT_DIR}/pkcs12/${SERVER_HOSTNAME}.key.p12

  echo ""
  echo "------------------------------------------------------------------------------"
  echo "Server cert: Converting key and certificate to PKCS12 format: ${PKCS12}"
  echo "------------------------------------------------------------------------------"
  openssl pkcs12 -export \
                 -in ${SERVER_CERT} -inkey ${SERVER_KEY} \
                 -out ${PKCS12} -passout pass:${KEYSTORE_PW} \
                 -name ${SERVER_HOSTNAME}

  if (( $? )); then echo -e "\nSomething went wrong, exiting" >&2; exit 1; fi

  echo ""
  echo "------------------------------------------------------------------------------"
  echo "Server cert: Importing the PCKS12 file (containing the key and certificate) into the keystore ${KEYSTORE}"
  echo "------------------------------------------------------------------------------"
  keytool -importkeystore \
          -srckeystore ${PKCS12} -srcstorepass ${KEYSTORE_PW} -srcstoretype pkcs12 -srcalias ${SERVER_HOSTNAME} \
          -destkeystore ${KEYSTORE} -storepass ${KEYSTORE_PW} -deststoretype JCEKS \
          -destalias ${SERVER_HOSTNAME} \
          -noprompt

  if (( $? )); then echo -e "\nSomething went wrong, exiting" >&2; exit 1; fi

  echo ""
  echo "------------------------------------------------------------------------------"
  echo "Server cert: Saving keystore password file: ${KEYSTORE_PW_FILE}"
  echo "------------------------------------------------------------------------------"
  echo ${KEYSTORE_PW} > ${KEYSTORE_PW_FILE}

  if (( $? )); then echo -e "\nSomething went wrong, exiting" >&2; exit 1; fi

  echo ""
  echo "------------------------------------------------------------------------------"
  echo "Server cert: Importing the CA into the truststore ${TRUSTSTORE}"
  echo "------------------------------------------------------------------------------"
  keytool -importcert -trustcacerts  -noprompt \
          -keystore ${TRUSTSTORE} -storepass ${TRUSTSTORE_PW} \
          -file ${SIGNING_CERT} -alias ${TRUST_CA_ALIAS} \
          -noprompt

  if (( $? )); then echo -e "\nSomething went wrong, exiting" >&2; exit 1; fi

  echo ""
  echo "------------------------------------------------------------------------------"
  echo "Server cert: Saving truststore password file: ${TRUSTSTORE_PW_FILE}"
  echo "------------------------------------------------------------------------------"
  echo ${TRUSTSTORE_PW} > ${TRUSTSTORE_PW_FILE}

  if (( $? )); then echo -e "\nSomething went wrong, exiting" >&2; exit 1; fi

  echo ""
  echo "------------------------------------------------------------------------------"
  echo "Server cert: Listing of ${KEYSTORE}"
  echo "------------------------------------------------------------------------------"
  keytool -list -keystore ${KEYSTORE} -storepass ${KEYSTORE_PW} -storetype JCEKS

  if (( $? )); then echo -e "\nSomething went wrong, exiting" >&2; exit 1; fi

  echo ""
  echo "------------------------------------------------------------------------------"
  echo "Server cert: Listing of ${TRUSTSTORE}"
  echo "------------------------------------------------------------------------------"
  keytool -list -keystore ${TRUSTSTORE} -storepass ${TRUSTSTORE_PW} -storetype JCEKS

  if (( $? )); then echo -e "\nSomething went wrong, exiting" >&2; exit 1; fi
}

function main()
{
  echo ""
  echo "Everything will be logged to: ${LOG_FILE}"

  echo `ls -R ${OUTPUT_DIR}`

  # This environment variable is referenced in the openssl conf file, so must be exported.
  export WORK_DIR=${OUTPUT_DIR}

  create_root_ca ${SERVER_ROOT_CA_NAME} ${SERVER_ROOT_PW} "${SERVER_ROOT_SUBJECT}"
  create_signing_ca ${SERVER_SIGNING_CA_NAME} ${SERVER_SIGNING_PW} "${SERVER_SIGNING_SUBJECT}"
  create_server_cert
}

mkdir -p ${LOG_DIR}
main 2>&1 | tee -a ${LOG_FILE}
