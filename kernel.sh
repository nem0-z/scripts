#!/bin/bash

convertsecs() {
 ((h=${1}/3600))
 ((m=(${1}%3600)/60))
 ((s=${1}%60))
 printf "%02dm %02ds\n" $m $s
}

# get environment variables
source env_vars.sh
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
if [ $CHOICE = "Y" ] || [ $CHOICE = "y" ]; then 
  make clean
  make mrproper
  rm -rf out
  mkdir out
fi

read -p "Do you want to regenerate defconfig? [Y/N]" DEF_REG

rm -f changelog.txt
git log --oneline "origin/${BRANCH}..HEAD" >> changelog.txt

echo "Version: $VERSION"
echo "Changelog since last origin push:"
cat changelog.txt
read -p "Press enter to start build "

make O=out ${DEFCONFIG}

if [ $DEF_REG = "Y" ] || [ $DEF_REG = "y" ]; then
		cp out/.config arch/arm64/configs/${DEFCONFIG}
		git add arch/arm64/configs/${DEFCONFIG}
		git commit --signoff -m "defconfig: regenerate and save

This is an auto-generated commit"
fi

#proton
export KBUILD_COMPILER_STRING="$(${CLANG_PATH}/bin/clang --version | head -n 1 | sed -e 's/  */ /g' -e 's/[[:space:]]*$//')";

START=$(date +"%s")

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


# POST ZIP OR REPORT FAILURE
cd ${ANYKERNEL_DIR}
rm -rf *.zip
# zip -r9 "${ZIPNAME}" * -x "Image"
zip -r9 "${ZIPNAME}" * -x .git
CAPTION="sha1sum: $(sha1sum ${ZIPNAME} | awk '{ print $1 }') completed in $(convertsecs $DIFF)" 
telegram-send --file "${ZIPNAME}" --caption "${CAPTION}" --timeout 60.0

cd ${script_dir} || exit
# Weeb/Hentai patch for custom boot.img
mkbootimg=${script_dir}/bin/mkbootimg
chmod 777 $mkbootimg

magiskboot=${script_dir}/bin/magiskboot
chmod 777 $magiskboot
# Undo Magisk want_initramfs hack ('want_initramfs' -> 'skip_initramfs')
$magiskboot --decompress ${ANYKERNEL_DIR}/Image.gz ${ANYKERNEL_DIR}/Image;
# original: $bin/magiskboot --hexpatch $decompressed_image 736B69705F696E697472616D667300 77616E745F696E697472616D667300;
$magiskboot --hexpatch ${ANYKERNEL_DIR}/Image 77616E745F696E697472616D667300 736B69705F696E697472616D667300;
$magiskboot --compress=gzip ${ANYKERNEL_DIR}/Image ${ANYKERNEL_DIR}/Image.gz;

mkdir -p ${script_dir}/out

export OS="10.0.0"
export SPL="2020-09"

$mkbootimg \
    --kernel ${ANYKERNEL_DIR}/Image.gz \
    --ramdisk ${script_dir}/ramdisk.gz \
    --cmdline 'androidboot.hardware=qcom androidboot.console=ttyMSM0 androidboot.memcg=1 lpm_levels.sleep_disabled=1 video=vfb:640x400,bpp=32,memsize=3072000 msm_rtb.filter=0x237 service_locator.enable=1 swiotlb=2048 firmware_class.path=/vendor/firmware_mnt/image loop.max_part=7 androidboot.usbcontroller=a600000.dwc3 androidboot.vbmeta.avb_version=1.0 buildvariant=user' \
    --base           0x00000000 \
    --pagesize       4096 \
    --kernel_offset  0x00008000 \
    --ramdisk_offset 0x02000000 \
    --second_offset  0x00f00000 \
    --tags_offset    0x00000100 \
    --dtb            ${ANYKERNEL_DIR}/dtb \
    --dtb_offset     0x01f00000 \
    --os_version     $OS \
    --os_patch_level $SPL \
    --header_version 2 \
    -o ${script_dir}/out/${NEW_IMG_NAME}

# Sleep to prevent errors such as:
# {"ok":false,"error_code":429,"description":"Too Many Requests: retry after 8","parameters":{"retry_after":8}}
sleep 2;

cd ${script_dir}/out || exit
telegram-send --file "${NEW_IMG_NAME}" --timeout 60.0

cd ${PROJECT_DIRECTORY} || exit
if [ -s "changelog.txt" ]; then
  telegram-send --file changelog.txt --caption "changelog since last origin push" --timeout 60.0
fi 

