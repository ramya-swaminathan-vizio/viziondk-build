#!/bin/sh

cd "${0%/*}"

#mkdir -p locales

chown conjure:system * 


chmod 777 .
chmod 644 VERSION
chmod 755 post-install.sh
chmod 666 libshim_lib.so 

