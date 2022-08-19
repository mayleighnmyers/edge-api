#!/bin/bash

set -x

mkdir "${PWD}/sonarqube/"
mkdir "${PWD}/sonarqube/download/"
mkdir "${PWD}/sonarqube/extract/"
mkdir "${PWD}/sonarqube/certs/"
mkdir "${PWD}/sonarqube/store/"

curl -o "${PWD}/sonarqube/certs/RH-IT-Root-CA.crt" --insecure "${ROOT_CA_CERT_URL}"

"${JAVA_HOME}/bin/keytool" \
  -keystore "/${PWD}/sonarqube/store/RH-IT-Root-CA.keystore" \
  -import \
  -alias "RH-IT-Root-CA" \
  -file "/${PWD}/sonarqube/certs/RH-IT-Root-CA.crt" \
  -storepass "redhat" \
  -noprompt

export SONAR_SCANNER_OPTS="-Djavax.net.ssl.trustStore=${PWD}/sonarqube/store/RH-IT-Root-CA.keystore -Djavax.net.ssl.trustStorePassword=redhat"
export SONAR_SCANNER_OS="linux"
export SONAR_SCANNER_CLI_VERSION="4.7.0.2747"
export SONAR_SCANNER_DOWNLOAD_NAME="sonar-scanner-cli-${SONAR_SCANNER_CLI_VERSION}-${SONAR_SCANNER_OS}"
export SONAR_SCANNER_NAME="sonar-scanner-${SONAR_SCANNER_CLI_VERSION}-${SONAR_SCANNER_OS}"

curl -o "${PWD}/sonarqube/download/${SONAR_SCANNER_DOWNLOAD_NAME}.zip" --insecure "${SONARQUBE_CLI_URL}"

unzip -d "${PWD}/sonarqube/extract/" "${PWD}/sonarqube/download/${SONAR_SCANNER_DOWNLOAD_NAME}.zip"

export PATH="${PWD}/sonarqube/extract/${SONAR_SCANNER_NAME}/bin:${PATH}"

COMMIT_SHORT=$(git rev-parse --short=7 HEAD)

OPENJDK_CONTAINER_IMAGE='registry.access.redhat.com/openjdk/openjdk-11-rhel7:1.12-1.1658422675'

docker pull "${OPENJDK_CONTAINER_IMAGE}"

{ echo "SONARQUBE_REPORT_URL=${SONARQUBE_REPORT_URL}";
  echo "COMMIT_SHORT=${COMMIT_SHORT}";
  echo "SONARQUBE_TOKEN=${SONARQUBE_TOKEN}";
  echo "SONAR_SCANNER_NAME=${SONAR_SCANNER_NAME}"
} >> "${PWD}/sonarqube/my-env.txt"

docker run \
    -v"${PWD}":/home/jboss \
    --env-file "${PWD}/sonarqube/my-env.txt" \
    "${OPENJDK_CONTAINER_IMAGE}" \
    "/home/jboss/edge-api/sonarqube_exec.sh"

mkdir -p "${WORKSPACE}/artifacts"
cat << EOF > "${WORKSPACE}/artifacts/junit-dummy.xml"
<testsuite tests="1">
    <testcase classname="dummy" name="dummytest"/>
</testsuite>
EOF
