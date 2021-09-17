#!/bin/bash

# Tell env that this is a standalone build
IS_KERNEL_STANDALONE=y
export IS_KERNEL_STANDALONE

# Compiler
export COMPILER="Clang"

# Export custom User and Host
KBUILD_BUILD_USER=nem0
KBUILD_BUILD_HOST=PacificOcean
export KBUILD_BUILD_USER KBUILD_BUILD_HOST

PROJECT_DIR=${HOME}/kranelstuff
PROJECT_DIRECTORY=${PROJECT_DIR}/dora_kernel_oneplus_sm8150
export PROJECT_DIR PROJECT_DIRECTORY

cd ${PROJECT_DIRECTORY} || exit

# AnyKernel3
ANYKERNEL_DIR="${PROJECT_DIR}/anykernel3"
export ANYKERNEL_DIR

if [[ ${COMPILER} == *"GCC"* ]]; then
	CROSS_COMPILE="${PROJECT_DIR}/gcc11/aarch64-linux-elf/bin/aarch64-linux-elf-"
	CROSS_COMPILE_ARM32="${PROJECT_DIR}/gcc32/bin/arm-eabi-"
else
  #proton
	CLANG_PATH=${PROJECT_DIR}/dora-clang
  
  #aosp
	# CLANG_PATH=${PROJECT_DIR}/aosp-clang
  # GCC_PATH=${PROJECT_DIR}/aosp-gcc64
  # GCC32_PATH=${PROJECT_DIR}/aosp-gcc32
fi
export CROSS_COMPILE CROSS_COMPILE_ARM32 
# export GCC_PATH GCC32_PATH

# get current branch and kernel patch level
CUR_BRANCH=$(git rev-parse --abbrev-ref HEAD)
export CUR_BRANCH

BRANCH=$(git symbolic-ref --short HEAD)
export BRANCH

read -p "Version number: " VERSION_NUMBER
read -p "SDCARD_FS [Y\N]: " SDCARD_FS
VERA="Dora"
VERSION="${VERA}-v${VERSION_NUMBER}"
if [ $SDCARD_FS = "Y" ] || [ $SDCARD_FS = "y" ]; then
  ZIPNAME="Dora-Kernel-v${VERSION_NUMBER}-sdcard_fs.zip"
else 
  ZIPNAME="Dora-Kernel-v${VERSION_NUMBER}.zip"
fi
export LOCALVERSION=$(echo "-${VERSION}")
export ZIPNAME 
export VERSION_NUMBER

#export defconfig
DEFCONFIG="dora_defconfig"
export DEFCONFIG
