#!/bin/bash

if [ "$NDK" = "" ]; then
	echo NDK variable not set, assuming ${HOME}/android-ndk
	export NDK=${HOME}/android-ndk
fi

SYSROOT=$NDK/platforms/android-3/arch-arm
# Expand the prebuilt/* path into the correct one
TOOLCHAIN=`echo $NDK/toolchains/arm-linux-androideabi-4.4.3/prebuilt/*-x86`
#TOOLCHAIN=`echo $NDK/toolchains/arm-linux-androideabi-4.4.3/prebuilt/windows`
export PATH=$TOOLCHAIN/bin:$PATH
echo $TOOLCHAIN

rm -rf build/ffmpeg
mkdir -p build/ffmpeg
cd ffmpeg

# Don't build any neon version for now
for version in armv5te armv7a; do

	DEST=../build/ffmpeg
	FLAGS="--target-os=linux --cross-prefix=/home/cladden/android-ndk/toolchains/arm-linux-androideabi-4.4.3/prebuilt/linux-x86/bin/arm-linux-androideabi- --arch=arm"
	FLAGS="$FLAGS --sysroot=$SYSROOT"
#	FLAGS="$FLAGS --soname-prefix=/data/data/com.bambuser.broadcaster/lib/"
#	FLAGS="$FLAGS --enable-shared --disable-symver"
	FLAGS="$FLAGS --enable-static"
	FLAGS="$FLAGS --disable-shared"
	FLAGS="$FLAGS --extra-libs=-static"
	FLAGS="$FLAGS --extra-cflags=-static"
  FLAGS="$FLAGS --enable-small"
#  FLAGS="$FLAGS --enable-libmp3lame"
#	FLAGS="$FLAGS --enable-small --optimization-flags=-O2"
#	FLAGS="$FLAGS --disable-everything"
#	FLAGS="$FLAGS --enable-encoder=mpeg2video --enable-encoder=nellymoser"
#	FLAGS="$FLAGS --enable-decoder=aac"

	case "$version" in
		neon)
			EXTRA_CFLAGS="-march=armv7-a -mfloat-abi=softfp -mfpu=neon -O2"
			EXTRA_LDFLAGS="-Wl,--fix-cortex-a8"
			# Runtime choosing neon vs non-neon requires
			# renamed files
			ABI="armeabi-v7a"
			;;
		armv7a)
			EXTRA_CFLAGS="-march=armv7-a -mfloat-abi=softfpu -O2"
			EXTRA_LDFLAGS=""
			ABI="armeabi-v7a"
			;;
		*)
			EXTRA_CFLAGS="-ftree-vectorize -fomit-frame-pointer -O4 -ffast-math"
			EXTRA_LDFLAGS=""
			ABI="armeabi"
			;;
	esac
	DEST="$DEST/$ABI"
	FLAGS="$FLAGS --prefix=$DEST"

	mkdir -p $DEST
	echo $FLAGS --extra-cflags="$EXTRA_CFLAGS" --extra-ldflags="$EXTRA_LDFLAGS" > $DEST/info.txt
	./configure $FLAGS --extra-cflags="$EXTRA_CFLAGS" --extra-ldflags="$EXTRA_LDFLAGS" | tee $DEST/configuration.txt
	[ $PIPESTATUS == 0 ] || exit 1
	make clean
	make -j4 || exit 1
	make install || exit 1

done

