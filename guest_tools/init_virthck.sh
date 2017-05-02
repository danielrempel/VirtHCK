#!/bin/bash

# TODO: All output must be during action execution, not during argument parsing

help ()
{
	echo "Usage: `basename $0` --C <dir> [options ..]"
	echo "init_virthck.sh -- a helper script for prepating VHCK setups"
	echo -e "Args:"
	echo -e "\t" "--help\t\t\t\t\t-- help message"
	echo -e "\t" "--C <VirtHCK instance dir>\t\t-- set VHCK directory; mandatory!"
	echo -e "\t" "--client-iso <iso path for both clients> -- changes CDROM_CLIENT variable. Depends on defaults in CLIENT{1,2}_IMAGE"
	echo -e "\t" "--qemu-bin <path/to/qemu-binary>\t-- sets QEMU_BIN"
	echo -e "\t" "--id <int>\t\t\t\t-- sets UNIQUE_ID"
	echo -e "\t" "--unsafe-cache <on|off>\t\t-- set UNSAFE_CACHE"
	echo -e "\t" "--client-world-access <on|off>\t\t-- set CLIENT_WORLD_ACESS"

	echo -e "VM images related options:"
	echo -e "\t" "--st <rar file path>\t\t\t-- unpacks studio image and changes the config appropriately"
	echo -e "\t" "--cst <imagename.qcow2>\t\t-- creates a new image for studio in VHCK_DIR/images/ amd changes config"
	echo -e "\t" "--st-size <int>G\t\t\t-- studio image size"
	echo
	echo -e "\t" "--c1 <rar file path>\t\t\t-- unpacks client 1 image and changes the config appropriately"
	echo -e "\t" "--cc1 <imagename.qcow2>\t\t-- creates a new image for client 1 in VHCK_DIR/images/ amd changes config"
	echo -e "\t" "--c1-size <int>G\t\t\t-- client1 image size"
	echo
	echo -e "\t" "--c2 <rar file path>\t\t\t-- unpacks client 2 image and changes the config appropriately"
	echo -e "\t" "--cc2 <imagename.qcow2>\t\t-- creates a new image for client 2 in VHCK_DIR/images/ amd changes config"
	echo -e "\t" "--c2-size <int>G\t\t\t-- client2 image size"
	exit
}

# <dir> <fail message>
checkDirExists()
{
if [ ! -d "$1" ];
then
	echo "$2 ($1)"
	exit 1
fi
}

# <file> <fail message>
checkFileExists()
{
if [ ! -e "$1" ];
then
	echo "$2 ($1)"
	exit 1
fi
}

# <VirtHCK dir> <variable name> <new value>
changeConfigLine()
{
	CURR_CONFIG_LINE=`grep "$2=" $1/hck_setup.cfg`
	NEW_CONFIG_LINE="$2=$3"
	#echo "Config: '${CURR_CONFIG_LINE} -> ${NEW_CONFIG_LINE}'" 1>&2
	sed -i.bak -e "s@${CURR_CONFIG_LINE}@${NEW_CONFIG_LINE}@" $1/hck_setup.cfg
	#echo "Result: " `grep "$2=" $1/hck_setup.cfg`
	echo "Set $2=$3"
}

# <image> <dir>
processArchive()
{
	LINE_NUM=`unrar l $1 | grep -n -- "--" | head -n 1 | sed "s/://;s/-//g"`
	let LINE_NUM+=1
	FILENAME=`unrar l $1 | awk -v line_num=${LINE_NUM} 'NR==line_num {printf $NF}' | awk -F '/' '{printf $NF}'`
	#echo unrar e $1 $2 1>&2
	echo Extracting $1 to $2 1>&2
	unrar e $1 $2 1>&2
	echo ${FILENAME}
}

# <image> <VirtHCK dir> <VARIABLE>
processImage()
{
	FILENAME=`processArchive $1 $2/images`
	echo Extracted img: ${FILENAME} 1>&2
	changeConfigLine "$2" "$3"  "\${IMAGES_DIR}/$FILENAME"
	#CURR_CONFIG_LINE=`grep "$3=" $2/hck_setup.cfg`
	#NEW_CONFIG_LINE="$3=\${IMAGES_DIR}/${FILENAME}"
	#echo "Config: '${CURR_CONFIG_LINE} -> ${NEW_CONFIG_LINE}'" 1>&2
	#sed -i.bak -e "s@${CURR_CONFIG_LINE}@${NEW_CONFIG_LINE}@" $2/hck_setup.cfg
}

echo "NOTE:"
echo "The script heavily depends on unrar's output. It may go haywire with different versions/implementations"
echo "Tuned for 'UNRAR 5.30 beta 2 freeware'"
echo "As of now it also depends on different config defaults like images dir etc"
echo

if [[ "$#" = "0" ]];
then
	help
fi

while [[ $# -gt 0 ]]
do
arg="$1"

case $arg in
	--help)
		help
		exit
	;;
	--st)
		if [ -n "$NEW_STUDIO_IMG" ]; then
			echo "Can't simultaneously unpack and create new studio image"
			help
		fi
		echo "Studio img: " $2
		STUDIO_IMG="$2"
		shift; shift;
	;;
	--c1)
		if [ -n "$NEW_CLIENT1_IMG" ]; then
			echo "Can't simultaneously unpack and create new client 1 image"
			help
		fi
		echo "Client1: " $2
		CLIENT1_IMG="$2"
		shift; shift;
	;;
	--c2)
		if [ -n "$NEW_CLIENT2_IMG" ]; then
			echo "Can't simultaneously unpack and create new client 2 image"
			help
		fi
		echo "Client2: " $2
		CLIENT2_IMG="$2"
		shift; shift;
	;;
	--C)
		echo "VirtHCK dir: " $2
		VHCK_DIR="$2"
		shift; shift;
	;;
	--client-iso)
		echo "CDROM image: $2"
		CDROM_IMG=$2
		shift;shift;
	;;
	--qemu-bin)
		echo "Qemu binary: $2"
		QEMU_BIN=$2
		shift;shift;
	;;
	--id)
		echo "New unique setup id: $2"
		UNIQUE_ID=$2
		shift;shift;
	;;
	--unsafe-cache)
		if [ "$2" != "on" ] && [ "$2" != "off" ]; then
			echo "Wrong argument for --unsafe-cache"
			help
		fi
		echo "Unsafe cache is $2"
		UNSAFE_CACHE=$2
		shift;shift;
	;;
	--client-world-access)
		if [ "$2" != "on" ] && [ "$2" != "off" ]; then
			echo "Wrong argument for --client-world-access"
			help
		fi
		echo "Client world access is $2"
		CLIENT_WORLD_ACCESS=$2
		shift;shift;
	;;
	--cst)
		if [ -n "$STUDIO_IMG" ]; then
			echo "Can't simultaneously unpack and create new studio image"
			help
		fi
		echo "New studio image: $2"
		NEW_STUDIO_IMG=$2
		shift;shift;
	;;
	--st-size)
		echo "New studio image size: $2"
		NEW_STUDIO_IMG_SIZE=$2
		shift;shift;
	;;
	--cc1)
		if [ -n "$CLIENT1_IMG" ]; then
			echo "Can't simultaneously unpack and create new client 1 image"
			help
		fi
		echo "New client 1 image: $2"
		NEW_CLIENT1_IMG=$2
		shift;shift;
	;;
	--c1-size)
		echo "New client 1 image size: $2"
		NEW_CLIENT1_IMG_SIZE=$2
		shift;shift;
	;;
	--cc2)
		if [ -n "$CLIENT2_IMG" ]; then
			echo "Can't simultaneously unpack and create new client 2 image"
			help
		fi
		echo "New client 2 image: $2"
		NEW_CLIENT2_IMG=$2
		shift;shift;
	;;
	--c2-size)
		echo "New client 2 image size: $2"
		NEW_CLIENT2_IMG_SIZE=$2
		shift;shift;
	;;
	*)
		echo "Unknown arg: " $1
		help
		shift
	;;
esac

done

checkDirExists "$VHCK_DIR" "VirtHCK directory not found"
checkDirExists "$VHCK_DIR/images" "VirtHCK images directory not found"

if [ -n "$STUDIO_IMG" ]; then
	checkFileExists "$STUDIO_IMG" "Studio image not found";
	processImage "$STUDIO_IMG" "$VHCK_DIR" STUDIO_IMAGE
fi
if [ -n "$CLIENT1_IMG" ]; then
	checkFileExists "$CLIENT1_IMG" "Client1 image not found";
	processImage "$CLIENT1_IMG" "$VHCK_DIR" CLIENT1_IMAGE
fi
if [ -n "$CLIENT2_IMG" ]; then
	checkFileExists "$CLIENT2_IMG" "Client2 image not found";
	processImage "$CLIENT2_IMG" "$VHCK_DIR" CLIENT2_IMAGE
fi

if [ -n "$NEW_STUDIO_IMG" ] && [ -n "$NEW_STUDIO_IMG_SIZE" ] && [ -z "$STUDIO_IMG" ]; then
	# here we suppose that $STUDIO_IMG isn't set
	echo "Creating studio image $NEW_STUDIO_IMG"
	qemu-img create -f qcow2 $VHCK_DIR/images/$NEW_STUDIO_IMG $NEW_STUDIO_IMG_SIZE
	changeConfigLine "$VHCK_DIR" "STUDIO_IMAGE" "\${IMAGES_DIR}/$NEW_STUDIO_IMG"
fi
if [ -n "$NEW_CLIENT1_IMG" ] && [ -n "$NEW_CLIENT1_IMG_SIZE" ] && [ -z "$CLIENT1_IMG" ]; then
	# here we suppose that $CLIENT1_IMG isn't set
	echo "Creating client 1 image $NEW_CLIENT1_IMG"
	qemu-img create -f qcow2 $VHCK_DIR/images/$NEW_CLIENT1_IMG $NEW_CLIENT1_IMG_SIZE
	changeConfigLine "$VHCK_DIR" "CLIENT1_IMAGE" "\${IMAGES_DIR}/$NEW_CLIENT1_IMG"
fi
if [ -n "$NEW_CLIENT2_IMG" ] && [ -n "$NEW_CLIENT2_IMG_SIZE" ] && [ -z "$CLIENT2_IMG" ]; then
	# here we suppose that $CLIENT2_IMG isn't set
	echo "Creating client 2 image $NEW_CLIENT2_IMG"
	qemu-img create -f qcow2 $VHCK_DIR/images/$NEW_CLIENT2_IMG $NEW_CLIENT2_IMG_SIZE
	changeConfigLine "$VHCK_DIR" "CLIENT2_IMAGE" "\${IMAGES_DIR}/$NEW_CLIENT2_IMG"
fi

if [ -n "$CDROM_IMG" ]; then
	checkFileExists "$CDROM_IMG" "CDROM image not found";
	IMG_NAME=`basename $CDROM_IMG`
	echo "Copying $IMG_NAME to $VHCK_DIR/images"
	cp $CDROM_IMG $VHCK_DIR/images/
	changeConfigLine "$VHCK_DIR" "CDROM_CLIENT" "\${IMAGES_DIR}/$IMG_NAME"
fi
if [ -n "$QEMU_BIN" ]; then
	if [ ! -e "$QEMU_BIN" ]; then
		echo "WARNING: QEMU_BIN($QEMU_BIN) does not exist"
	fi
	changeConfigLine "$VHCK_DIR" "QEMU_BIN" "$QEMU_BIN"
fi
if [ -n "$UNIQUE_ID" ]; then
	changeConfigLine "$VHCK_DIR" "UNIQUE_ID" "$UNIQUE_ID"
fi
if [ -n "$UNSAFE_CACHE" ]; then
	changeConfigLine "$VHCK_DIR" "UNSAFE_CACHE" "$UNSAFE_CACHE"
fi
if [ -n "$CLIENT_WORLD_ACCESS" ]; then
	changeConfigLine "$VHCK_DIR" "CLIENT_WORLD_ACCESS" "$CLIENT_WORLD_ACCESS"
fi

if [ -e "$VHCK_DIR/hck_setup.cfg.bak" ]; then
	rm -v "$VHCK_DIR/hck_setup.cfg.bak"
fi
