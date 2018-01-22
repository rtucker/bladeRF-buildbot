while true
do
    ${BINDIR}/autobuild.sh
    [ -n "${COVERITY_PATH}" ]  && ${BINDIR}/coverity_upload.sh
    ${BINDIR}/clean_builds.sh
    ${BINDIR}/update_html.sh > ${WORKDIR}/builds/index.html.new
    mv ${WORKDIR}/builds/index.html.new ${WORKDIR}/builds/index.html
    sleep 345
done
