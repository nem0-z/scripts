#!/bin/bash

convertsecs() {
 ((h=${1}/3600))
 ((m=(${1}%3600)/60))
 ((s=${1}%60))
 printf "%02dm %02ds\n" $m $s
}

# get environment variables
source ~/kranel/scripts/nemo_vars.sh
#
cd ${PROJECT_DIRECTORY} || exit

# compilation
#
# First we need number of jobs
COUNT="$(grep -c '^processor' /proc/cpuinfo)"
export JOBS="$((COUNT * 2))"

export ARCH=arm64
export SUBARCH=arm64

echo "Building on branch: $BRANCH"

read -p "Do you want to build clean? [Y/N]" CHOICE
read -p "Do you want to regenerate defconfig? [Y/N]" DEF_REG

rm -f changelog.txt
git log --oneline "origin/${BRANCH}..HEAD" >> changelog.txt

echo "Version: $VERSION"
echo "Changelog since last origin push:"
cat changelog.txt
read -p "Press enter to start build "


if [ $CHOICE = "Y" ] || [ $CHOICE = "y" ]; then 
  make clean
  make mrproper
  rm -rf out
  mkdir out
fi

make O=out ${DEFCONFIG}

if [ $DEF_REG = "Y" ] || [ $DEF_REG = "y" ]; then
		cp out/.config arch/arm64/configs/${DEFCONFIG}
		git add arch/arm64/configs/${DEFCONFIG}
		git commit --signoff -m "nem0: Regenerate and save

This is an auto-generated commit"
fi

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
  # telegram-send "Build failed!"
  # telegram-send --file "${PROJECT_DIRECTORY}/build.log"
	exit 1;
fi

# Move kernel image and dtb to anykernel3 folder
cp ${OUT_IMAGE} ${ANYKERNEL_DIR}
find out/arch/arm64/boot/dts -name '*.dtb' -exec cat {} + > ${ANYKERNEL_DIR}/dtb


# POST ZIP
cd ${ANYKERNEL_DIR}
rm -rf *.zip
zip -r9 "${ZIPNAME}" * -x .git "Image"

cd ${PROJECT_DIRECTORY} || exit

clear
