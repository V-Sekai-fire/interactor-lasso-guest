#!/usr/bin/env bash
# RISCV64_SYSROOT=<repository-riscv64-sysroot> [GUEST_RUNTIME_ROOT=<contract-guest-runtime>] [PRECISION=single|double] ./build.sh
set -euo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SYSROOT="${RISCV64_SYSROOT:?set RISCV64_SYSROOT to the riscv64 sysroot (toolchain.cmake inside)}"
PRECISION="${PRECISION:-single}"
case "$PRECISION" in
	single) DOUBLE=OFF ;;
	double) DOUBLE=ON ;;
	*) echo "error: PRECISION must be single or double, not $PRECISION" >&2; exit 1 ;;
esac
BUILD="${BUILD_DIR:-$HERE/build-$PRECISION}"

if [ ! -f "$SYSROOT/toolchain.cmake" ]; then
	echo "error: no toolchain.cmake under RISCV64_SYSROOT=$SYSROOT" >&2
	exit 1
fi
if ! clang++ --print-targets 2>/dev/null | grep -qi riscv64; then
	echo "error: no clang++ with a riscv64 target on PATH" >&2
	exit 1
fi

if [ ! -f "$BUILD/build.ninja" ]; then
	cmake -S "$HERE" -B "$BUILD" -G Ninja \
		-DCMAKE_TOOLCHAIN_FILE="$SYSROOT/toolchain.cmake" \
		-DCMAKE_BUILD_TYPE=Release \
		${GUEST_RUNTIME_ROOT:+-DGUEST_RUNTIME_ROOT="$GUEST_RUNTIME_ROOT"} \
		-DSANDBOX_RISCV_EXT_V=OFF \
		-DDOUBLE_PRECISION="$DOUBLE"
fi
cmake --build "$BUILD" --target lasso -- -j "${BUILD_JOBS:-8}"
ls -la "$HERE/lasso.elf"
sha256sum "$HERE/lasso.elf"
