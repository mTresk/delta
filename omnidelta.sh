#!/bin/bash

DEVICE=$1
CURRENT_IMAGE=$2

if [ "$DEVICE" == "" ]; then
        echo "Abort: no device set" >&2
        exit 0
fi

if [ "$SSHUSER" == "" ]; then
	SSHUSER=tresk
fi

HOME=/home/tresk/build
SSHHOST=91.121.79.102
SSHPORT=22
KEYFILE=/home/tresk/.ssh/common
SAVE_PATH=$PWD

cd $HOME/delta

rm -rf $HOME/delta/last
rm -rf $HOME/delta/publish

mkdir -p $HOME/delta/last/$DEVICE

scp -P $SSHPORT -i $KEYFILE $SSHUSER@$SSHHOST:/var/www/html/delta.treskmod.ru/weeklies/_last/$DEVICE/*.zip $HOME/delta/last/$DEVICE/.
if [ $? -ne 0 ]; then
    echo "Abort: restoring last reference failed - could be fine on first build - skipping delta" >&2
else
    $HOME/delta/opendelta.sh $DEVICE
    if [ $? -ne 0 ]; then
        echo "Abort: creating delta failed" >&2
        exit 1
    fi

    # copy delta files
    ssh -p $SSHPORT -i $KEYFILE $SSHUSER@$SSHHOST "mkdir -p /var/www/html/delta.treskmod.ru/weeklies/$DEVICE"
    scp -P $SSHPORT -i $KEYFILE $HOME/delta/publish/$DEVICE/* $SSHUSER@$SSHHOST:/var/www/html/delta.treskmod.ru/weeklies/$DEVICE/.
    rm -rf $HOME/delta/last
    rm -rf $HOME/delta/publish
fi

# copy current image as last for next round (opendelta.sh will replace the file in last/$DEVICE)
ssh -p $SSHPORT -i $KEYFILE $SSHUSER@$SSHHOST "mkdir -p /var/www/html/delta.treskmod.ru/weeklies/_last/$DEVICE"
ssh -p $SSHPORT -i $KEYFILE $SSHUSER@$SSHHOST "rm -rf /var/www/html/delta.treskmod.ru/weeklies/_last/$DEVICE/*"
if [ -f $CURRENT_IMAGE ]; then
    scp -P $SSHPORT -i $KEYFILE $CURRENT_IMAGE $SSHUSER@$SSHHOST:/var/www/html/delta.treskmod.ru/weeklies/_last/$DEVICE/.
fi

cd $SAVE_PATH

exit 0


