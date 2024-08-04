#!/bin/sh

cd $II_SYSTEM/ingres

source $II_SYSTEM/ingres/.ingORsh

II_HOSTNAME=localhost
export II_HOSTNAME

TARBALL=/tmp/actianx-*-x86_64*/ingres.tar

tar -xvf $TARBALL install

./install/ingbuild -acceptlicense -install=net,tm,esql -exresponse -file=$II_RESPONSE_FILE $TARBALL

if [ $II_HOSTNAME ] ; then
    ingsetenv II_HOSTNAME localhost
fi
