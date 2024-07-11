#!/bin/bash

set -e
set -x

BASE=`pwd`
SRC=$BASE/src
PATCHES=$BASE/patches
RPATH=$PREFIX/lib
DEST=$BASE$PREFIX
LDFLAGS="-L$DEST/lib -s -Wl,--dynamic-linker=$PREFIX/lib/ld-musl-x86_64.so.1 -Wl,-rpath,$RPATH -Wl,-rpath-link,$DEST/lib"
CPPFLAGS="-I$DEST/include"
CFLAGS="-march=x86-64-v2"
CXXFLAGS=$CFLAGS
CONFIGURE="./configure --prefix=$PREFIX --host=x86_64-tomatoware-linux-musl"
MAKE="make -j`nproc`"
export CCACHE_DIR=$HOME/.ccache_rust

########### #################################################################
# OPENSSL # #################################################################
########### #################################################################

OPENSSL_VERSION=3.3.1

cd $SRC/openssl

if [ ! -f .extracted ]; then
	rm -rf openssl openssl-${OPENSSL_VERSION}
	tar zxvf openssl-${OPENSSL_VERSION}.tar.gz
	mv openssl-${OPENSSL_VERSION} openssl
	touch .extracted
fi

cd openssl

if [ ! -f .configured ]; then
	./Configure linux-x86_64 \
	$LDFLAGS $CFLAGS \
	--prefix=$PREFIX
	touch .configured
fi

if [ ! -f .built ]; then
	make \
	CC=x86_64-tomatoware-linux-musl-gcc
	AR=x86_64-tomatoware-linux-musl-ar
	RANLIB=x86_64-tomatoware-linux-musl-ranlib
	touch .built
fi

if [ ! -f .installed ]; then
	make \
	install \
	CC=x86_64-tomatoware-linux-musl-gcc \
	AR=x86_64-tomatoware-linux-musl-ar \
	RANLIB=x86_64-tomatoware-linux-musl-ranlib \
	INSTALLTOP=$DEST \
	OPENSSLDIR=$DEST/ssl
	touch .installed
fi

######## ####################################################################
# RUST # ####################################################################
######## ####################################################################

RUST_VERSION=1.79.0
RUST_VERSION_REV=1

cd $SRC/rust

if [ ! -f .cloned ]; then
	git clone https://github.com/rust-lang/rust.git
	touch .cloned
fi

cd rust

if [ ! -f .configured ]; then
	git checkout $RUST_VERSION
	cp ../config.toml .
	touch .configured
fi

#if [ ! -f .patched ]; then
#	./x.py
#	./build/x86_64-unknown-linux-gnu/stage0/bin/cargo update -p libc
#	touch .patched
#fi

if [ ! -f .installed ]; then

	CARGO_TARGET_X86_64_UNKNOWN_LINUX_MUSL_RUSTFLAGS='-Ctarget-feature=-crt-static -Cstrip=symbols -Clink-arg=-Wl,--dynamic-linker=/mmc/lib/ld-musl-x86_64.so.1 -Clink-arg=-Wl,-rpath,/mmc/lib' \
	CFLAGS_x86_64_unknown_linux_musl="-march=x86-64-v2" \
	CXXFLAGS_x86_64_unknown_linux_musl="-march=x86-64-v2" \
	x86_64_UNKNOWN_LINUX_MUSL_OPENSSL_LIB_DIR=$DEST/lib \
	x86_64_UNKNOWN_LINUX_MUSL_OPENSSL_INCLUDE_DIR=$DEST/include \
	x86_64_UNKNOWN_LINUX_MUSL_OPENSSL_NO_VENDOR=1 \
	x86_64_UNKNOWN_LINUX_MUSL_OPENSSL_STATIC=1 \
	DESTDIR=$BASE/x86_64-unknown-linux-musl \
	./x.py install
	touch .installed
fi

cd $BASE

if [ ! -f .prepped ]; then
	mkdir -p $BASE/x86_64-unknown-linux-musl/DEBIAN
	cp $SRC/rust/control $BASE/x86_64-unknown-linux-musl/DEBIAN
	sed -i 's,version,'"$RUST_VERSION"'-'"$RUST_VERSION_REV"',g' \
		$BASE/x86_64-unknown-linux-musl/DEBIAN/control
	touch .prepped
fi

if [ ! -f .packaged ]; then
	dpkg-deb --build x86_64-unknown-linux-musl
	dpkg-name x86_64-unknown-linux-musl.deb
	touch .packaged
fi
