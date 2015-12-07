#!/bin/sh
DIRECTORY="/mnt/data/scripts/screenshots"

UPLOAD_DESTINATION="server" #Server or imgur
#required when using server
SSH_PARAMS=""
SSH_ADDRESS="image_sharing@"
REMOTE_DIRECTORY="/home/image_sharing"
DOMAIN="https://i.maciekmm.net/"

#required when using imgur
IMGUR_HEADER="Authorization: Client-ID xxx"

#http://stackoverflow.com/questions/592620/check-if-a-program-exists-from-a-bash-script
if hash xfce4-screenshooter 2>/dev/null; then
    cmd="xfce4-screenshooter -r --save $DIRECTORY"
else
    if hash scrot 2>/dev/null; then
        cmd="scrot --select $DIRECTORY/%Y-%m-%d-%H-%M-%S.png"
    fi
fi

#http://stackoverflow.com/a/2440602/2161610
#put into stdin
set -- $cmd

[ -z "$cmd" ] && { echo "No supported screenshooter found."; exit; }

#avoid running two or more instances of screenshooter if clicked twice
#[ -z "$(pidof $1)" ] || { echo "Already running"; exit; }

directoryBefore=($DIRECTORY/*)
$($cmd)
directoryAfter=($DIRECTORY/*)

#diff the file list, we can't use direct output from binaries, because xfce4-sc is stupid
file=$(echo ${directoryBefore[@]} ${directoryAfter[@]} | tr ' ' '\n' | sort | uniq -u)

[[ -z "$file" ]] && { echo "No screenshot taken"; exit; }

fileName=${file##*/}
if [[ "$UPLOAD_DESTINATION" == "server" ]]; then
    if hash rsync 2>/dev/null; then
        rsync -ar $DIRECTORY/ -e "ssh $SSH_PARAMS" $SSH_ADDRESS:$REMOTE_DIRECTORY
    else
	(echo "
	cd $REMOTE_DIRECTORY
        put $file
        bye") | (sftp $SSH_PARAMS $SSH_ADDRESS)
    fi
    id=$fileName
    echo "$DOMAIN${id/\.png/}" | $(xclip -selection clipboard)
else
    resp=$(curl --header "$IMGUR_HEADER" --form "image=$(base64 $file)" https://api.imgur.com/3/image)
    id=$(echo $resp | egrep -o '"id":"[^"]+"' | cut -d "\"" -f 4)
    deleteHash=$(echo $resp | egrep -o '"deletehash":"[^"]+"' | cut -d "\"" -f 4)
    echo "$fileName-$deleteHash">>$DIRECTORY/delete-hashes
    echo "https://imgur.com/$id.png" | $(xclip -selection clipboard)
fi
#get filename



