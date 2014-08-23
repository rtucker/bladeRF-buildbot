#!/bin/bash

set -e

# Clean out old builds...
[ -z "$WORKDIR" ] && WORKDIR=/srv/bladerf

# Nuke all but the latest build dirs after a few hours
LATESTTARGET=$(stat --format="%N" ${WORKDIR}/builds/latest | cut -d'`' -f3 | cut -d"'" -f1)

for dir in $(find ${WORKDIR}/builds/ -maxdepth 2 -mindepth 2 -type d -ctime +2)
do
    CANDIDATEBUILD=$(basename `dirname $dir`)
    if [ "$CANDIDATEBUILD" != "$LATESTTARGET" ] && [ "$(basename $dir)" != "artifacts" ]
    then
        echo "Deleting $WORKDIR/builds/$CANDIDATEBUILD/$(basename $dir)..."
        cd $WORKDIR/builds/$CANDIDATEBUILD/
        rm -rf $(basename $dir)
    else
        echo "Not deleting $WORKDIR/builds/$CANDIDATEBUILD/$(basename $dir)..."
    fi
done

# Nuke anything older than a couple weeks
for dir in $(find ${WORKDIR}/builds/ -maxdepth 1 -mindepth 1 -type d -ctime +14)
do
    CANDIDATEBUILD=$(basename $dir)
    if [ "$CANDIDATEBUILD" != "$LATESTTARGET" ] && [ "$CANDIDATEBUILD" != "misc" ]
    then
        echo "Deleting ${WORKDIR}/builds/${CANDIDATEBUILD} due to age..."
        cd $WORKDIR/builds/
        rm -rf ${CANDIDATEBUILD}
    else
        echo "Not deleting build $CANDIDATEBUILD as it is still the latest!"
    fi
done
