#!/bin/bash
##############################################################################
# build ndk
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
#   <basedir>/ndk-build/ .......... pre-exists, conjure build scripts
#   <basedir>/ndk-vsilicon/vendor/VS/artefacts/libs/ .................... pre-exists,libshim_lib.so
#
#   <basedir>/ndk_out/ndk/ ........... created, ndk build output , currently not used as libshim_lib.so update in repo
#   <basedir>/ndk_install/dev/ ............ created, dev image files
#   <basedir>/ndk_install/img/ ............ created, install image files
#   <basedir>/ndk_install/img/dragonfly/ .. created, VS .img files
#   <basedir>/ndk_install/img/leo/ ........ created, VS .img files
#   <basedir>/ndk_install/work/ ........... created, general workspace
#   <basedir>/ndk_install/work/ndk/ .. created, base installation files
#
##############################################################################

#-----------------------------------------------------------------------------
#
#-----------------------------------------------------------------------------

ME=$(basename $0)
MYDIR=$(realpath $(dirname $0))
TARGET=vs-sx7b
MAKE_CLEAN=0
IS_DEV_BUILD=0
IS_RC_BUILD=0

VENDOR_FILES_UNUSED="
"
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

parse_arguments()
{
  for arg in $*
  do
    case $arg in
      --target=*)      set_target `echo $arg | awk -F = '{print $2}'` ;;
      --release-ver=*) set_release_ver `echo $arg | awk -F = '{print $2}'` ;;
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
  banner "Building $target $release"
fi
}

make_clean()
{
  echo "RAMY im in make_clean()"
  echo "$VIZIONDK_INSTALL_IMG_DIR " $VIZIONDK_INSTALL_IMG_DIR  
  rm -rf $VIZIONDK_INSTALL_IMG_DIR/*
}


#=============================================================================
# start of execution
#=============================================================================
parse_arguments $*

# set up platform-independent environment variables
VIZIONDK_BUILD_ROOT=$(realpath $(dirname $0))
echo "RAMYA VIZIONDK_BUILD_ROOT = " $VIZIONDK_BUILD_ROOT
VIZIONDK_ROOT=`realpath $VIZIONDK_BUILD_ROOT/..`
echo "RAMYA VIZIONDK_ROOT= " $VIZIONDK_ROOT
VIZIONDK_EXTRAS_DIR=`realpath $VIZIONDK_BUILD_ROOT/extras`
echo "RAMYA VIZIONDK_EXTRAS_DIR= " $VIZIONDK_EXTRAS_DIR
VIZIONDK_SO_ROOT=$VIZIONDK_ROOT/ndk-vsilicon/vendor/VS/artefacts/libs
echo "RAMYA VIZIONDK_SO_ROOT= " $VIZIONDK_SO_ROOT


#mkdir -p $VIZIONDK_ROOT/viziondk_out/ndk
#VIZIONDK_OUT_DIR=$VIZIONDK_ROOT/viziondk_out/ndk
#echo "RAMYA VIZIONDK_OUT_DIR= " $VIZIONDK_OUT_DIR 

mkdir -p $VIZIONDK_ROOT/viziondk_install/work
VIZIONDK_IMG_WORKDIR=$VIZIONDK_ROOT/viziondk_install/work
echo "RAMYA VIZIONDK_IMG_WORKDIR= " $VIZIONDK_IMG_WORKDIR

mkdir -p $VIZIONDK_ROOT/viziondk_install/img
VIZIONDK_INSTALL_IMG_DIR=$VIZIONDK_ROOT/viziondk_install/img
echo "RAMYA VIZIONDK_INSTALL_IMG_DIR= "$VIZIONDK_INSTALL_IMG_DIR

mkdir -p $VIZIONDK_ROOT/viziondk_install/dev
VIZIONDK_DEV_IMG_DIR=$VIZIONDK_ROOT/viziondk_install/dev

echo "RAMYA VIZIONDK_DEV_IMG_DIR= " $VIZIONDK_DEV_IMG_DIR

# set up platform-dependent environment variables & functions
source $VIZIONDK_BUILD_ROOT/$incl

show_settings

if [ $MAKE_CLEAN -ne 0 ]; then
  banner "Cleaning up previous builds"
  make_clean
fi

if [ -n "$RELEASE_VER" ]; then
  banner "Building installable image"
  # build_install_img sets $FINAL_IMG_FILE
  build_install_img $RELEASE_VER $VIZIONDK_INSTALL_IMG_DIR
  banner "Installable image:
$FINAL_IMG_FILE"

else
  banner "Building development tarball"
  build_dev_tarball $VIZIONDK_DEV_IMG_DIR
  banner "Development tarball:
`ls $RELEASE_VER $VIZIONDK_DEV_IMG_DIR/*tgz`"
fi
