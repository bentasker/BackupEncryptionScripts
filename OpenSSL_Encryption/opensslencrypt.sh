#!/bin/bash
#
# Use OpenSSL to encrypt a file
#
# Copyright (C) 2014 B Tasker
# Released under GNU GPL V2 - See http://www.gnu.org/licenses/gpl-2.0.txt
#
# https://github.com/bentasker/BackupEncryptionScripts
#
# Arguments
#
# -f [file] - File to encrypt
# -s - If set the original will be shredded after encryption [Default = Off]
# -k [public key file] - the PEM encoded RSA key to use for encryption [Default = ~/key.pem]
# -l [keylen (chars)] - The number of characters to use for the One Time Password [Default = 256]
# -p [shred passes] - How many passes should shred make? [Default = 500]
# -D [random/urandom] - Should /dev/random or urandom be used for OTP generation [Default = urandom]
#




while getopts "f:k:l:t:D:p:s:" flag
do

        case "$flag" in
                f) file="$OPTARG";;
                k) keyfile="$OPTARG";;
                l) keylen="$OPTARG";;
                D) rand="$OPTARG";;
                p) passes="$OPTARG";;
                s) destroy=1;;
        esac
done


if [ "$file" == "" ]
then

cat << EOM
Usage $0 -f [file] [-s] [-k publickey file] [-l keylen (chars)] [-p shred passes] [-D random/urandom] [-s 1/0]
Example: $0 -f myfile -k ~/public.pem -l 256 -t /tmp -D random


Arguments

         -f [file] - File to encrypt
         -s - If set the original will be shredded after encryption [Default = Off]
         -k [public key file] - the PEM encoded RSA public key to use for encryption [Default = ~/key.pem]
         -l [keylen (chars)] - The number of characters to use for the One Time Password [Default = 256]
         -p [shred passes] - How many passes should shred make? [Default = 500]
         -D [random/urandom] - Should /dev/random or urandom be used for OTP generation (random may block) [Default = urandom]
         -s Shred original 0 = no, 1= yes (default 0)


EOM

exit 1
fi




# Set the defaults
keyfile=${keyfile:-"~/key.pem"}
keylen=${keylen:-256}
passes=${passes:-500}
rand=${rand:-"random"}
destroy=${destroy:-0}


echo "Encrypting $file"

# Create the OTP
cat /dev/$rand | tr -dc 'a-zA-Z0-9-_!@#$%^&*()_+{}|:<>?='|fold -w $keylen| head -n 1 > key.txt

# Encrypt the file
openssl enc -aes-256-cbc -salt -pass file:key.txt -in "$file" > $file.enc

# Encrypt the key
openssl rsautl -encrypt -pubin -inkey $keyfile -in key.txt -out key.txt.enc

# Package the two together
tar -cf "$file.enc.tar" key.txt.enc "$file.enc"

echo "Tidying up"
rm -f key.txt.enc "$file.enc"
shred -uz -n $passes key.txt

if [ $destroy -eq 1 ]
then
        echo "Shredding original"
        shred -uz -n $passes "$file"
fi
