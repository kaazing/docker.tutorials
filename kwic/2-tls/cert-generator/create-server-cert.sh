#!/bin/bash

OUTPUT_DIR=/x509

SERVER_HOSTNAME=example.com

ROOT_CA_NAME=root-ca
ROOT_PW=rootpass
ROOT_SUBJECT="/C=US/ST=California/O=Kaazing/OU=Kaazing Demo Certificate Authority/CN=Kaazing Demo Root CA"

SIGNING_CA_NAME=signing-ca
SIGNING_PW=signingpass
SIGNING_SUBJECT="/C=US/ST=California/O=Kaazing/OU=Kaazing Demo Certificate Authority/CN=Kaazing Demo Signing CA"

DAYS=1

SERVER_KEY=certs/${SERVER_HOSTNAME}.key
SERVER_CSR=certs/${SERVER_HOSTNAME}.csr
SERVER_CERT=certs/${SERVER_HOSTNAME}.crt
SERVER_SUBJECT="/C=US/ST=California/O=Kaazing/OU=Kaazing Demo/CN=*.${SERVER_HOSTNAME}"

# Save the args, minus the command.
ARGS=("$@")

function usage()
{
  echo ""
  echo "  Options:"
  echo ""
  echo "    --root-ca              The name of the root CA"
  echo "    --root-ca-password     Password for the root CA"
  echo "    --root-ca-subject      The subject DN of the root CA certificate"
  echo "    --signing-ca           The name of the signing CA"
  echo "    --signing-ca-password  Password for the signing CA"
  echo "    --signing-ca-subject   The subject DN of the signing CA certificate"
  echo "    --days                 Number of days the CAs are valid for"
  echo "    --server-cert-subject  The subject DN of the server certificate"
  echo ""
  echo "  Example (showing default values):"
  echo ""
  echo "    --root-ca              root-ca"
  echo "    --root-ca-password     rootpass"
  echo "    --root-ca-subject      \"/C=US/ST=California/O=Kaazing/OU=Kaazing Demo Certificate Authority/CN=Kaazing Demo Root CA\""
  echo "    --signing-ca           signing-ca"
  echo "    --signing-ca-password  signingpass"
  echo "    --signing-ca-subject   \"/C=US/ST=California/O=Kaazing/OU=Kaazing Demo Certificate Authority/CN=Kaazing Demo Signing CA\""
  echo "    --days                 1"
  echo "    --server-ca-subject    \"/C=US/ST=California/O=Kaazing/OU=Kaazing Demo/CN=*.example.com\""
}

# Check if a variable is present, and error if it is not.
# $1 is the variable containing the argument ${CA_KEY_NAME}
# $2 is the argument name. e.g. --ca-key
function check_mandatory_arg
{
  if [ -z "${1}" ]
  then
    if [ -z "${MISSING_ARG}" ]; then echo ""; fi
    echo "Missing argument: ${2}"
    MISSING_ARG="true"
  fi
}

function process_args
{

  local n=${#ARGS[@]}

  # if (( ${n} > 0 ))
  # then

    i=$((0))
    while [ ${i} -lt ${n} ];
    do
      PARAM=${ARGS[${i}]}

      case ${PARAM} in
        -h | --help)
          usage
          exit 0
          ;;
        --root-ca)
          i=$((i+1)); ROOT_CA_NAME=${ARGS[${i}]}
          ;;
        --root-ca-password)
          i=$((i+1)); ROOT_PW=${ARGS[${i}]}
          ;;
        --root-ca-subject)
          i=$((i+1)); ROOT_SUBJECT=${ARGS[${i}]}
          ;;
        --signing-ca)
          i=$((i+1)); SIGNING_CA_NAME=${ARGS[${i}]}
          ;;
        --signing-ca-password)
          i=$((i+1)); SIGNING_PW=${ARGS[${i}]}
          ;;
        --signing-ca-subject)
          i=$((i+1)); SIGNING_SUBJECT=${ARGS[${i}]}
          ;;
        --days)
          i=$((i+1)); DAYS=${ARGS[${i}]}
          ;;
        --server-ca-subject)
          i=$((i+1)); SERVER_SUBJECT=${ARGS[${i}]}
          ;;
        *)
          echo "ERROR: unknown parameter \"${PARAM}\""
          usage
          exit 1
          ;;
      esac

      i=$((i+1))
    done

  # else
  #
  #   usage
  #   exit 0
  #
  # fi

  # check_mandatory_arg "${ROOT_CA_NAME}"     "--root-ca"
  # check_mandatory_arg "${ROOT_PW}"          "--root-ca-password"
  # check_mandatory_arg "${ROOT_SUBJECT}"     "--root-ca-subject"
  # check_mandatory_arg "${SIGNING_CA_NAME}"  "--signing-ca"
  # check_mandatory_arg "${SIGNING_PW}"       "--signing-ca-password"
  # check_mandatory_arg "${SIGNING_SUBJECT}"  "--signing-ca-subject"
  # check_mandatory_arg "${DAYS}"             "--days"
  # check_mandatory_arg "${SERVER_SUBJECT}"   "--server-ca-subject"
  #
  # # By exiting here, it will show all error messages, rather than one at a time.
  # if [ "${MISSING_ARG}" ]
  # then
  #   usage
  #   exit 1
  # fi

}

function print_settings()
{
  echo -e "  Command:     ${COMMAND}"
  echo -e "  Output dir:  ${OUTPUT_DIR}"
  echo -e "  CA:"
  echo -e "    Key:       ${CA_KEY}\t[Password: ${CA_PW}]"
  echo -e "    Cert:      ${CA_CERT}\t[Valid for: ${CA_DAYS} days]"
  echo -e "    Subject:   ${CA_SUBJECT}"
  echo -e "  Server:"
  echo -e "    Key:       ${KEY}"
  echo -e "    Cert:      ${CERT}\t[Valid for: ${SERVER_DAYS} days]"
  echo -e "    Subject:   ${SERVER_SUBJECT}"
  echo -e "    SAN:       ${SAN}"
  echo -e "  Keystore:    ${KEYSTORE}\t[Password: ${KEYSTORE_PW}, Alias: ${SERVER_HOSTNAME}]"
  echo -e "  Truststore:  ${TRUSTSTORE}\t[Password: ${TRUSTSTORE_PW}, Alias: ${TRUST_CA_ALIAS}]"
}

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

# $1 is the path and filename of the crl. e.g. x509/crl/root-ca.crl
# More info: https://langui.sh/2010/01/10/parsing-a-crl-with-openssl/
function print_crl()
{
  CRL=$1
  echo ""
  echo "------------------------------------------------------------------------------"
  echo "Printing CRL ${CRL}"
  echo "------------------------------------------------------------------------------"
  openssl crl -text -noout -in ${CRL}
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
  openssl verify -verbose -purpose sslserver -policy_check -CAfile ${CA_CERT} ${SERVER_CERT}
}

function create_root_ca()
{

  # This environment variable is referenced in the openssl conf file
  export ROOT_CA=$1

  ROOT_KEY=ca/${ROOT_CA}/private/${ROOT_CA}.key
  ROOT_CSR=ca/${ROOT_CA}.csr
  ROOT_CERT=ca/${ROOT_CA}.crt
  ROOT_CRL=crl/${ROOT_CA}.crl
  ROOT_DER=ca/${ROOT_CA}.der

  # Create directories"
  mkdir -p ca/${ROOT_CA}/private ca/${ROOT_CA}/db crl certs
  # chmod 700 ca/${ROOT_CA}/private

  # Create database, if it doesn't exist
  if [ ! -f ca/${ROOT_CA}/db/${ROOT_CA}.db ]; then
    cp /dev/null ca/${ROOT_CA}/db/${ROOT_CA}.db
    cp /dev/null ca/${ROOT_CA}/db/${ROOT_CA}.db.attr
    echo 01 > ca/${ROOT_CA}/db/${ROOT_CA}.crt.srl
    echo 01 > ca/${ROOT_CA}/db/${ROOT_CA}.crl.srl
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
      -config ../conf/root-ca.conf \
      -key ${ROOT_KEY} -passin pass:${ROOT_PW} \
      -subj "${ROOT_SUBJECT}" \
      -out ${ROOT_CSR}

  if (( $? )); then echo -e "\nSomething went wrong, exiting" >&2; exit 1; fi

  echo ""
  echo "------------------------------------------------------------------------------"
  echo "Root CA: Creating the certificate (CSR self-signed): ${ROOT_CERT}"
  echo "------------------------------------------------------------------------------"
  openssl ca  -selfsign \
      -config ../conf/root-ca.conf \
      -extensions root_ca_ext \
      -days ${DAYS}  \
      -in ${ROOT_CSR} \
      -passin pass:${ROOT_PW} -batch \
      -out ${ROOT_CERT}

  if (( $? )); then echo -e "\nSomething went wrong, exiting" >&2; exit 1; fi

  # print_cert ${ROOT_CERT}

  echo ""
  echo "------------------------------------------------------------------------------"
  echo "Root CA: Creating initial CRL: ${ROOT_CRL}"
  echo "------------------------------------------------------------------------------"
  openssl ca -gencrl \
      -config ../conf/root-ca.conf \
      -passin pass:${ROOT_PW} \
      -out ${ROOT_CRL}

  if (( $? )); then echo -e "\nSomething went wrong, exiting" >&2; exit 1; fi

  # print_crl ${ROOT_CRL}

  echo ""
  echo "------------------------------------------------------------------------------"
  echo "Root CA: Creating DER certificate for publishing: ${ROOT_DER}"
  echo "------------------------------------------------------------------------------"
  # All published certificates must be in DER format. MIME type: application/pkix-cert. [RFC 2585#section-4.1]
  openssl x509 \
      -in ${ROOT_CERT} \
      -out ${ROOT_DER} \
      -outform der

  if (( $? )); then echo -e "\nSomething went wrong, exiting" >&2; exit 1; fi

}

function create_signing_ca()
{

  # This environment variable is referenced in the conf file
  export SIGNING_CA=$1

  SIGNING_KEY=ca/${SIGNING_CA}/private/${SIGNING_CA}.key
  SIGNING_CSR=ca/${SIGNING_CA}.csr
  SIGNING_CERT=ca/${SIGNING_CA}.crt
  SIGNING_CRL=crl/${SIGNING_CA}.crl
  SIGNING_DER=ca/${SIGNING_CA}.der

  SIGNING_CHAIN=ca/${SIGNING_CA}-chain.pem

  # Create directories"
  mkdir -p ca/${SIGNING_CA}/private ca/${SIGNING_CA}/db crl certs
  # chmod 700 ca/${SIGNING_CA}/private

  # Create database"
  if [ ! -f ca/${SIGNING_CA}/db/${SIGNING_CA}.db ]; then
    cp /dev/null ca/${SIGNING_CA}/db/${SIGNING_CA}.db
    cp /dev/null ca/${SIGNING_CA}/db/${SIGNING_CA}.db.attr
    echo 01 > ca/${SIGNING_CA}/db/${SIGNING_CA}.crt.srl
    echo 01 > ca/${SIGNING_CA}/db/${SIGNING_CA}.crl.srl
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
      -config ../conf/signing-ca.conf \
      -key ${SIGNING_KEY} -passin pass:${SIGNING_PW} \
      -subj "${SIGNING_SUBJECT}" \
      -out ${SIGNING_CSR}

  if (( $? )); then echo -e "\nSomething went wrong, exiting" >&2; exit 1; fi

  echo ""
  echo "------------------------------------------------------------------------------"
  echo "Signing CA: Creating the certificate (CSR signed with root CA): ${SIGNING_CERT}"
  echo "------------------------------------------------------------------------------"
  openssl ca \
      -config ../conf/root-ca.conf \
      -extensions signing_ca_ext \
      -days ${DAYS}  \
      -in ${SIGNING_CSR} \
      -passin pass:${ROOT_PW} -batch \
      -out ${SIGNING_CERT}

  if (( $? )); then echo -e "\nSomething went wrong, exiting" >&2; exit 1; fi

  # print_cert ${SIGNING_CERT}

  echo ""
  echo "------------------------------------------------------------------------------"
  echo "Signing CA: Creating the initial CRL: ${SIGNING_CRL}"
  echo "------------------------------------------------------------------------------"
  openssl ca -gencrl \
      -config ../conf/signing-ca.conf \
      -out ${SIGNING_CRL} \
      -passin pass:${SIGNING_PW}

  if (( $? )); then echo -e "\nSomething went wrong, exiting" >&2; exit 1; fi

  # print_crl ${ROOT_CRL}

  echo ""
  echo "------------------------------------------------------------------------------"
  echo "Signing CA: Create the certificate chain: ${SIGNING_CHAIN}"
  echo "------------------------------------------------------------------------------"
  cat ${SIGNING_CERT} ${ROOT_CERT} > ${SIGNING_CHAIN}

}

function create_server_cert()
{

  echo ""
  echo "------------------------------------------------------------------------------"
  echo "Server cert: Creating the certificate signing request: ${SERVER_CSR}"
  echo "------------------------------------------------------------------------------"
  export SAN="DNS:${SERVER_HOSTNAME},DNS:*.${SERVER_HOSTNAME},DNS:example.net,DNS:*.example.net,DNS:example.org,DNS:*.example.org"
  openssl req -new \
      -config ../conf/server.conf \
      -keyout ${SERVER_KEY} \
      -subj "${SERVER_SUBJECT}" \
      -out ${SERVER_CSR}

  if (( $? )); then echo -e "\nSomething went wrong, exiting" >&2; exit 1; fi

  echo ""
  echo "------------------------------------------------------------------------------"
  echo "Server cert: Creating the certificate (CSR signed with signing CA): ${SERVER_CERT}"
  echo "------------------------------------------------------------------------------"
  openssl ca \
      -config ../conf/signing-ca.conf \
      -extensions server_ext \
      -days ${DAYS}  \
      -passin pass:${SIGNING_PW} -batch \
      -in ${SERVER_CSR} \
      -out ${SERVER_CERT}

  if (( $? )); then echo -e "\nSomething went wrong, exiting" >&2; exit 1; fi

  # print_cert ${SERVER_CERT}

}

function main()
{

  echo "I am Groot 4!"
  #echo "hello" > /x509/a.out
  echo `ls -laR /x509`
  exit 0
  process_args

  cd ${OUTPUT_DIR}

  create_root_ca ${ROOT_CA_NAME}
  create_signing_ca ${SIGNING_CA_NAME}
  create_server_cert

  echo ""
  echo "Done."

}

main 2>&1
