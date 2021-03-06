#! /usr/bin/env bash
# vim: set ts=3 sw=3 noet ft=sh : bash

. ./libretro-config.sh

#split TARGET_ABI string into an array we can iterate over
IFS=' ' read -ra ABIS <<< "$TARGET_ABIS"

# BSDs don't have readlink -f
read_link()
{
	TARGET_FILE="$1"
	cd $(dirname "$TARGET_FILE")
	TARGET_FILE=$(basename "$TARGET_FILE")

	while [ -L "$TARGET_FILE" ]
	do
		TARGET_FILE=$(readlink "$TARGET_FILE")
		cd $(dirname "$TARGET_FILE")
		TARGET_FILE=$(basename "$TARGET_FILE")
	done

	PHYS_DIR=$(pwd -P)
	RESULT="$PHYS_DIR/$TARGET_FILE"
	echo $RESULT
}

SCRIPT=$(read_link "$0")
echo "Script: $SCRIPT"
BASE_DIR=$(dirname $SCRIPT)
RARCH_DIR=$BASE_DIR/dist
RARCH_DIST_DIR=$RARCH_DIR/android
FORMAT=_android
FORMAT_EXT=so

die()
{
	echo $1
	#exit 1
}

# $1 is core name
# $2 is subdir (if there's no subdir, put "." here)
# $3 is appendage to core name for output JNI file
build_libretro_generic_makefile()
{
	cd $BASE_DIR
	if [ -d "libretro-${1}" ]; then
		echo "=== Building ${1} ==="
		cd libretro-${1}
		cd ${2}
		for a in "${ABIS[@]}"; do
			if [ -z "${NOCLEAN}" ]; then
				ndk-build clean APP_ABI=${a} || die "Failed to clean ${a} ${1}"
			fi
			ndk-build -j$JOBS APP_ABI=${a} || die "Failed to build  ${a} ${1}"
			cp ../libs/${a}/libretro${3}.${FORMAT_EXT} $RARCH_DIST_DIR/${a}/${1}_libretro${FORMAT}.${FORMAT_EXT}
		done
	else
		echo "${1} not fetched, skipping ..."
	fi
}

create_dist_dir()
{
	if [ -d $RARCH_DIR ]; then
		echo "Directory $RARCH_DIR already exists, skipping creation..."
	else
		mkdir $RARCH_DIR
	fi

	if [ -d $RARCH_DIST_DIR ]; then
		echo "Directory $RARCH_DIST_DIR already exists, skipping creation..."
	else
		mkdir $RARCH_DIST_DIR
	fi
	
	for a in "${ABIS[@]}"; do
		if [ -d $RARCH_DIST_DIR/${a} ]; then
			echo "Directory $RARCH_DIST_DIR/${a} already exists, skipping creation..."
		else
			mkdir $RARCH_DIST_DIR/${a}
		fi
	done
}



create_dist_dir

if [ $1 ]; then
	WANT_CORES="$1"
else
WANT_CORES=" \
	2048 \
   4do \
	bluemsx \
	fmsx \
	mednafen_lynx \
	mednafen_ngp \
	mednafen_pce_fast \
	mednafen_supergrafx \
	mednafen_pcfx \
	mednafen_vb \
	mednafen_wswan \
	mednafen_psx \
	catsfc \
	snes9x \
	snes9x_next \
	genesis_plus_gx \
	virtualjaguar \
	stella \
	gpsp \
	dosbox \
	picodrive \
	3dengine \
	prosystem \
	meteor \
	nxengine \
	o2em \
	pcsx_rearmed \
	mupen64plus \
	vecx \
	nestopia \
	tgbdual \
	quicknes \
	handy \ 
   gambatte \
	prboom \
	tyrquake \
	vba_next \
	vbam \
	fceumm \
	dinothawr \
	desmume \
	fb_alpha \
	bsnes_mercury_performance \
	bsnes_performance \
	mame2000 \
	mame2003 \
	pocketsnes"
fi

for core in $WANT_CORES; do
	path="jni"
	append=""
	if [ $core = "snes9x" ] || [ $core = "genesis_plus_gx" ] || [ $core = "meteor" ] || [ $core = "nestopia" ] || [ $core = "yabause" ] || [ $core = "vbam" ] || [ $core = "vba_next" ] || [ $core = "ppsspp" ]; then
		path="libretro/jni"
	fi
	if [ $core = "gambatte" ]; then
		path="libgambatte/libretro/jni"
	fi
	if [ $core = "desmume" ]; then
		path="desmume/src/libretro/jni"
	fi
	if [ $core = "fb_alpha" ]; then
		path="svn-current/trunk/projectfiles/libretro-android/jni"
	fi

	if [ $core = "bsnes_mercury_performance" ] || [ $core = "bsnes_performance" ]; then
		path="target-libretro/jni"
		append="_$core"
	fi
	build_libretro_generic_makefile $core $path $append
done

