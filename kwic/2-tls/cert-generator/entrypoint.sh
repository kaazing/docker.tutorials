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
CLIENT_ALIAS=tenant101

DAYS=10

SERVER_ROOT_CA_NAME=server-root-ca
SERVER_ROOT_PW=rootpass
SERVER_ROOT_SUBJECT="/C=US/ST=California/O=Kaazing/OU=Kaazing Demo Server CA/CN=Kaazing Demo Server Root CA"

SERVER_CERT_SUBJECT="/C=US/ST=California/O=Kaazing/OU=Kaazing Demo/CN=*.${SERVER_HOSTNAME}"
SERVER_CA_ALIAS=kaazingdemoserverca

CLIENT_ROOT_CA_NAME=client-root-ca
CLIENT_ROOT_PW=rootpass
CLIENT_ROOT_SUBJECT="/C=US/ST=California/O=Kaazing/OU=Kaazing Demo Client CA/CN=Kaazing Demo Client Root CA"

CLIENT_CERT_SUBJECT="/C=US/ST=California/O=Kaazing/OU=Kaazing Demo/CN=tenant101"
CLIENT_CA_ALIAS=kaazingdemoclientca

KEYSTORE_NAME=keystore
KEYSTORE_PW=ab987c
TRUSTSTORE_NAME=truststore
TRUSTSTORE_PW=changeit

#############################################################################

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

#############################################################################

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

#############################################################################

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
           ${OUTPUT_DIR}/certs \
           ${OUTPUT_DIR}/pkcs12
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
  echo "${ROOT_CA}: Creating the keypair: ${ROOT_KEY}"
  echo "------------------------------------------------------------------------------"
  openssl genrsa -aes256 -passout pass:${ROOT_PW} -out ${ROOT_KEY} 4096

  if (( $? )); then echo -e "\nSomething went wrong, exiting" >&2; exit 1; fi

  echo ""
  echo "------------------------------------------------------------------------------"
  echo "${ROOT_CA}: Creating the signing request: ${ROOT_CSR}"
  echo "------------------------------------------------------------------------------"
  openssl req -new \
              -config ${CONF_DIR}/root-ca.conf \
              -key ${ROOT_KEY} -passin pass:${ROOT_PW} \
              -subj "${ROOT_SUBJECT}" \
              -out ${ROOT_CSR}

  if (( $? )); then echo -e "\nSomething went wrong, exiting" >&2; exit 1; fi

  echo ""
  echo "------------------------------------------------------------------------------"
  echo "${ROOT_CA}: Creating the certificate (CSR self-signed): ${ROOT_CERT}"
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

#############################################################################

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
              -subj "${SERVER_CERT_SUBJECT}" \
              -out ${SERVER_CSR}

  if (( $? )); then echo -e "\nSomething went wrong, exiting" >&2; exit 1; fi

  echo ""
  echo "------------------------------------------------------------------------------"
  echo "Server cert: Creating the certificate (CSR signed with signing CA): ${SERVER_CERT}"
  echo "------------------------------------------------------------------------------"
  openssl ca -config ${CONF_DIR}/root-ca.conf \
             -extensions server_ext \
             -days ${DAYS}  \
             -passin pass:${ROOT_PW} -batch \
             -in ${SERVER_CSR} \
             -out ${SERVER_CERT}

  if (( $? )); then echo -e "\nSomething went wrong, exiting" >&2; exit 1; fi

  #print_cert ${SERVER_CERT}

  verify_chain_of_trust ${ROOT_CERT} ${SERVER_CERT}

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
          -file ${ROOT_CERT} -alias ${SERVER_CA_ALIAS} \
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

#############################################################################

function create_client_cert()
{

  CLIENT_KEY=${OUTPUT_DIR}/certs/${CLIENT_ALIAS}.key
  CLIENT_CSR=${OUTPUT_DIR}/certs/${CLIENT_ALIAS}.csr
  CLIENT_CERT=${OUTPUT_DIR}/certs/${CLIENT_ALIAS}.crt

  KEYSTORE=${OUTPUT_DIR}/stores/${KEYSTORE_NAME}-onprem.jceks
  KEYSTORE_PW_FILE=${OUTPUT_DIR}/stores/${KEYSTORE_NAME}-onprem.pw
  TRUSTSTORE=${OUTPUT_DIR}/stores/${TRUSTSTORE_NAME}-cloud.jceks
  TRUSTSTORE_PW_FILE=${OUTPUT_DIR}/stores/${TRUSTSTORE_NAME}-cloud.pw

  mkdir -p ${OUTPUT_DIR}/stores

  echo ""
  echo "------------------------------------------------------------------------------"
  echo "Client cert: Creating the certificate signing request: ${CLIENT_CSR}"
  echo "------------------------------------------------------------------------------"
  openssl req -new \
              -config ${CONF_DIR}/client.conf \
              -keyout ${CLIENT_KEY} \
              -subj "${CLIENT_CERT_SUBJECT}" \
              -out ${CLIENT_CSR}

  if (( $? )); then echo -e "\nSomething went wrong, exiting" >&2; exit 1; fi

  echo ""
  echo "------------------------------------------------------------------------------"
  echo "Client cert: Creating the certificate (CSR signed with signing CA): ${CLIENT_CERT}"
  echo "------------------------------------------------------------------------------"
  openssl ca -config ${CONF_DIR}/root-ca.conf \
             -extensions client_ext \
             -days ${DAYS}  \
             -passin pass:${ROOT_PW} -batch \
             -in ${CLIENT_CSR} \
             -out ${CLIENT_CERT}

  if (( $? )); then echo -e "\nSomething went wrong, exiting" >&2; exit 1; fi

  #print_cert ${CLIENT_CERT}

  verify_chain_of_trust ${ROOT_CERT} ${CLIENT_CERT}

  PKCS12=${OUTPUT_DIR}/pkcs12/${CLIENT_ALIAS}.key.p12

  echo ""
  echo "------------------------------------------------------------------------------"
  echo "Client cert: Converting key and certificate to PKCS12 format: ${PKCS12}"
  echo "------------------------------------------------------------------------------"
  openssl pkcs12 -export \
                 -in ${CLIENT_CERT} -inkey ${CLIENT_KEY} \
                 -out ${PKCS12} -passout pass:${KEYSTORE_PW} \
                 -name ${CLIENT_ALIAS}

  if (( $? )); then echo -e "\nSomething went wrong, exiting" >&2; exit 1; fi

  echo ""
  echo "------------------------------------------------------------------------------"
  echo "Client cert: Importing the PCKS12 file (containing the key and certificate) into the keystore ${KEYSTORE}"
  echo "------------------------------------------------------------------------------"
  keytool -importkeystore \
          -srckeystore ${PKCS12} -srcstorepass ${KEYSTORE_PW} -srcstoretype pkcs12 -srcalias ${CLIENT_ALIAS} \
          -destkeystore ${KEYSTORE} -storepass ${KEYSTORE_PW} -deststoretype JCEKS \
          -destalias ${CLIENT_ALIAS} \
          -noprompt

  if (( $? )); then echo -e "\nSomething went wrong, exiting" >&2; exit 1; fi

  echo ""
  echo "------------------------------------------------------------------------------"
  echo "Client cert: Saving keystore password file: ${KEYSTORE_PW_FILE}"
  echo "------------------------------------------------------------------------------"
  echo ${KEYSTORE_PW} > ${KEYSTORE_PW_FILE}

  if (( $? )); then echo -e "\nSomething went wrong, exiting" >&2; exit 1; fi

  echo ""
  echo "------------------------------------------------------------------------------"
  echo "Client cert: Importing the CA into the truststore ${TRUSTSTORE}"
  echo "------------------------------------------------------------------------------"
  keytool -importcert -trustcacerts  -noprompt \
          -keystore ${TRUSTSTORE} -storepass ${TRUSTSTORE_PW} \
          -file ${ROOT_CERT} -alias ${CLIENT_CA_ALIAS} \
          -noprompt

  if (( $? )); then echo -e "\nSomething went wrong, exiting" >&2; exit 1; fi

  echo ""
  echo "------------------------------------------------------------------------------"
  echo "Client cert: Saving truststore password file: ${TRUSTSTORE_PW_FILE}"
  echo "------------------------------------------------------------------------------"
  echo ${TRUSTSTORE_PW} > ${TRUSTSTORE_PW_FILE}

  if (( $? )); then echo -e "\nSomething went wrong, exiting" >&2; exit 1; fi

  echo ""
  echo "------------------------------------------------------------------------------"
  echo "Client cert: Listing of ${KEYSTORE}"
  echo "------------------------------------------------------------------------------"
  keytool -list -keystore ${KEYSTORE} -storepass ${KEYSTORE_PW} -storetype JCEKS

  if (( $? )); then echo -e "\nSomething went wrong, exiting" >&2; exit 1; fi

  echo ""
  echo "------------------------------------------------------------------------------"
  echo "Client cert: Listing of ${TRUSTSTORE}"
  echo "------------------------------------------------------------------------------"
  keytool -list -keystore ${TRUSTSTORE} -storepass ${TRUSTSTORE_PW} -storetype JCEKS

  if (( $? )); then echo -e "\nSomething went wrong, exiting" >&2; exit 1; fi
}

#############################################################################

function main()
{
  echo ""
  echo "Everything will be logged to: ${LOG_FILE}"

  echo `ls -R ${OUTPUT_DIR}`

  # This environment variable is referenced in the openssl conf file, so must be exported.
  export WORK_DIR=${OUTPUT_DIR}

  create_root_ca ${SERVER_ROOT_CA_NAME} ${SERVER_ROOT_PW} "${SERVER_ROOT_SUBJECT}"
  create_server_cert

  create_root_ca ${CLIENT_ROOT_CA_NAME} ${CLIENT_ROOT_PW} "${CLIENT_ROOT_SUBJECT}"
  create_client_cert

  echo ""
  echo "All done"
}

#############################################################################

mkdir -p ${LOG_DIR}
main 2>&1 | tee -a ${LOG_FILE}
