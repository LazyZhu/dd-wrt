#!/bin/sh
### #########################################
### This must be properly setup on build host
### #########################################
DEVDIR=/home/dd-wrt/dd-wrt
GCCARM=/home/dd-wrt/toolchains/toolchain-arm_cortex-a9_gcc-4.8-linaro_musl-1.1.5_eabi/bin
REVISION="28000M" # redefined, just default value
KERNELVERSION="3.10" # 3.10 stable, 3.18 experimental
export PATH=$GCCARM:$PATH
export ARCH=arm

### #########################################
### install missing packages for Ubuntu 14.04
### #########################################
# sudo apt-get install build-essential gcc g++ gengetopt binutils cmake bzip2 flex bison make automake automake1.9 automake1.11 autoconf gettext texinfo unzip sharutils subversion libncurses5-dev zlib1g-dev libglib2.0-dev patch pkg-config rsync libtool sed wget
# sudo apt-get install lib32stdc++6 # for lzma_4k on 64bit systems

### update sources
cd $DEVDIR
# git pull
REVISION=`git log --grep git-svn-id -n 1|grep -i dd-wrt|awk '{print $2}'|awk -F'@' '{print $2}'`
EXTENDNO="-"`git rev-parse --verify HEAD --short|cut -c 1-4`"-GIT"

### ###################
### setup target router
### ###################
# MINI (~10MB firmware) - try to build with that config it first!
# cp -f $DEVDIR/src/router/configs/northstar/.config_ws880_mini $DEVDIR/src/router/.config
# 16M (~16MB firmware)
# cp -f $DEVDIR/src/router/configs/northstar/.config_ws880_16m $DEVDIR/src/router/.config
# STD (~30MB firmware)
cp -f $DEVDIR/src/router/configs/northstar/.config_ws880 $DEVDIR/src/router/.config
# R1D (14.3MB MAX)
# cp -f $DEVDIR/src/router/configs/northstar/.config_xiaomi_r1d $DEVDIR/src/router/.config
echo "CONFIG_BUILD_HUAWEI=y" >> $DEVDIR/src/router/.config
echo "CONFIG_USB_AUDIO=y" >> $DEVDIR/src/router/.config
echo "CONFIG_PPTP_PLUGIN=y" >> $DEVDIR/src/router/.config
if [ $KERNELVERSION = "3.18" ]; then
sed -i 's/KERNELVERSION=3.10/KERNELVERSION=3.18/g' $DEVDIR/src/router/.config
fi
# Make fw for other brands too
# (uncomment desired and check src/router/Makefile.northstar)
#echo "CONFIG_BUILD_XIAOMI=y" >> $DEVDIR/src/router/.config
#echo "CONFIG_BUILD_TPLINK=y" >> $DEVDIR/src/router/.config
#echo "CONFIG_BUILD_DLINK=y" >> $DEVDIR/src/router/.config
#echo "CONFIG_BUILD_ASUS=y" >> $DEVDIR/src/router/.config
#echo "CONFIG_BUILD_BUFFALO=y" >> $DEVDIR/src/router/.config
#echo "CONFIG_BUILD_NETGEAR=y" >> $DEVDIR/src/router/.config
#echo "CONFIG_BUILD_TRENDNET=y" >> $DEVDIR/src/router/.config

# !!! TEMP need to fix
echo "NO_PROCESSLANGFILES=y" >> $DEVDIR/src/router/.config

cd $DEVDIR/src/router/libutils
echo -n '#define SVN_REVISION "' > revision.h
# svnversion -n . >> revision.h
echo -n $REVISION >> revision.h
echo -n $EXTENDNO >> revision.h
echo '"' >> revision.h

cd $DEVDIR/src/router/httpd/visuals
echo -n '#define SVN_REVISION "' > revision.h
# svnversion -n . >> revision.h
echo -n $REVISION >> revision.h
echo -n $EXTENDNO >> revision.h
echo '"' >> revision.h

cd $DEVDIR/src/router/httpd
echo -n '#define SVN_REVISION "' > revision.h
# svnversion -n . >> revision.h
echo -n $REVISION >> revision.h
echo -n $EXTENDNO >> revision.h
echo '"' >> revision.h

### #################################################################
### compile them once to make sure these binaries work on your distro,
### then comment them as i did
### ###

### compile trx ###
#cd $DEVDIR/opt/tools/
#gcc -o trx trx.c
#gcc -o trx_asus trx_asus.c

### compile jsformat ###
#cd $DEVDIR/src/router/tools
#rm jsformat
#make jsformat

### compile webcomp tools ###
cd $DEVDIR/tools/
rm ./process_langfile
gcc process_langfile.c -o ./process_langfile
rm ./process_nvramconfigfile
gcc process_nvramconfigfile.c -o ./process_nvramconfigfile
rm ./removewhitespace
gcc removewhitespace.c -o ./removewhitespace
rm ./strip
gcc strip.c -o ./strip
rm ./write3
gcc write3.c -o ./write3
rm ./write4
gcc write4.c -o ./write4
rm ./webcomp
gcc -o webcomp -DUEMF -DWEBS -DLINUX webcomp.c

echo ""
echo "************************************"
echo "*"
echo "* Fix all configs for local build  "
echo "*"
echo "************************************"
echo ""
### #########################################
### * comment this section after 1st run
### * some fixes doesn't needed at all...
### ###
#cd $DEVDIR/src/router/zlib
#aclocal

#cd $DEVDIR/src/router/jansson
#aclocal

### glib2.0/gettext automake version build error fix (moved to rules/*.mk)
### it still needs aclocal-1.13, link it in case yourth newer
#sudo ln -s /usr/bin/automake /usr/bin/automake-1.13
#sudo ln -s /usr/bin/aclocal /usr/bin/aclocal-1.13

### comgt compile fix
#cd $DEVDIR/src/router/usb_modeswitch/libusb-compat
#aclocal
#autoreconf -ivf

#cd $DEVDIR/src/router/pptpd
#aclocal

#cd $DEVDIR/src/router/igmp-proxy
#aclocal

#cd $DEVDIR/src/router/nocat
#aclocal

### for snort (moved to rules/*.mk)
#cd $DEVDIR/src/router/libnfnetlink
#aclocal
#autoreconf -ivf
#cd $DEVDIR/src/router/libnetfilter_queue
#aclocal
#autoreconf -ivf
#cd $DEVDIR/src/router/daq
#aclocal
#autoconf
#automake --add-missing
#autoreconf -ivf

#cd $DEVDIR/src/router/zabbix
#aclocal

#cd $DEVDIR/src/router/openvpn
#aclocal
#autoconf
### #########################################

cd $DEVDIR/src/router
echo ""
echo "************************************"
echo "* Essentials..."
echo "************************************"
echo ""
make -f Makefile.northstar zlib-configure
make -f Makefile.northstar jansson-configure
make -f Makefile.northstar zlib
make -f Makefile.northstar jansson
make -f Makefile.northstar nvram
make -f Makefile.northstar shared
make -f Makefile.northstar utils
make -f Makefile.northstar libutils # for dhcpv6 linking (radvd)
# make -f Makefile.northstar glib20-configure # for nocat linking

mkdir -p $DEVDIR/logs
echo ""
echo "************************************"
echo "* Configure Northstar targets..."
echo "* doesn't need to run on every build"
echo "* comment if build with same config"
echo "************************************"
echo ""
#(make -f Makefile.northstar configure | tee $DEVDIR/logs/`date "+%Y.%m.%d-%H.%M"`-stdoutconf.log) 3>&1 1>&2 2>&3 | tee $DEVDIR/logs/`date "+%Y.%m.%d-%H.%M"`-stderrconf.log 
echo ""
echo "************************************"
echo "* Make Northstar targets..."
echo "************************************"
echo ""
# make -f Makefile.northstar install_headers
make -f Makefile.northstar kernel # must be builded first, or opendpi won't compile
make -f Makefile.northstar clean all install 2>&1 | tee $DEVDIR/logs/`date "+%Y.%m.%d-%H.%M"`-stdoutbuild.log
# make -f Makefile.northstar all install 2>&1 | tee $DEVDIR/logs/`date "+%Y.%m.%d-%H.%M"`-stdoutbuild.log

# copy firmware to image dir
if [ -e arm-uclibc/xiaomi-r1d-firmware.bin ]
then
   STAMP="`date +%Y-%m-%d_%H:%M`"
   mkdir -p ../../image
   cp arm-uclibc/xiaomi-r1d-firmware.bin ../../image/dd-wrt.v3-K"$KERNELVERSION"_Xiaomi_R1D_"$STAMP"_r"$REVISION$EXTENDNO".bin
   echo ""
   echo ""
   echo "Image created: image/dd-wrt.v3-K"$KERNELVERSION"_Xiaomi_R1D_"$STAMP"_r"$REVISION$EXTENDNO".bin"
fi

# copy firmware to image dir
if [ -e arm-uclibc/huawei-ws880-firmware.trx ]
then
   STAMP="`date +%Y-%m-%d_%H:%M`"
   mkdir -p ../../image
   cp arm-uclibc/huawei-ws880-firmware.trx ../../image/dd-wrt.v3-K"$KERNELVERSION"_Huawei_WS880_"$STAMP"_r"$REVISION$EXTENDNO".trx
   echo ""
   echo ""
   echo "Image created: dd-wrt.v3-K"$KERNELVERSION"_Huawei_WS880_"$STAMP"_r"$REVISION$EXTENDNO".trx"
fi

   echo "DONE"
   echo ""
   echo "Have a look in the \"image\" directory"
   echo "and src/router/arm-uclibc directory"

cd $DEVDIR
