#!/bin/bash
#
# Simple loop to replicate the 'recursive' sync behaviour of s3cmd whilst allowing encryption.
#
# Copyright (C) 2014 B Tasker
# Released under GNU GPL V2 - See http://www.gnu.org/licenses/gpl-2.0.txt
#
#
# See https://www.bentasker.co.uk/documentation/linux/285-implementing-encrypted-incremental-backups-with-s3cmd for more information


# Backup directory specific
loca="Notes" # The name of the directory we'll be backing up
basedir="/mnt/files" # Where we can find that directory
s3path="benbackup/Server1" # The path (including bucket name) to use for s3cmd

# Largely static (server specific at least)
hashdir="/var/backuphashes"  # Where we should store our file hashes


cd $basedir/$loca

if [ ! -d "$hashdir/$loca" ]
then
        mkdir -p "$hashdir/$loca"
fi

#Find all files within this directory and it's subdirs
find * -type f | while read -r a
do

        fnamehash=`echo "$a" | sha1sum | cut -d\  -f1`
        filehash=`sha1sum "$a" | cut -d\  -f1`
        source "$hashdir/$loca/$fnamehash" 2> /dev/null

        if [ "$filehash" != "$storedhash" ]
        then
                /usr/bin/s3cmd put -e $a s3://$s3path/$loca/$a
        else
                # Hashes match, no need to push
                echo "$a unchanged, skipping......"
        fi

done

