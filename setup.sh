#!/bin/bash

#Create a folder where we will save everything
mkdir ${HOME}/kranel
cd ${HOME}/kranel || exit

#Compiler setup

#Proton Clang 12 by dragun
git clone https://github.com/kdrag0n/proton-clang.git --depth=1 proton-clang

# GCC11 
# git clone https://github.com/milouk/gcc-prebuilt-elf-toolchains gcc11

#AOSP Clang and AOSP GCC for cross compilation
# git clone https://android.googlesource.com/platform/prebuilts/clang/host/linux-x86 aosp-clang
# git clone https://android.googlesource.com/platform/prebuilts/gcc/linux-x86/aarch64/aarch64-linux-android-4.9 aosp-gcc64
# git clone https://android.googlesource.com/platform/prebuilts/gcc/linux-x86/arm/arm-linux-androideabi-4.9 aosp-gcc32

#AnyKernel setup
git clone https://github.com/nem0-z/AnyKernel3 -b guacamole --depth=1 anykernel3

#Karamel clone
git clone git@github.com:nem0-z/android_kernel_oneplus_sm8150.git

cd android_kernel_oneplus_sm8150 || cd .. || exit

echo "Ready to build bish!"



