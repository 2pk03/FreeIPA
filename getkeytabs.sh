#!/bin/bash

CMKEYTAB="/root/.cm/cm.keytab"
CMUSER="cdh"
REALM="ALO.ALT"
IPASERVER="freeipa.alo.alt"

DEST="$1"
FULLPRINC="$2"

# Passwd based kinit
echo PASSWORD | kinit $CMUSER@$REALM

# Or per keytab (keytab needs to be generated before)
#kinit -k -t $CMKEYTAB $CMUSER@$REALM

PRINC=$( echo $FULLPRINC | sed "s/\@$( echo $REALM )//" )

echo Retrieving keytab for $FULLPRINC for $DEST

echo Checking for existing service principle
if ipa service-find $FULLPRINC; then
        echo Service principle found
else
        echo Service principle not created, creating
        ipa service-add $FULLPRINC
fi

echo Ensuring service allows
ipa service-allow-create-keytab --users=$CMUSER $FULLPRINC
ipa service-allow-retrieve-keytab --users=$CMUSER $FULLPRINC

if ipa service-show $FULLPRINC | grep 'Keytab' | grep 'False'; then
        echo Creating keytab for $FULLPRINC for $DEST
        ipa-getkeytab -s $IPASERVER -p $PRINC -k $DEST
else
        echo Retrieving keytab for $FULLPRINC for $DEST
        ipa-getkeytab -r -s $IPASERVER -p $PRINC -k $DEST
fi

kdestroy

exit 0
