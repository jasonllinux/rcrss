#! /bin/bash

if [ ! $# -eq 3 ] ; then
  echo "usage: `basename $0` <teamname> <hostname> <dir>"
  exit 1
fi

. functions.sh


echo "$1 $2 $3"
TEAM_NAME=$1
HOSTNAME=$2
OUTDIR=$3

# processArgs $*





makeClasspath $BASEDIR/jars $BASEDIR/lib
java -Xmx1024m -cp $CP:$BASEDIR/jars/rescuecore2.jar:$BASEDIR/jars/standard.jar:$BASEDIR/jars/sample.jar -Dlog4j.log.dir=logs rescuecore2.LaunchComponents sample.LiveLogExtractor -c config/viewer.cfg -h $HOSTNAME --viewer.team-name=$TEAM_NAME --viewer.output-dir=$OUTDIR
