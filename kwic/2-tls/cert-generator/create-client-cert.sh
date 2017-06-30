#!/bin/bash

# Where all the stuff goes.
OUTPUT_DIR=/x509
KEYS_DIR=private
CERTS_DIR=certs
STORES_DIR=stores

# Defaults
CA_KEY_NAME=rootca.key.pem
CA_CERT_NAME=rootca.cert.pem
CA_PW="capass"
CA_SUBJECT="/C=US/ST=California/O=Kaazing/OU=Kaazing Demo Certificate Authority/CN=Kaazing Demo Root CA"
CA_DAYS=1
SERVER_HOSTNAME=example.com
SERVER_DAYs=1
SERVER_SUBJECT="/C=US/ST=California/O=Kaazing/OU=Kaazing Demo/CN=*.${SERVER_HOSTNAME}"
KEYSTORE_NAME=keystore.jceks
KEYSTORE_PW=ab987c
TRUSTSTORE_NAME=truststore.jceks
TRUSTSTORE_PW=changeit
TRUST_CA_ALIAS=kaazingdemoca

CMD_NAME=$(basename $0)

function usage()
{
  echo ""
  echo "  Options:"
  echo ""
  echo "    --command           The operation to perform. Values: create-ca|create-es"
  echo "    --ca-key            Certificate authority keypair filename"
  echo "    --ca-cert           Certificate authority cert filename"
  echo "    --ca-password       Password for keypair and cert"
  echo "    --ca-subject-dn     The subject distinguished name of the CA certificate"
  echo "    --ca-days           Number of days the CA certificate is valid for"
  echo "    --server-hostname   The base hostname (it will be wildcarded)"
  echo "    --server-days       Number of days the server certificate is valid for"
  echo "    --server-subject-dn The subject distinguished name of the server certificate"
  echo "    --keystore          The name of the keystore file"
  echo "    --keystore-pw       The password for the keystore"
  echo "    --truststore        The name of the truststore file"
  echo "    --truststore-pw     The password for the truststore"
  echo "    --trust-ca-alias    The alias for the CA certificate put into the truststore"
  echo ""
  echo "  Example:"
  echo ""
  echo "    --command           create-ca"
  echo "    --ca-key            rootca.key.pem"
  echo "    --ca-cert           rootca.cert.pem"
  echo "    --ca-password       capass"
  echo "    --ca-days           10"
  echo "    --ca-subject-dn     \"/C=US/ST=California/O=Kaazing/OU=Kaazing Demo Certificate Authority/CN=Kaazing Demo Root CA\""
  echo "    --server-hostname   example.com"
  echo "    --server-days       10"
  echo "    --server-subject-dn \"/C=US/ST=California/O=Kaazing/OU=Kaazing Demo/CN=*.example.com\""
  echo "    --keystore          keystore.jceks"
  echo "    --keystore-pw       ab987c"
  echo "    --truststore        truststore.jceks"
  echo "    --truststore-pw     changeit"
  echo "    --trust-ca-alias    kaazingdemoca"
}

# Check if a variable is present, and error if it is not.
# $1 is the variable containing the argument ${CA_KEY_NAME}
# $2 is the argument name. e.g. --ca-key
function check_mandatory_arg
{
  if [ -z "${1}" ]
  then
    echo ""
    echo "Missing argument: ${2}"
    usage
    exit 1
  fi
}

function process_args
{

  local n=${#ARGS[@]}

  if (( ${n} > 0 ))
  then

    i=$((0))
    while [ ${i} -lt ${n} ];
    do
      PARAM=${ARGS[${i}]}

      case ${PARAM} in
        -h | --help)
          usage
          exit 0
          ;;
        --ca-key)
          i=$((i+1)); VALUE=${ARGS[${i}]}
          echo "   ${VALUE}"
          ;;
        # *)
        #   echo "ERROR: unknown parameter \"${PARAM}\""
        #   usage
        #   exit 1
        #   ;;
      esac

      i=$((i+1))
    done

  else

    usage
    exit 0

  fi
}

function process_args3
{

  # Get the number of arguments passed to this script.
  # (The BASH_ARGV array does not include $0.)
  # (The BASH_ARGV arrary is reversed, with the last argument in first position.)
  local n=${#BASH_ARGV[@]}

  if (( ${n} > 0 ))
  then

    i=$((n-1))
    while [ ${i} -ge 0 ];
    do
      PARAM=${BASH_ARGV[$i]}
      echo "${i}: ${PARAM}"

      i=$((i-1))
    done

  else
    echo "No args provided"
  fi





  # Get the number of arguments passed to this script.
  # (The BASH_ARGV array does not include $0.)
  # (The BASH_ARGV arrary is reversed, with the last argument in first position.)
  local n=${#BASH_ARGV[@]}

  if (( $n > 0 ))
  then
      # Get the last index of the args in BASH_ARGV.
      local n_index=$(( $n - 1 ))

      # Loop through the indexes from largest to smallest.
      for i in $(seq ${n_index} -2 0)
      do
        PARAM=${BASH_ARGV[$i]}
        VALUE=${BASH_ARGV[$i-1]}

        case ${PARAM} in
            -h | --help)
                usage
                exit
                ;;
            --command)
                COMMAND=${VALUE}
                ;;
            --ca-key)
                CA_KEY_NAME=${VALUE}
                ;;
            --ca-cert)
                CA_CERT_NAME=${VALUE}
                ;;
            --ca-password)
                CA_PW=${VALUE}
                ;;
            --ca-days)
                CA_DAYS=${VALUE}
                ;;
            --ca-subject-dn)
                CA_SUBJECT=${VALUE}
                ;;
            --server-hostname)
                SERVER_HOSTNAME=${VALUE}
                ;;
            --server-days)
                SERVER_DAYS=${VALUE}
                ;;
            --server-subject-dn)
                SERVER_SUBJECT=${VALUE}
                ;;
            --keystore)
                KEYSTORE_NAME=${VALUE}
                ;;
            --keystore-pw)
                KEYSTORE_PW=${VALUE}
                ;;
            --truststore)
                TRUSTSTORE_NAME=${VALUE}
                ;;
            --truststore-pw)
                TRUSTSTORE_PW=${VALUE}
                ;;
            --trust-ca-alias)
                TRUST_CA_ALIAS=${VALUE}
                ;;
            # --server-alt-names)
            #     SAN=${VALUE}
            #     ;;
            *)
                echo "ERROR: unknown parameter \"${PARAM}\""
                usage
                exit 1
                ;;
        esac

      done

  fi

  if [ "${COMMAND}" != "create-ca" ] && [ "${COMMAND}" != "create-es" ]
  then
    echo ""
    # TODO: Figure out the right commands.
    echo "Invalid or missing command. Must be one of: create-ca|create-es"
    usage
    exit 1
  fi

  check_mandatory_arg "${CA_KEY_NAME}"     "--ca-key"
  check_mandatory_arg "${CA_CERT_NAME}"    "--ca-cert"
  check_mandatory_arg "${CA_PW}"           "--ca-password"
  check_mandatory_arg "${CA_DAYS}"         "--ca-days"
  check_mandatory_arg "${CA_SUBJECT}"      "--ca-subject-dn"
  check_mandatory_arg "${SERVER_HOSTNAME}" "--server-hostname"
  check_mandatory_arg "${SERVER_DAYS}"     "--server-days"
  check_mandatory_arg "${SERVER_SUBJECT}"  "--server-subject-dn"
  check_mandatory_arg "${KEYSTORE_NAME}"   "--keystore"
  check_mandatory_arg "${KEYSTORE_PW}"     "--keystore-pw"
  check_mandatory_arg "${TRUSTSTORE_NAME}" "--truststore"
  check_mandatory_arg "${TRUSTSTORE_PW}"   "--truststore-pw"
  check_mandatory_arg "${TRUST_CA_ALIAS}"  "--trust-ca-alias"

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

# $1 is the path and filename of the ca cert. e.g. private/rootca.cert.pem
# $2 is the path and filename of the server cert. e.g. certs/example.com.cert.pem
function verify_chain_of_trust()
{
  CA_CERT=$1
  SERVER_CERT=$2
  echo ""
  echo "------------------------------------------------------------------------------"
  echo "Verifying chain of trust between ${CA_CERT} and ${SERVER_CERT}"
  echo "------------------------------------------------------------------------------"
  openssl verify -purpose sslserver -policy_check -CAfile ${CA_CERT} ${SERVER_CERT}
}

# Check if a file exists, and determine whether we shoudl proceed or not.
# $1 is the the file to check. e.g. private/rootca.key.pem
function check_if_file_exists()
{
  if [ -f ${1} ]
  then
    echo ""
    echo -n "${1} already exists. "
    if [ "${OVERWRITE}" == "true" ]
    then
      echo "It will be re-created because \"--overwrite\" is set to true. Just thought you should know."
    else
      echo "Stopping. Set \"--overwrite\" to \"true\" to continue when files exist. See usage with \"--help\""
      exit 1
    fi
  fi
}

function create_ca()
{

  echo ""
  echo "Let's make a CA!"

  # check_if_file_exists ${CA_KEY}
  # check_if_file_exists ${CA_CERT}

  echo ""
  echo "------------------------------------------------------------------------------"
  echo "Creating the root CA keypair: ${CA_KEY}"
  echo "------------------------------------------------------------------------------"
  openssl genrsa -aes256 -passout pass:${CA_PW} -out ${CA_KEY} 4096

  echo ""
  echo "------------------------------------------------------------------------------"
  echo "Creating the root CA certificate: ${CA_CERT}"
  echo "------------------------------------------------------------------------------"
  openssl req -config /openssl.cnf \
        -key ${CA_KEY} -passin pass:${CA_PW} \
        -new -x509 -days ${CA_DAYS} -sha256 -extensions v3_ca \
        -subj "${CA_SUBJECT}" \
        -out ${CA_CERT}

  print_cert ${CA_CERT}

}

function create_cert()
{

  echo ""
  echo "Let's make a cert!"

  KEY=${KEYS_DIR}/${SERVER_HOSTNAME}.key.pem
  CERT=${CERTS_DIR}/${SERVER_HOSTNAME}.cert.pem

  CSR=_work/csr/${SERVER_HOSTNAME}.csr.pem

  KEYSTORE=${STORES_DIR}/${KEYSTORE_NAME}
  TRUSTSTORE=${STORES_DIR}/${TRUSTSTORE_NAME}

  # Exported because it's used in openssl.cnf
  export SAN="DNS:${SERVER_HOSTNAME},DNS:*.${SERVER_HOSTNAME}"

  # TODO: Check that files exist
  # check_if_file_exists ${KEY}
  # check_if_file_exists ${CERT}

  echo ""
  echo "------------------------------------------------------------------------------"
  echo "Creating the server certificate keypair: ${KEY}"
  echo "------------------------------------------------------------------------------"
  openssl genrsa -out ${KEY} 2048

  echo ""
  echo "------------------------------------------------------------------------------"
  echo "Creating the server certificate signing request: ${CSR}"
  echo "------------------------------------------------------------------------------"
  # Note: subjectAltName is set automatically using ${SAN}. See env var. in openssl.cfg file.
  openssl req -config /openssl.cnf \
        -key ${KEY} \
        -new -sha256 -out ${CSR} \
        -subj "${SERVER_SUBJECT}"

  echo ""
  echo "------------------------------------------------------------------------------"
  echo "Signing the CSR with the CA: ${CERT}"
  echo "------------------------------------------------------------------------------"
  openssl ca -config /openssl.cnf -passin pass:${CA_PW} -batch \
        -extensions server_cert -days ${SERVER_DAYS} -notext -md sha256 \
        -keyfile ${CA_KEY} -cert ${CA_CERT} \
        -in ${CSR} \
        -out ${CERT}
  # chmod 444 ${CERT}

  print_cert ${CERT}

  verify_chain_of_trust ${CA_CERT} ${CERT}

  PKCS12=_work/pkcs12/${SERVER_HOSTNAME}.key.p12

  echo ""
  echo "------------------------------------------------------------------------------"
  echo "Converting key and certificate to PKCS12 format"
  echo "------------------------------------------------------------------------------"
  openssl pkcs12 -export \
        -in ${CERT} -inkey ${KEY} \
        -out ${PKCS12} -passout pass:${KEYSTORE_PW} \
        -name ${SERVER_HOSTNAME}


  echo ""
  echo "------------------------------------------------------------------------------"
  echo "Importing the PCKS12 file (containing the key and certificate) into the keystore"
  echo "------------------------------------------------------------------------------"
  keytool -importkeystore \
        -srckeystore ${PKCS12} -srcstorepass ${KEYSTORE_PW} -srcstoretype pkcs12 -srcalias ${SERVER_HOSTNAME} \
        -destkeystore ${KEYSTORE} -storepass ${KEYSTORE_PW} -deststoretype JCEKS \
        -destalias ${SERVER_HOSTNAME}

  echo ""
  echo "------------------------------------------------------------------------------"
  echo "Importing the CA into the truststore"
  echo "------------------------------------------------------------------------------"
  keytool -importcert -trustcacerts  -noprompt \
        -keystore ${TRUSTSTORE} -storepass ${TRUSTSTORE_PW} \
        -file ${CA_CERT} -alias ${TRUST_CA_ALIAS}

  echo ""
  echo "------------------------------------------------------------------------------"
  echo "Listing of ${KEYSTORE}"
  echo "------------------------------------------------------------------------------"
  keytool -list -keystore ${KEYSTORE} -storepass ${KEYSTORE_PW} -storetype JCEKS

  echo ""
  echo "------------------------------------------------------------------------------"
  echo "Listing of ${TRUSTSTORE}"
  echo "------------------------------------------------------------------------------"
  keytool -list -keystore ${TRUSTSTORE} -storepass ${TRUSTSTORE_PW} -storetype JCEKS

}

function main()
{
  echo "I AM CLIENT"
  process_args
  exit 0

  mkdir -p ${OUTPUT_DIR}
  # Clean up in case files are there from a previous run.
  rm -rf ${OUTPUT_DIR}/*

  cd ${OUTPUT_DIR}
  mkdir -p ${KEYS_DIR} ${CERTS_DIR} ${STORES_DIR} _work/csr _work/newcerts _work/pkcs12

  # Clean up in case files are there from a previous run.
  # TODO: Do we want to clean up, or keep the database going?
  # rm -rf _work/index.txt
  touch _work/index.txt
  # if [ ! -f _work/serial ]
  # then
  #   echo "Serial file doesn't exist. Creating it."
    echo 1000 > _work/serial
  # fi

  CA_KEY=${KEYS_DIR}/${CA_KEY_NAME}
  CA_CERT=${CERTS_DIR}/${CA_CERT_NAME}

  case ${COMMAND} in
    create-ca)
        create_ca
        create_cert
        # TODO: Remove the following, it's for testing only.
        # SERVER_HOSTNAME=example.net
        # SERVER_SUBJECT="/C=US/ST=California/O=Kaazing/OU=Kaazing Demo/CN=*.example.net"
        # echo ""
        # echo "#####################################################################"
        # echo "#####################################################################"
        # echo "#####################################################################"
        # create_cert
        ;;
    create-es)
        echo "Not yet ready"
        ;;
  esac

  echo ""
  echo "------------------------------------------------------------------------------"
  echo "Summary"
  echo "------------------------------------------------------------------------------"
  print_settings

  echo ""
  echo "Done."

}

main
