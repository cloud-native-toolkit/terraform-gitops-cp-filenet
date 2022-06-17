#!/usr/bin/env bash
CHART_DIR="$1"
DEST_DIR="$2"
mkdir -p "${DEST_DIR}"
echo "**********Create Directory ${DEST_DIR} Create DB Yaml  **************"
#mkdir -p "${DEST_DIR}/cp4ba-odm"
#mkdir -p "${DEST_DIR}/db-secret"
echo "**********Create Directory ${DEST_DIR}  **************"
#cp -R "${CHART_DIR}/cp4ba-odm"/* "${DEST_DIR}/cp4ba-odm/"
#cp -R "${CHART_DIR}/cp4ba-odm"/* "${DEST_DIR}"
#cp -R "${CHART_DIR}/db-secret"/* "${DEST_DIR}/db-secret"
cp -R "${CHART_DIR}/db-secret"/* "${DEST_DIR}"

echo "**** Copied ${CHART_DIR} to   ${DEST_DIR}  ****"
find "${DEST_DIR}" -name "*"

if [[ -n "${VALUES_CONTENT}" ]]; then
    #echo "${VALUES_CONTENT}" > "${DEST_DIR}/cp4ba-odm/values.yaml"
    echo "${VALUES_CONTENT}" > "${DEST_DIR}/values.yaml"
    #echo "${VALUES_CONTENT}" > "${DEST_DIR}/db-secret/values.yaml"
    echo "Copied the custom values to the values.yaml file ${VALUES_CONTENT}"
fi    