#!/bin/bash

#sync with configs
source bot.conf
source build/envsetup.sh

export BUILD_FINISHED=false

sendMessage() {
MESSAGE=$1

curl -s "https://api.telegram.org/bot${BOT_API_KEY}/sendmessage" --data "text=$MESSAGE&chat_id=$CHAT_ID" 1> /dev/null

echo -e;
}

# Make clean build
echo "${blu}Make clean build?${txtrst}"
select yn in "Yes" "No"; do
    case $yn in
        Yes ) make clean && make clobber ; break;;
        No ) break;;
    esac
done

# supported devices
echo "${blu}Which device you want to build?${txtrst}"
select yn in "rolex" "santoni"; do
    case $yn in
        rolex ) sendMessage "Starting build $ROM for $DEVICE1" && lunch $ROM\_$DEVICE1-userdebug | tee lunch.log ; break;;
        santoni ) sendMessage "Starting build $ROM for $DEVICE" && lunch $ROM\_$DEVICE-userdebug | tee lunch.log ; break;;
    esac
done

# catch lunch error
if [ $? -eq 0 ]
then
        if [ $DEVICE1 ]; then
       	echo "Bringup Done... Starting Build\(brunch\)"
	sendMessage "Bringup Done... Starting build."
	brunch $DEVICE1 | tee build.log
        else
       	echo "Bringup Done... Starting Build\(brunch\)"
	sendMessage "Bringup Done... Starting build."
	brunch $DEVICE | tee build.log
        fi
#	mka aex | tee build.log
	#catch brunch error
	if [ $? -eq 0 ]
	then
		echo "build DONE :)"
		sendMessage "build DONE !"

		BUILD_FINISHED=true
		if [ $BUILD_FINISHED = true  ] ; then

			#since build iz done lets upload
			OUTPUT_FILE=$(grep -o -P '(?<=Package\ Complete).*(?=.zip)' build.log)'.zip'
	#		OUTPUT_FILE=$(grep -o -P '(?<=Zip: ).*(?=.zip)' build.log)'.zip'
			OUTPUT_LOC=$(echo $OUTPUT_FILE | cut -f2 -d":")
			echo $OUTPUT_LOC

			#upload to gdrive
			sendMessage "Uploading to Gdrive..."
			gdrive upload $OUTPUT_LOC | tee upload.log

			#get file id
			sed -e 's/.*Uploaded\(.*\)at.*/\1/' upload.log >> id.txt
			sendMessage "Upload Finished."
			sed -e '1d' id.txt >> final.txt
			FILE_ID=$(cat final.txt)

			#set permission to sharing
			gdrive share $FILE_ID

			#finally output the sharing url
			URL='https://drive.google.com/open?id='$FILE_ID
			SHARE="$(echo -e "${URL}" | tr -d '[:space:]')"
			echo $SHARE >> url.txt

			#MESSAGE=$(cat url.txt)
			echo $SHARE
			sendMessage $SHARE

			BEELD_FINISHED=true
			#clean up
			rm upload.log final.txt id.txt url.txt
		fi
	else
		sendMessage "beeld phel nibba"
		echo "brunch phel"
	fi
else
       	echo "Bringup PHEL..."
	sendMessage "Bringup PHEL... sad"
fi

rm lunch.log

if [ $BUILD_FINISHED = true  ] ; then

# Some Extra Summary to share
MD5=`md5sum ${OUTPUT_LOC} | awk '{ print $1 }'`

if [ $DEVICE1 ]; then
read -r -d '' SUMMARY << EOM
ROM: $ZIPNAME1
Build: $BUILD_TYPE
LINK: $SHARE
NOTES: $NOTES
MD5: $MD5
EOM
else
read -r -d '' SUMMARY << EOM
ROM: $ZIPNAME
Build: $BUILD_TYPE
LINK: $SHARE
NOTES: $NOTES
MD5: $MD5
EOM
fi
                curl -s "https://api.telegram.org/bot${BOT_API_KEY}/sendmessage" --data "text=$SUMMARY&chat_id=$CHAT_ID" 1> /dev/null
echo -e;

fi


exit 1
