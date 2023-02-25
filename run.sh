#!/bin/sh
#set -e
#set -x

# SIGTERM-handler
term_handler() {
    echo Got SIGTERM

    echo Unmounting...
    mount

    while read line;
    do 
        fusermount -u $line
        rmdir $line
    done   < /etc/gocryptfs/decrypt_mounts

    while read line;
    do 
        fusermount -u $line
        rmdir $line
    done   < /etc/gocryptfs/encrypt_mounts

    echo Unmount complete
    mount

  exit 143; # 128 + 15 -- SIGTERM
}

trap 'kill ${!}; term_handler' SIGTERM


# We re-create them every time and just rely on the directories that are present:
rm /etc/gocryptfs/decrypt
rm /etc/gocryptfs/encrypt

# Expects initialised gocryptfs cipherdir(s) within /crypts at locations specified in:
#       /etc/gocryptfs/crypts
# Decrypts and mounts them in symmetric locations within /mnt
[ -e /etc/gocryptfs ] || mkdir /etc/gocryptfs
[ -e /etc/gocryptfs/decrypt ] || ls -d /decrypt/encrypted/* > /etc/gocryptfs/decrypt
[ -e /etc/gocryptfs/encrypt ] || ls -d /encrypt/decrypted/* > /etc/gocryptfs/encrypt

if [ -s /etc/gocryptfs/decrypt ] ; then
    sed s/encrypted/decrypted/g /etc/gocryptfs/decrypt \
    | tee /etc/gocryptfs/decrypt_mounts \
    | xargs mkdir -p

    # Remove existing mounts from prior killed process.
    while read line;
    do 
        fusermount -u $line
    done   < /etc/gocryptfs/decrypt_mounts

    while read line;
    do 
        if [ ! -f $line/.gocryptfs.conf ]; then
            if [ $AUTOINIT == "true" ]; then
                echo "Initializing $line"
                gocryptfs -init -allow_other -extpass 'printenv GOCRYPTFS_PSWD' -fg -nosyslog $line
            else
                echo "$line is not an initialized directory for gogryptfs. To auto-initialize it set environment-variable AUTOINIT=true"
            fi
        fi
    done   < /etc/gocryptfs/decrypt

    # line-buffer: since we're long-running in the foreground, we want each
    #   gocryptfs job's output without waiting for the first to finish.
    paste /etc/gocryptfs/decrypt /etc/gocryptfs/decrypt_mounts \
        | parallel --colsep='\t' --line-buffer "gocryptfs -allow_other -extpass 'printenv GOCRYPTFS_PSWD' -fg -nosyslog '{1}' '{2}'" &
fi

if [ -s /etc/gocryptfs/encrypt ] ; then
    sed s/decrypted/encrypted/g /etc/gocryptfs/encrypt \
    | tee /etc/gocryptfs/encrypt_mounts \
    | xargs mkdir -p

    # Remove existing mounts from prior killed process.
    while read line;
    do 
        fusermount -u $line
    done   < /etc/gocryptfs/encrypt_mounts

    while read line;
    do 
        if [ ! -f $line/.gocryptfs.reverse.conf ]; then
            if [ $AUTOINIT == "true" ]; then
                echo "Initializing $line"
                gocryptfs -init -reverse -allow_other -extpass 'printenv GOCRYPTFS_PSWD' -fg -nosyslog $line
            else
                echo "$line is not an initialized directory for gogryptfs. To auto-initialize it set environment-variable AUTOINIT=true"
            fi
        fi
    done   < /etc/gocryptfs/encrypt

    # line-buffer: since we're long-running in the foreground, we want each
    #   gocryptfs job's output without waiting for the first to finish.
    paste /etc/gocryptfs/encrypt /etc/gocryptfs/encrypt_mounts \
        | parallel --colsep='\t' --line-buffer "gocryptfs -reverse -allow_other -extpass 'printenv GOCRYPTFS_PSWD' -fg -nosyslog '{1}' '{2}'" &
fi

while true
do
    sleep 1
done
