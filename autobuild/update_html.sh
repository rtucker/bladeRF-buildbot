#!/bin/bash
WORKDIR="/srv/bladerf"
COVERITY_REVISION="$(cat $WORKDIR/.coverity_last_upload)"

cd $WORKDIR

cat << EOM
<html>
    <head>
        <title>bladeRF Automatic Build-O-Matic</title>
    </head>
    <body>
        <h1>bladeRF Automatic Build-O-Matic</h1>

        <img src="misc/bladerf_pic.jpg" alt="[Nuand bladeRF board]" align="right" width="40%">

        <p>
            This page provides automatically-built FPGA and FX3 images for
            the <a href="http://nuand.com/">Nuand</a> bladeRF software
            defined radio.  A new build is launched automatically when the
            HEAD of the <a href="https://github.com/nuand/bladerf">git
            repository</a> moves to an unbuilt revision, i.e. something is
            committed to the master branch.
        </p>

        <p>
            The FPGA images are built using Quartus II Web Edition 15.0,
            32-bit.  The FX3 firmware images are built using the
            <span title="FX3_SDK_B125.tar.gz, md5sum=a1434b1fc3611f845d1b249722dfc497">
                Cypress FX3 SDK v1.2.3</span>.
            All builds are performed on an Ubuntu 10.04 LTS server hosted by
            <a href="http://www.linode.com/?r=f4079e5bd594cdb5820aaec4a8eaca7b533dd6d0">
                Linode</a>.
        </p>

        <p>
            If there is a problem with this script, please contact the
            build-o-matician at
            <a href="mailto:rtucker@gmail.com">rtucker@gmail.com</a>
            or HoopyCat on
            <a href="irc://chat.freenode.net/bladeRF">freenode #bladeRF</a>.
        </p>

        <h2>Latest Image</h2>
EOM

if [ -h "${WORKDIR}/builds/latest" ]
then
    # XXX: ugly shell hacking warning
    TARGET=$(stat --format="%N" ${WORKDIR}/builds/latest | cut -d'`' -f3 | cut -d"'" -f1)

    echo "<p>Static URLs to retrieve the latest auto-built hosted images and firmware:</p>"
    echo "<ul>"
    echo "<li><a href=\"latest/artifacts/hostedx40.rbf\">hostedx40.rbf (FPGA image, 40 kLE)</a></li>"
    echo "<li><a href=\"latest/artifacts/hostedx115.rbf\">hostedx115.rbf (FPGA image, 115 kLE)</a></li>"
    echo "<li><a href=\"latest/artifacts/firmware.img\">firmware.img (Cypress FX3 firmware, no debugging symbols)</a></li>"
    echo "<li><a href=\"latest/artifacts/libbladeRF_doxygen/\">Documentation for libbladeRF (generated by doxygen)</a></li>"
    echo "</ul>"

    echo "<p>These were built from git revision:</p>"
    echo "<pre>$(cd ${WORKDIR}/bladeRF/ && git log -n 1 ${TARGET} | sed 's/\&/\&amp;/g;s/</\&lt;/g;s/>/\&gt;/g')</pre>"

else
    TARGET=""
    echo "<p><b>ERROR: No 'latest' symlink exists.</b></p>"
fi

cat << EOM
        <h2>Available builds</h2>

        <p>
            Builds will be deleted after about 14 days, to preserve our natural resources.
        </p>

        <table border="1">
        <tr>
            <td><b>Image Name</b></td>
            <td><b>File Size</b></td>
            <td><b>Build Time</b></td>
            <td><b>MD5</b></td>
        </tr>
EOM

# Create sorted build list
DIRLIST=""
for artifact in $(ls -dt ${WORKDIR}/builds/*/artifacts/)
do
    # XXX: real ugly right here
    dir=$(basename $(dirname $artifact))
    DIRLIST="${DIRLIST} $dir"
done

for dir in ${DIRLIST}
do
    # Ensure we've got the exact path we want...
    BASEDIR=$(basename ${dir})
    BUILDDIR=${WORKDIR}/builds/${BASEDIR}

    if [ -d "${BUILDDIR}" ] && [ ! -h "${BUILDDIR}" ]
    then
        echo "<tr>"

        echo "<td colspan=4><b><a href=\"https://github.com/Nuand/bladeRF/commit/${BASEDIR}\">${BASEDIR}</a>"

        if [ -f "${BUILDDIR}/buildlog.txt" ]
        then
            echo " (<a href=\"${BASEDIR}/buildlog.txt\">build log</a>)"
        fi

        if [ "${TARGET}" = "${BASEDIR}" ]
        then
            echo " (latest build)"
        fi

        if [ "${COVERITY_REVISION}" = "${BASEDIR}" ]
        then
            echo " (latest Coverity upload)"
        fi

        echo "</b><br/>"
        echo $(cd ${WORKDIR}/bladeRF && git log -n 1 --format='%s' ${BASEDIR} | sed 's/\&/\&amp;/g;s/</\&lt;/g;s/>/\&gt;/g')
        echo "</td>"
        echo "</tr>"

        artipath=${WORKDIR}/builds/${dir}/artifacts

        if [ -d "${artipath}/libbladeRF_doxygen" ]
        then
            BUILDFILE=${BUILDDIR}/artifacts/libbladeRF_doxygen/
            BUILDTIME=$(stat --format="%y" ${BUILDFILE})
            SIZE=$(du -bs ${BUILDFILE} | cut -f1)
            echo "<tr>"
            echo "<td><a href=\"${BASEDIR}/artifacts/libbladeRF_doxygen/\">libbladeRF_doxygen/</a></td>"
            echo "<td>${SIZE}</td>"
            echo "<td>${BUILDTIME}</td>"
            echo "<td></td>"
            echo "</tr>"
        fi

        for file in $(ls ${artipath}/*.rbf ${artipath}/*.img 2>/dev/null)
        do
            # Build info about each artifact file
            BASEFILE=$(basename ${file})
            BUILDFILE=${BUILDDIR}/artifacts/${BASEFILE}
            BUILDTIME=$(stat --format="%y" ${BUILDFILE})
            MD5SUM=$(md5sum ${BUILDFILE} | cut -d' ' -f1)
            SIZE=$(stat --format="%s" ${BUILDFILE})
            echo "<tr>"
            echo "<td><a href=\"${BASEDIR}/artifacts/${BASEFILE}\">${BASEFILE}</a></td>"
            echo "<td>${SIZE}</td>"
            echo "<td>${BUILDTIME}</td>"
            echo "<td>${MD5SUM}</td>"
            echo "</tr>"
        done

        for file in $(ls ${WORKDIR}/builds/${dir}/artifacts/*.FAILED 2>/dev/null)
        do
            BASEFILE=$(basename ${file})
            BUILDFILE=${BUILDDIR}/artifacts/${BASEFILE}
            BUILDTIME=$(stat --format="%y" ${BUILDFILE})
            echo "<tr style=\"background-color: grey;\">"
            echo "<td>${BASEFILE}</td>"
            echo "<td>FAILED</td>"
            echo "<td>${BUILDTIME}</td>"
            echo "<td><i>&lt;/3</i></td>"
            echo "</tr>"
        done
    fi
done

cat << EOM
        </table>

        <hr>
<i>autobuild.sh by <a href="mailto:rtucker@gmail.com">rtucker@gmail.com</a></i><br/>
<pre>
$(uptime)

$(df -h ${WORKDIR})

used    path
$(du -sh ${WORKDIR}/builds/*)
</pre>
    </body>
</html>
EOM
