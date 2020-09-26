#!/bin/bash

# Tell env that this is a standalone build
IS_KERNEL_STANDALONE=y
export IS_KERNEL_STANDALONE

# Compiler
export COMPILER="clang"

# Export custom User and Host
KBUILD_BUILD_USER=nem0
KBUILD_BUILD_HOST=T460s
export KBUILD_BUILD_USER KBUILD_BUILD_HOST

PROJECT_DIR=/home/zlatan/karamel
PROJECT_DIRECTORY=/home/zlatan/karamel/android_kernel_oneplus_sm8150
export PROJECT_DIR PROJECT_DIRECTORY

cd ${PROJECT_DIRECTORY} || exit

# AnyKernel3
ANYKERNEL_DIR="${PROJECT_DIR}/anykernel3"
export ANYKERNEL_DIR

if [[ ${COMPILER} == *"GCC"* ]]; then
	CROSS_COMPILE="${PROJECT_DIR}/gcc/bin/aarch64-elf-"
	CROSS_COMPILE_ARM32="${PROJECT_DIR}/gcc32/bin/arm-eabi-"
else
  #proton
	CLANG_PATH=${PROJECT_DIR}/proton-clang
  
  #aosp
	# CLANG_PATH=${PROJECT_DIR}/aosp-clang
  # GCC_PATH=${PROJECT_DIR}/aosp-gcc
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
VERA="nem0"
VERSION="${VERA}-${BRANCH}-v${VERSION_NUMBER}"
ZIPNAME="${BRANCH}-v${VERSION_NUMBER}.zip"
export LOCALVERSION=$(echo "-${VERSION}")
export ZIPNAME 
export VERSION_NUMBER

#export defconfig
DEFCONFIG="nem0_defconfig"
export DEFCONFIG
