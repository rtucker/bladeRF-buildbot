#!/bin/bash
LATEST_SYMLINK=/srv/bladerf/builds/latest
LAST_UPLOAD_FILE=/srv/bladerf/.coverity_last_upload
MINIMUM_AGE=$(((7*24*60*60)))
TOKENDIR=/srv/bladerf

LATEST_TARGET=$(stat --format="%N" ${LATEST_SYMLINK} | cut -d'`' -f3 | cut -d"'" -f1)
TOKEN=$(cat ${TOKENDIR}/.coverity_token)
EMAIL=rtucker@gmail.com
DROPFILE=${LATEST_SYMLINK}/coverity/build/bladeRF_coverity.tgz
VERSION=$(grep Version ${LATEST_SYMLINK}/coverity/build/host/libraries/libbladeRF/libbladeRF.pc | cut -d' ' -f2)

if [ -f "${LAST_UPLOAD_FILE}" ]; then
    LAST_UPLOADED=$(cat ${LAST_UPLOAD_FILE})
    LAST_UPLOADED_AT=$(stat --format=%Z ${LAST_UPLOAD_FILE})
    echo "Last revision uploaded: ${LAST_UPLOADED}"
else
    LAST_UPLOADED=""
    LAST_UPLOADED_AT=0
    echo "Warning: no record of last uploaded version"
fi

if [ "$VERSION" = "" ]; then
    echo "No version string, aborting"
    exit 1
fi

if [ "$TOKEN" = "" ]; then
    echo "No token string, aborting"
    exit 1
fi

if [ ! -f "${DROPFILE}" ]; then
    echo "No output file, aborting"
    exit 1
fi

if [ "$LAST_UPLOADED" = "${LATEST_TARGET}" ]; then
    echo "Revision ${LATEST_TARGET} already uploaded; exiting."
    exit 0
fi

LAST_UPLOAD_AGE=$((($(date +%s) - ${LAST_UPLOADED_AT})))
echo "Last uploaded: ${LAST_UPLOAD_AGE} seconds ago"

if [ $LAST_UPLOAD_AGE -lt $MINIMUM_AGE ]; then
    echo "Age less than ${MINIMUM_AGE}; exiting."
    exit 0
fi

echo "Uploading revision: ${LATEST_TARGET}"
echo "Version: ${VERSION}"
echo ""

curl --form project=bladeRF \
     --form token=${TOKEN} \
     --form email=${EMAIL} \
     --form file=@${DROPFILE} \
     --form version=${VERSION} \
     --form description="Rev ${LATEST_TARGET:0:7} - bladeRF Build-o-Matic Auto Submission" \
     http://scan5.coverity.com/cgi-bin/upload.py || exit 1

echo "${LATEST_TARGET}" > ${LAST_UPLOAD_FILE}
