#!/usr/bin/env bash

# Extract Quartus
if [ ! -f "${QUARTUS_ARCHIVE}" ]; then
    echo "file not found: ${QUARTUS_ARCHIVE}"
    exit 1
fi

[ -d "${QUARTUS_PATH}" ] && echo "Deleting existing Quartus: ${QUARTUS_PATH}" && rm -rf ${QUARTUS_PATH}

echo "Extracting ${QUARTUS_ARCHIVE} to ${QUARTUS_PATH}..."
mkdir -p ${QUARTUS_PATH}
pushd $(dirname ${QUARTUS_PATH})
tar -axf ${QUARTUS_ARCHIVE}
popd

# Patch
echo "Fixing Quartus..."
for i in libboost_system.so libstdc++.so.6 libccl_curl_drl.so
do
    [ -f "${QUARTUS_PATH}/quartus/linux64/$i" ] && echo "deleting $i" && rm ${QUARTUS_PATH}/quartus/linux64/$i
done

while true
do
    ${BINDIR}/autobuild.sh
    [ -n "${COVERITY_PATH}" ]  && ${BINDIR}/coverity_upload.sh
    ${BINDIR}/clean_builds.sh
    ${BINDIR}/update_html.sh > ${WORKDIR}/builds/index.html.new
    mv ${WORKDIR}/builds/index.html.new ${WORKDIR}/builds/index.html
    sleep 345
done
