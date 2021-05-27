#!/bin/bash

convertsecs() {
 ((h=${1}/3600))
 ((m=(${1}%3600)/60))
 ((s=${1}%60))
 printf "%02dm %02ds\n" $m $s
}

# get environment variables
source ~/kranel/scripts/stable_vars.sh
#
cd ${PROJECT_DIRECTORY} || exit

#Merge to master and build there
git checkout master && git merge labs

# compilation
#
# First we need number of jobs
COUNT="$(grep -c '^processor' /proc/cpuinfo)"
export JOBS="$((COUNT * 2))"

export ARCH=arm64
export SUBARCH=arm64

echo "Building on branch: $BRANCH"

rm -f changelog.txt
git log --oneline "origin/${BRANCH}..HEAD" >> changelog.txt

echo "Version: $VERSION"

make clean && make mrproper
rm -rf out
mkdir out

if [ $SDCARD_FS = "N" ] || [ $SDCARD_FS = "n" ]; then 
  sed -i 's/CONFIG_SDCARD_FS=y/# CONFIG_SDCARD_FS is not set/' arch/arm64/configs/${DEFCONFIG}
  DEF_REG=0
fi

make O=out ${DEFCONFIG}

# 		cp out/.config arch/arm64/configs/${DEFCONFIG}
# 		git add arch/arm64/configs/${DEFCONFIG}
# 		git commit --signoff -m "defconfig: Regenerate and save
#
# This is an auto-generated commit"

START=$(date +"%s")

if [[ ${COMPILER} == "GCC" ]]; then
	make -j${JOBS} O=out
else
	export KBUILD_COMPILER_STRING="$(${CLANG_PATH}/bin/clang --version | head -n 1 | sed -e 's/  */ /g' -e 's/[[:space:]]*$//')";

	PATH="${CLANG_PATH}/bin:${PATH}" \
	make O=out -j${JOBS} \
	CC="clang" \
	CLANG_TRIPLE="aarch64-linux-gnu-" \
	CROSS_COMPILE="aarch64-linux-gnu-" \
	CROSS_COMPILE_ARM32="arm-linux-gnueabi-" \
	LD=ld.lld \
	AR=llvm-ar \
	NM=llvm-nm \
	OBJCOPY=llvm-objcopy \
	OBJDUMP=llvm-objdump \
	STRIP=llvm-strip | tee build.log
fi

END=$(date +"%s")
DIFF=$((END - START))

export OUT_IMAGE="${PROJECT_DIRECTORY}/out/arch/arm64/boot/Image.gz"
# export OUT_IMAGE="${PROJECT_DIRECTORY}/out/arch/arm64/boot/Image.gz-dtb"

if [ ! -f "${OUT_IMAGE}" ]; then
  telegram-send "Build failed!"
	exit 1;
fi

# Move kernel image and dtb to anykernel3 folder
cp ${OUT_IMAGE} ${ANYKERNEL_DIR}
find out/arch/arm64/boot/dts -name '*.dtb' -exec cat {} + > ${ANYKERNEL_DIR}/dtb


# POST ZIP
cd ${ANYKERNEL_DIR}
rm -rf *.zip
zip -r9 "${ZIPNAME}" * -x .git "Image"
CAPTION="sha1sum: $(sha1sum ${ZIPNAME} | awk '{ print $1 }')" 
telegram-send --file "${ZIPNAME}" --caption "${CAPTION}" --timeout 60.0

# Sleep to prevent errors such as:
# {"ok":false,"error_code":429,"description":"Too Many Requests: retry after 8","parameters":{"retry_after":8}}
sleep 2;

telegram-send "Build completed in $(convertsecs $DIFF)"
clear

cd ${PROJECT_DIRECTORY}

if [ $SDCARD_FS = "N" ] || [ $SDCARD_FS = "n" ]; then 
  sed -i 's/# CONFIG_SDCARD_FS is not set/CONFIG_SDCARD_FS=y/' arch/arm64/configs/${DEFCONFIG}
  DEF_REG=0
fi
