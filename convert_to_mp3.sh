#!/bin/bash
export IFS=$'\n'

DATE=`date +%Y_%m_%d`
argv=("$@")
CMDNAME=`basename $0`

if [ $# -eq 0 ]; then
    echo "Usage : ${CMDNAME} [dirname]"
    exit 1
fi

## https://qiita.com/hit/items/e95298f689a1ee70ae4a
_pcnt=`pgrep -fo ${CMDNAME} | wc -l`
if [ ${_pcnt} -gt 1 ]; then
	echo "This script has been running now. proc : ${_pcnt}"
  exit 1
fi

TMP_DIR=/var/tmp/crond

for ARG_DIR in ${argv}
do

TARGET_DIR=`readlink -f ${ARG_DIR}`

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
    mp4info "$i.m4a" > ${TMP_DIR}/xxx || continue
    mv ${TMP_DIR}/xxx "$id3" || continue
    cat "$id3"

    ffmpeg -i "$i.m4a" "${TMP_DIR}/$serial.wav" || continue

    title=`grep "^ Metadata Name:" "$id3" | sed 's/^ Metadata Name: //'`
    album=`grep "^ Metadata Album:" "$id3" | sed 's/^ Metadata Album: //'`
    mydate=`grep "^ Metadata Year:" "$id3" | sed 's/^ Metadata Year: //'`
    track=`grep "^ Metadata track:" "$id3" | sed 's/^ Metadata track: //' | cut -d " " -f 1`
    artist=`grep "^ Metadata Artist:" "$id3" | sed 's/^ Metadata Artist: //'`
    genre=`grep "^ Metadata Genre:" "$id3" | sed 's/^ Metadata Genre: //'`
    comment=`grep "^ Metadata Grouping:" "$id3" | sed 's/^ Metadata Grouping: //'`

    tags="Setting id3 tag info. Artist: [$artist] Album: [$album] Title: [$title] Year: [$mydate] Track: [$track] Genre: [$genre] Comment: [$comment]"
    echo $tags

    lame -h -q 0 --preset insane --highpass -1 --lowpass -1 --add-id3v2 --tt "$title" --ta "$artist" --tl "$album" --ty "$mydate" --tn "$track" --tg "${genre:-12}" --tc "${comment}" "${TMP_DIR}/$serial.wav" "$i.mp3" || continue

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

    artist=$(metaflac "${FILENAME}" --show-tag=ARTIST | sed s/.*=//g)
    title=$(metaflac "${FILENAME}" --show-tag=TITLE | sed s/.*=//g)
    album=$(metaflac "${FILENAME}" --show-tag=ALBUM | sed s/.*=//g)
    genre=$(metaflac "${FILENAME}" --show-tag=GENRE | sed s/.*=//g)
    track=$(metaflac "${FILENAME}" --show-tag=TRACKNUMBER | sed s/.*=//g)
    mydate=$(metaflac "${FILENAME}" --show-tag=DATE | sed s/.*=//g)

    tags="Setting id3 tag info. Artist: [$artist] Album: [$album] Title: [$title] Year: [$mydate] Track: [$track]"
    echo $tags

    lame -h -q 0 --preset insane --highpass -1 --lowpass -1 --add-id3v2 --tt "$title" --ta "$artist" --tl "$album" --ty "$mydate" --tn "$track" --tg "${genre:-12}" "${TMP_DIR}/$serial.wav" "$i.mp3" || continue

    rm -f "$id3"
    rm -f "${TMP_DIR}/${serial}.wav"
    rm -f "${FILENAME}"

done

## dsf2mp3
for FILENAME in `find "${TARGET_DIR}" -name "*.dsf" | sort`
do

	echo "${FILENAME}"

	i=${FILENAME%%.dsf}
	serial=`uuidgen`
	id3="${TMP_DIR}/${serial}.id3"

	ffmpeg -i ${FILENAME} "${TMP_DIR}/$serial.wav" || continue

	echo "Converting: ${FILENAME} -> $i.mp3"
	ffmpeg -i ${FILENAME} > ${TMP_DIR}/xxx 2>&1
	mv ${TMP_DIR}/xxx "$id3"
	cat "$id3" || continue

	## get the tags
	title=`grep "^    title           : " "$id3" | sed 's/^    title           : //'`
	album=`grep "^    album           : " "$id3" | sed 's/^    album           : //'`
	mydate=`grep "^    date            : " "$id3" | sed 's/^    date            : //' | cut -d "-" -f 1`
	track=`grep "^    track           : " "$id3" | sed 's/    track           : //'`
	artist=`grep "^    artist          : " "$id3" | sed 's/^    artist          : //'`
	comment=`grep "^      comment         : " "$id3" | sed 's/^      comment         : //'`

	tags="Setting id3 tag info. Artist: [$artist] Album: [$album] Title: [$title] Year: [$mydate] Track: [$track] Comment: [$comment]"
	echo $tags
	
	lame -h -q 0 --preset insane --highpass -1 --lowpass -1 --add-id3v2 --tt "$title" --ta "$artist" --tl "$album" --ty "$mydate" --tn "$track" --tc "${comment}" "${TMP_DIR}/$serial.wav" "$i.mp3" || continue

	rm -f "$id3"
	rm -f "${TMP_DIR}/$serial.wav"
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
