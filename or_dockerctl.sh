#!/bin/bash
#
# Copyright (c) 2023 Actian Corporation
#
# Name: or_dockerctl.sh -- Wrapper script for starting and stopping the OpenROAD Server in
#                    Docker image
#
# Usage:
#       dockerctl
#
# Description:
#       This script is the target of the ENTRYPOINT command in a Dockerfile
#       which dictates which executable/script is run when a Docker container
#       is started.
#       When run it setups the OpenROAD environment and runs ingstart and orspostart&.
#       It will then sleep, polling a runfile every 10 seconds until it
#       receives a SIGHUP, INT, QUIT or TERM from either the launch terminal
#       or Docker.
#       When it receives a signal it will run ingstop and orspostop then exit.
#

runfile=/var/lib/actian-orserver/OR/run.$$
rundir=`dirname $runfile`
[ -d rundir ] || mkdir -p $rundir
trap "rm -f $runfile" HUP INT QUIT TERM
boilerplate="Actian OpenROAD Server ($VERSION)
"
envfile=/etc/profile.d/ingresOR.sh
if [ -f $envfile ] ; then
    source $envfile
else
    cat << EOF
ERROR: Cannot locate $envfile

EOF
fi

echo "$boilerplate"

or_deploy=/deploy
or_log=/logs
[ -d ${or_deploy} ] || mkdir -p ${or_deploy}

[ -f ${or_deploy}/orjarinstall_cfg.json ] && {
    rm $II_SYSTEM/ingres/files/orjarinstall_cfg.json
    cp ${or_deploy}/orjarinstall_cfg.json ${II_SYSTEM}/ingres/files/
} || {
    cp $II_SYSTEM/ingres/files/orjarinstall_cfg.json ${or_deploy}/
}

log_files="catalina.out errlog.log w4gl.log"

for l in $log_files; do
    case $l in
        "catalina.out")
            ldir=$CATALINA_HOME/logs/
	    ;;
        *)
            ldir=$II_SYSTEM/ingres/files/
	    ;;
    esac

    [ -f ${or_log}/$l ] && {
        [ -f $ldir/$l ] && rm $ldir/$l
        ln -s /logs/$l $ldir
    } || { 
	rm -f $ldir/$l
        touch /logs/$l
        ln -s /logs/$l $ldir
    }
done
chown actian:actian /logs/*


touch $runfile
owner=actian
echo "Starting Ingres Net (ingstart)."
runuser $owner -c ingstart

orjar_files=/deploy/orserver-add-*.zip
for f in $orjar_files
do
  python /deploy/orjarinstall.py $f >> /logs/orjarinstall.log 2>&1
done

echo "Starting Tomcat 9 ($CATALINA_HOME/bin/catalina.sh start)."
su - $owner -c "$CATALINA_HOME/bin/catalina.sh start"

echo "Starting the ORSPO Server."
su - $owner -c "$II_SYSTEM/ingres/bin/orspogsvrstart"
echo "Started."

while [ -f $runfile ]
do
    sleep 10
done

echo "Exiting..."
echo "ingstop"
runuser $owner -c ingstop
runuser $owner -c "ingstop -mgmtsvr"
echo "Tomcat stop"
runuser $owner -c "$CATALINA_HOME/bin/catalina.sh stop"
echo "orspogsvrstop"
runuser $owner -c "$II_SYSTEM/ingres/bin/orspogsvrstop"
echo "Done"

