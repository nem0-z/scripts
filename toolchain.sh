#!/bin/bash
CURRENT_DATE=$(date +"%Y%m%d")
TC_DIR=/home/zlatan/kranelstuff/dora-clang

cd ${TC_DIR} || exit 1
cd ../tc-build || exit 1

# Build LLVM
./build-llvm.py \
  --lto thin \
  -t "ARM;AArch64;X86" \
  --clang-vendor "Dora" \
  --projects "clang;compiler-rt;lld;polly" \
  --incremental

# Check if the final clang binary exists or not.
[ ! -f install/bin/clang-1* ] && {
  echo "LLVM not built!"
	exit 1
}

# Build binutils
./build-binutils.py --targets arm aarch64

# Strip remaining products
for f in $(find install -type f -exec file {} \; | grep 'not stripped' | awk '{print $1}'); do
	strip -s "${f: : -1}"
done

# Move to git repo and commit
cd install
rm -r ${TC_DIR}/aarch64-linux-gnu ${TC_DIR}/arm-linux-gnueabi
cp -r LICENSE aarch64-linux-gnu arm-linux-gnueabi bin include lib share ${TC_DIR}
cd ${TC_DIR}
git add --all && git commit -sm "Update to ${CURRENT_DATE} build" && git push

