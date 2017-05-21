#!/bin/bash
export IFS=$'\n'
DIR=$(cd $(dirname $0); pwd)
cd $DIR
source ./lock.sh

DATE=`date +%Y_%m_%d`
argv=("$@")
CMDNAME=`basename $0`

if [ $# -eq 0 ]; then
    echo "Usage : ${CMDNAME} [dirname]"
    exit 1
fi

TMP_DIR=/var/tmp/crond

for TARGET_DIR in ${argv}
do

## wav2mp3
for FILENAME in `find "${TARGET_DIR}" -name "*.wav" | sort`
do
	echo "${FILENAME}"
	lame -h -q 0 --preset insane --highpass -1 --lowpass -1 "${FILENAME}" "${FILENAME%%.wav}.mp3" || continue
	rm -f "${FILENAME}" || continue
done

## ogg2mp3
for FILENAME in `find "${TARGET_DIR}" -name "*.ogg" | sort`
do
	echo "${FILENAME}"

	ffmpeg -y -i "${FILENAME}" -ab 320k -map_metadata 0:s:0 -id3v2_version 3 -write_id3v1 1 "${FILENAME/.ogg/.mp3}" || continue
	rm -f "${FILENAME}" || continue
done


## m4a2mp3
for FILENAME in `find "${TARGET_DIR}" -name "*.m4a" | sort`
do
    echo "${FILENAME}"

    i=${FILENAME%%.m4a}
    serial=`uuidgen`
    id3="${TMP_DIR}/$serial.id3"

    echo "Converting: $i.m4a -> $i.mp3"
    mp4info "$i.m4a" "$i.m4a" 2> ${TMP_DIR}/xxx || continue
    mv ${TMP_DIR}/xxx "$id3" || continue
    ffmpeg -i "$i.m4a" "${TMP_DIR}/$serial.wav" || continue

    title=`grep ^title: "$id3" | sed 's/^title: //' | nkf -Ws`
    album=`grep ^album: "$id3" | sed 's/^album: //' | nkf -Ws`
    mydate=`grep ^date: "$id3" | sed 's/^date: //' | nkf -Ws`
    track=`grep ^track: "$id3" | sed 's/^track: //' | nkf -Ws`
    album_artist=`grep ^artist: "$id3" | sed 's/^album_artist: //' | sed 's/^artist: //' | nkf -Ws`

    comment="Setting id3 tag info. Artist: [$album_artist] Album: [$album] Title: [$title] Year: [$mydate] Track: [$track]"

    echo $comment | nkf -Sw
    lame -h -q 0 --preset insane --highpass -1 --lowpass -1 --add-id3v2 --tt "$title" --ta "$album_artist" --tl "$album" --ty "$mydate" --tn "$track" "${TMP_DIR}/$serial.wav" "$i.mp3" || continue
    rm -f "$id3"
    rm -f "${TMP_DIR}/$serial.wav"
    rm -f "${FILENAME}"

done

## flac2mp3
for FILENAME in `find "${TARGET_DIR}" -name "*.flac" | sort`
do

    echo "${FILENAME}"

    i=${FILENAME%%.flac}
    serial=`uuidgen` 
    id3="${TMP_DIR}/${serial}.id3"

    echo "Converting: $i.flac -> $i.mp3"
    flac -F -d "${FILENAME}" -o "${TMP_DIR}/${serial}.wav" || continue
    metaflac --list "$i.flac" > ${TMP_DIR}/xxx || continue
    mv ${TMP_DIR}/xxx "$id3"

    title=`grep "TITLE=" "$id3" | cut -d '=' -f 2 | nkf -Ws`
    album=`grep "ALBUM=" "$id3" | cut -d '=' -f 2 | nkf -Ws`
    mydate=`grep "DATE=" "$id3" | cut -d '=' -f 2 | nkf -Ws`
    track=`grep "TRACK=" "$id3" | cut -d '=' -f 2 | nkf -Ws`
    album_artist=`grep "ARTIST=" "$id3" | cut -d '=' -f 2-3 | nkf -Ws`

    comment="Setting id3 tag info. Artist: [$album_artist] Album: [$album] Title: [$title] Year: [$mydate] Track: [$track]"

    echo $comment | nkf -Sw
    lame -h -q 0 --preset insane --highpass -1 --lowpass -1 --add-id3v2 --tt "$title" --ta "$album_artist" --tl "$album" --ty "$mydate" --tn "$track" "${TMP_DIR}/$serial.wav" "$i.mp3" || continue
    rm -f "$id3"
    rm -f "${TMP_DIR}/${serial}.wav"
    rm -f "${FILENAME}"

done

## aif2mp3
for FILENAME in `find "${TARGET_DIR}" -name "*.aif" | sort`
do
	echo "${FILENAME}"
	i=${FILENAME%%.aif}
	lame -h -q 0 --preset insane --highpass -1 --lowpass -1 "${FILENAME}" "${FILENAME%%.aif}.mp3" || continue
	rm -f "${FILENAME}"
done

## aiff2mp3
for FILENAME in `find "${TARGET_DIR}" -name "*.aiff" | sort`
do
    echo "${FILENAME}"
    i=${FILENAME%%.aiff}
    lame -h -q 0 --preset insane --highpass -1 --lowpass -1 "${FILENAME}" "${FILENAME%%.aiff}.mp3" || continue
    rm -f "${FILENAME}"
done

## mpc2mp3
for FILENAME in `find "${TARGET_DIR}" -name "*.mpc" | sort`
do
    echo "${FILENAME}"
    i=${FILENAME%%.mpc}
    serial=`uuidgen`
    mpcdec "${FILENAME}" "${TMP_DIR}/${serial}.wav" || continue
    lame -h -q 0 --preset insane --highpass -1 --lowpass -1 "${TMP_DIR}/${serial}.wav" "${i}.mp3" || continue
    rm -f "${TMP_DIR}/${serial}.wav"
    rm -f "${FILENAME}"
done

done

## delete txt
rm -f ${TMP_DIR}/*.id3
rm -f ${TMP_DIR}/*.wav
find "${TARGET_DIR}" -name *.txt -exec rm -f {} \;
find "${TARGET_DIR}" -name *.url -exec rm -f {} \;
find "${TARGET_DIR}" -name "Thumbs.db" -exec rm -f {} \;
find "${TARGET_DIR}" -name ".DS_store" -exec rm -Rf {} \;
