#!/bin/bash
##############################################################################
# build chromium
#
# usage: build.sh --target=vs-sx7a|vs-sx7b|mtk-5581|mtk-5597|mtk2020
#                [--release-ver=<version>]
#                [--dev]
#                [--enable-debug]
#                [--rc]
#                [--clean]
#
#        If --release-ver is not specified, a development tarball is created
#
# This script assumes this directory structure:
#   <basedir>/ ........................ pre-exists
#   <basedir>/build/ .................. pre-exists, VS build scripts
#   <basedir>/conjure-build/ .......... pre-exists, conjure build scripts
#   <basedir>/src/ .................... pre-exists, chromium source
#   <basedir>/sx7_sdk/ ................ pre-exists, VS SDK
#
#   <basedir>/out/chromium/ ........... created, Chromium build output
#   <basedir>/install/dev/ ............ created, dev image files
#   <basedir>/install/img/ ............ created, install image files
#   <basedir>/install/img/dragonfly/ .. created, VS .img files
#   <basedir>/install/img/leo/ ........ created, VS .img files
#   <basedir>/install/work/ ........... created, general workspace
#   <basedir>/install/work/chromium/ .. created, base installation files
#
##############################################################################

#-----------------------------------------------------------------------------
#
#-----------------------------------------------------------------------------

ME=$(basename $0)
MYDIR=$(realpath $(dirname $0))
TARGET=vs-sx7b
MAKE_CLEAN=0
ENABLE_CHROMIUM_DEBUG=0
IS_DEV_BUILD=0
IS_RC_BUILD=0

#COMMENT START
#
CHROMIUM_FILES="
cast_shell
chrome_sandbox
icudtl.dat
libfairplay_cdm_base.so
natives_blob.bin
snapshot_blob.bin
"
#

#
CHROMIUM_PAK_DIRS="
assets
chromecast_locales
"
#

#
EXTRA_FILES="
libuuid.so.1
libcxxrt.so.1
"
#

#
VENDOR_FILES_UNUSED="
"
#
#COMENT END

#-----------------------------------------------------------------------------
# functions
#-----------------------------------------------------------------------------

usage()
{
  rc=$1
  echo "RAMYA IAM in usage() and value of rc = " $1
  shift
  msg="$*"
  echo "RAMYA IAM in usage() and value of msg = " $msg
  test -n "$msg" && echo $msg && echo
  echo "usage: $ME --target=vs-sx7a|vs-sx7b|mtk-5581|mtk-5597|mtk2020 [--release-ver=<version>] [--dev] [--clean]
"
  exit $rc
}


die()
{
  echo "RAMYA I am in die()"	
  rc=$1
  shift
  msg="$*"
  test -n "$msg" && echo "!! $msg" && echo
  exit $rc
}

set_target()
{
  target=$1
  case $target in
    vs-sx7a|VS-SX7A)   TARGET=vs-sx7a ; incl=build-vs.incl      ;;
    vs-sx7b|VS-SX7B)   TARGET=vs-sx7b ; incl=build-vs.incl      ;;
    mtk-5581|MTK-5581) TARGET=mtk-5581; incl=build-mtk.incl     ;;
    mtk-5597|MTK-5597) TARGET=mtk-5597; incl=build-mtk.incl     ;;
    mtk2020|MTK2020)   TARGET=mtk2020 ; incl=build-mtk2020.incl ;;
    *) usage 2 "Error: unsupported target: '$1'" ;;
  esac
}

set_release_ver()
{
  RELEASE_VER=$1
  echo "RAMYA I am in set_release_ver value of RELEASE_VER= " $RELEASE_VER

}

set_symdir()
{
  SYMDIR=$1
}

parse_arguments()
{
  for arg in $*
  do
    case $arg in
      --target=*)      set_target `echo $arg | awk -F = '{print $2}'` ;;
      --release-ver=*) set_release_ver `echo $arg | awk -F = '{print $2}'` ;;
      --symdir=*)      set_symdir `echo $arg | awk -F = '{print $2}'` ;;
      --enable-debug)  ENABLE_CHROMIUM_DEBUG=1 ;;
      --dev)           IS_DEV_BUILD=1 ;;
      --rc)            IS_RC_BUILD=1 ;;
      --clean)         MAKE_CLEAN=1 ;;
      --help)          usage 0 ;;
      *)               usage 1 "Error: unsupported flag: '$arg'" ;;
    esac
  done
}

banner()
{
  echo "
==============================================================================
 $*
==============================================================================
"
}

show_settings()
{
  case "$TARGET" in
    "mtk-5581") target="MediaTek 5581" ;;
    "mtk-5597") target="MediaTek 5597" ;;
    "mtk2020")  target="MediaTek 2020" ;;
    "vs-sx7a")  target="V-Silicon SX7A" ;;
    "vs-sx7b")  target="V-Silicon SX7B" ;;
    *)          target="Unknown" ;;
  esac

  release="development tarball"
  test -n "$RELEASE_VER" && release="installable image version $RELEASE_VER"

if false; then
  banner "Building $target $release
#`show_build_base` "
fi
}

show_chromium_version()
{
  cd $CHROMIUM_ROOT/chrome
  maj=`grep MAJOR VERSION | awk -F = '{print $2}'`
  min=`grep MINOR VERSION | awk -F = '{print $2}'`
  bld=`grep BUILD VERSION | awk -F = '{print $2}'`
  patch=`grep PATCH VERSION | awk -F = '{print $2}'`
  echo "$maj.$min.$bld.$patch"
}

build_cast_shell()
{
  cd $CHROMIUM_ROOT
  gn gen $CHROMIUM_OUT_DIR --args="$GN_ARGS" || die 2
  ninja -C $CHROMIUM_OUT_DIR cast_shell || die 2
  ninja -C $CHROMIUM_OUT_DIR chrome_sandbox || die 2
  ninja -C $CHROMIUM_OUT_DIR dump_syms minidump-2-core minidump_stackwalk || die 2
}

make_clean()
{
  echo "RAMY im in make_clean()"
  echo "$NDK_OUT_DIR = " $NDK_OUT_DIR
  echo "$NDK_INSTALL_IMG_DIR " $NDK_INSTALL_IMG_DIR  
  #rm -rf $NDK_OUT_DIR/*
  rm -rf $NDK_INSTALL_IMG_DIR/*
}


#=============================================================================
# start of execution
#=============================================================================
parse_arguments $*

# set up platform-independent environment variables
NDK_BUILD_ROOT=$(realpath $(dirname $0))
echo "RAMYA NDK_BUILD_ROOT = " $NDK_BUILD_ROOT
NDK_ROOT=`realpath $NDK_BUILD_ROOT/..`
echo "RAMYA NDK_ROOT= " $NDK_ROOT
#NDK_EXTRAS_DIR=`realpath $CONJURE_BUILD_ROOT/extras`
#echo "RAMYA CONJURE_EXTRAS_DIR= " $CONJURE_EXTRAS_DIR
NDK_SO_ROOT=$NDK_ROOT/ndk-vsilicon/vendor/VS/artefacts/libs
echo "RAMYA NDK_SO_ROOT= " $NDK_SO_ROOT


#mkdir -p $NDK_ROOT/ndk_out/ndk
#NDK_OUT_DIR=$NDK_ROOT/ndk_out/ndk
#echo "RAMYA NDK_OUT_DIR= " $NDK_OUT_DIR 

mkdir -p $NDK_ROOT/ndk_install/work

NDK_IMG_WORKDIR=$NDK_ROOT/ndk_install/work
echo "RAMYA NDK_IMG_WORKDIR= " $NDK_IMG_WORKDIR

mkdir -p $NDK_ROOT/ndk_install/img

#Looks below not needed
NDK_INSTALL_IMG_DIR=$NDK_ROOT/ndk_install/img
echo "RAMYA NDK_INSTALL_IMG_DIR= "$NDK_INSTALL_IMG_DIR

mkdir -p $NDK_ROOT/ndk_install/dev
NDK_DEV_IMG_DIR=$NDK_ROOT/ndk_install/dev

echo "RAMYA CONJURE_DEV_IMG_DIR= " $NDK_DEV_IMG_DIR
#test -z "$SYMDIR" && SYMDIR=$CHROMIUM_OUT_DIR/../symbols

#STRIP_TOOL=$CHROMIUM_ROOT/third_party/eu-strip/bin/eu-strip

# set up platform-dependent environment variables & functions
source $NDK_BUILD_ROOT/$incl

show_settings
# echo "GN_ARGS='$GN_ARGS'"

#Check whether need to clean

if [ $MAKE_CLEAN -ne 0 ]; then
  banner "Cleaning up previous builds"
  make_clean
fi

if false; then
banner "Building cast_shell"
build_cast_shell
$MYDIR/gensyms.sh --target=$TARGET --symdir=$SYMDIR
fi

if [ -n "$RELEASE_VER" ]; then
  banner "Building installable image"
  # build_install_img sets $FINAL_IMG_FILE
  build_install_img $RELEASE_VER $NDK_INSTALL_IMG_DIR
  banner "Installable image:
$FINAL_IMG_FILE"

else
  banner "Building development tarball"
  build_dev_tarball $NDK_DEV_IMG_DIR
  banner "Development tarball:
`ls $RELEASE_VER $NDK_DEV_IMG_DIR/*tgz`"
fi
