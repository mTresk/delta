#!/bin/bash

DEVICE=oneplus5
BUILDTYPE=treskmod
ROOTDIR=/home/tresk/build/
UPLOAD=1
DELTA=1
JAVA=$java
KEYFILE=/home/tresk/.ssh/common

if [ -z $DEVICE ]; then
    echo DEVICE not set
    exit 1
fi

if [ -z $BUILDTYPE ]; then
    echo BUILDTYPE not set
    exit 1
fi

if [ -z $ROOTDIR ]; then
    echo ROOTDIR not set
    exit 1
fi

if [ -z $UPLOAD ]; then
    echo UPLOAD not set
    exit 1
fi

if [ $UPLOAD -eq 1 ]; then
    export UPLOAD_DIR=$DEVICE
fi
if [ $UPLOAD -eq 2 ]; then
    export UPLOAD_DIR=tmp
fi

if [ -z $JAVA ]; then
    export JAVA_HOME=/usr/lib/jvm/java-8-openjdk-amd64/
else
    export JAVA_HOME=$JAVA
fi

if [ -z $DELTA ]; then
    DELTA=0
fi

export ROM_BUILDTYPE=$BUILDTYPE

echo USER=$USER
echo DEVICE=$DEVICE
echo CCACHE_DIR=$CCACHE_DIR
echo ROM_BUILDTYPE=$ROM_BUILDTYPE
echo ROOTDIR=$ROOTDIR
echo UPLOAD=$UPLOAD
echo UPLOAD_DIR=$UPLOAD_DIR
echo DELTA=$DELTA
echo JAVA_HOME=$JAVA_HOME

cd $ROOTDIR

#repo sync -j48
#fixme: uncommitted changes suddenly appear
#rm .repo/local_manifests/roomservice.xml
#cd .repo/manifests
#git reset --hard
#git clean -fd
#cd ../..
#cd .repo/repo
#git reset --hard
#git clean -fd
#cd ../..
#repo forall -c "git reset --hard" -j48
#repo forall -c "git clean -fd" -j48
#repo sync --force-sync -cdf -j48
rm -rf out

#use non-public keys to sign ROMs - keys not in git for obvious reasons
#cp /home/tresk/build/.keys/* ./build/target/product/security

. build/envsetup.sh
brunch $DEVICE

if [ $? -eq 0 ]; then
    CURRENT_IMAGE=`ls $ROOTDIR/out/target/product/$DEVICE/omni*-*$BUILDTYPE.zip`
    if [ $UPLOAD -ne 0 ]; then
        # Create dir if needed
        ssh -i $KEYFILE tresk@91.121.79.102 "mkdir -p /var/www/html/dl.treskmod.ru/$UPLOAD_DIR" 2>/dev/null >/dev/null
        if [ $? -ne 0 ]; then
            echo "Abort: ssh access to dl server failed" >&2
            exit 1
        fi
        # Upload file (in a background process?!)
        echo Uploading zip $CURRENT_IMAGE to $UPLOAD_DIR ...
        scp -i $KEYFILE $CURRENT_IMAGE "tresk@91.121.79.102:/var/www/html/dl.treskmod.ru/$UPLOAD_DIR"
        M5SUM_FILE=`ls $ROOTDIR/out/target/product/$DEVICE/omni*-*$BUILDTYPE.zip.md5sum`
        echo Uploading md5sum $M5SUM_FILE to $UPLOAD_DIR ...
        scp -i $KEYFILE $M5SUM_FILE "tresk@91.121.79.102:/var/www/html/dl.treskmod.ru/$UPLOAD_DIR/"
    fi
    if [ $DELTA -eq 1 ]; then
        /home/tresk/build/delta/omnidelta.sh $DEVICE $CURRENT_IMAGE
        if [ $? -ne 0 ]; then
            echo "Abort: omnidelta.sh failed" >&2
            exit 1
        fi
    fi
else
    exit 1
fi
exit 0
