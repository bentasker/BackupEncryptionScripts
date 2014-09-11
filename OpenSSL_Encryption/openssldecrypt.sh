#!/bin/bash
#
# Use OpenSSL to decrypt a file, or find and decrypt encrypted files within a directory structure
#
# Copyright (C) 2014 B Tasker
# Released under GNU GPL V2 - See http://www.gnu.org/licenses/gpl-2.0.txt
#
# https://github.com/bentasker/BackupEncryptionScripts
#
# Arguments
#
# [-f file] - File to decrypt
# [-d directory] - base directory to find encrypted files in
#
# One of -f or -d must be set
#
# -k [public key file] - the PEM encoded RSA key to use for encryption [Default = ~/privkey.key]
# -c [encrypted filename] - The filename used within the tarball for the original file [Default = encryptedfile.enc]
# -r - Should the encrypted file be removed?


# Perform the decryption
decryptFile(){
        file=$1
        keyfile=$2
        deffile=$3
        remove=$4

        origfile=`echo -n "$file" | sed 's/.enc.tar//g'`
        here=`pwd`

        echo "Decrypting $here/$origfile"

        tar xf "$file"

        if [ -e "$origfile.enc" ]
        then
                cryptfile="$origfile.enc"
        elif [ -e "$deffile" ]
        then
                cryptfile="$deffile"
        else
                echo "Can't find a file to decrypt, use -c to define the filename"
        fi



        openssl rsautl -decrypt -inkey "$keyfile" -in key.txt.enc -out key.txt
        openssl enc -aes-256-cbc -d -pass file:key.txt -in "$cryptfile" > "$origfile"

        rm -f key.txt key.txt.enc "$cryptfile"

        if [ "$remove" == "1" ]
        then
                rm -f $file
        fi
}



while getopts "f:d:k:c:r" flag
do
        case "$flag" in
                f) file="$OPTARG";;
                d) directory="$OPTARG"; recurse=1;;
                k) keyfile="$OPTARG";;
                c) crypfile="$OPTARG";;
                r) remove=1;;
        esac
done


if [ "$file" == "" ] && [ "$directory" == "" ]
then

cat << EOM
Usage $0 [-f file] [-d directory] [-k private key file] [-c encrypted filename] [-r]
Example: $0 -f myfile -k ~/public.pem -l 256 -t /tmp -D random


Arguments:

         [-f file] - File to encrypt
         [-d directory] - Directory structure to find encrypted files in
         [-k private key file] - the PEM encoded RSA private key to use for encryption [Default = ~/privkey.key]
         [-c encrypted filename] - The filename used within the tarball for the original file [Default = encryptedfile.enc]
         [-r]   - Remove the encrypted version of the file [Default = Off ]

EOM

exit 1
fi




# Set the defaults
keyfile=${keyfile:-"~/privkey.key"}
crypfile=${keyfile:-"encryptedfile.enc"}

if [ "$recurse" == "1" ]
then
        if [ ! -d $directory ]
        then
                echo "ERROR: $directory doesn't appear to be a directory (did you mean to use -f?)"
                exit 1
        fi


        cd $directory
        cur=`pwd`
        find ./ -name '*.enc.tar' -type f | while read -r dir
        do
                cd $(dirname $dir)
                decryptFile $(basename $dir) "$keyfile" "$crypfile" $remove
                cd "$cur"
        done

else

        if [ ! -f "$file" ]
        then
                echo "ERROR: $file doesn't appear to be a file (did you mean to use -d?)"
                exit 1
        fi

        decryptFile "$file" "$keyfile" "$crypfile" $remove

fi
