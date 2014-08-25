#!/bin/bash
#
# Simple loop to replicate the 'recursive' sync behaviour of s3cmd whilst allowing encryption, using OpenSSL.
#
# Copyright (C) 2014 B Tasker
# Released under GNU GPL V2 - See http://www.gnu.org/licenses/gpl-2.0.txt
#
#
# See https://www.bentasker.co.uk/documentation/linux/285-implementing-encrypted-incremental-backups-with-s3cmd for more information


# Backup directory specific

loca="Notes"
basedir="/mnt/files"
s3path="benbackup/Server1"
# Number of characters to use in the OTP
keylen="256"

# Largely static (server specific at least)
hashdir="/var/backuphashes"

# Public key to be used for encryption
keyfile="~/keys/backupkey-public.pem"

# What should we use as a temporary directory?
tmpdir="/tmp/"

# Change to urandom if issues with /dev/random blocking are experienced
rand="random" 


cd $basedir/$loca

if [! -d "$hashdir/$loca" ]
then
        mkdir -p "$hashdir/$loca"
fi

find * -type f | while read -r a
do

	fnamehash=`echo "$a" | sha1sum | cut -d\  -f1`
	filehash=`sha1sum "$a" | cut -d\  -f1`

	source "$hashdir/$loca/$fnamehash"

	if [ "$filehash" != "$storedhash" ]
	then

		  echo "Encrypting $a"
		  fname=`basename $a`

		  # Create the OTP
		  cat /dev/$rand | tr -dc 'a-zA-Z0-9-_!@#$%^&*()_+{}|:<>?='|fold -w $keylen| head -n 1 > $tmpdir/key.txt

		  # Encrypt the file
		  openssl enc -aes-256-cbc -salt -pass file:$tmpdir/key.txt -in "$a" > "$tmpdir/$fname.enc"

		  # Encrypt the key
		  openssl rsautl -encrypt -pubin -inkey $keyfile -in $tmpdir/key.txt -out $tmpdir/key.txt.enc

		  cd $tmpdir

		  # Package the two together
		  tar -cf "encrypted.enc.tar" key.txt.enc "$fname.enc"

		  /usr/bin/s3cmd put encrypted.enc.tar "s3://$s3path/$loca/$a.enc.tar"

		  echo "Tidying up"
		  rm -f encrypted.enc.tar key.txt.enc key.txt "$fname.enc"
		  echo "storedhash='$filehash'" > "$hashdir/$loca/$fnamehash"
		  cd $basedir/$loca

	else
		  # Hashes match, no need to push
		  echo "$a unchanged, skipping......"
	fi

done
