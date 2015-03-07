#!/bin/sh
### #########################################
### This must be properly setup on build host
### #########################################
DEVDIR=/home/dd-wrt/dd-wrt
GCCARM=/home/dd-wrt/toolchains/toolchain-arm_cortex-a9_gcc-4.8-linaro_musl-1.1.5_eabi/bin
REVISION="26424M"
export PATH=$GCCARM:$PATH
export ARCH=arm

### update sources
cd $DEVDIR
# git pull
REVISION=`git log --grep git-svn-id -n 1|grep -i dd-wrt|awk '{print $2}'|awk -F'@' '{print $2}'`
EXTENDNO="-"`git rev-parse --verify HEAD --short`"-GIT"

### ###################
### setup target router
### ###################
cp -f $DEVDIR/src/router/configs/northstar/.config_ws880_mini $DEVDIR/src/router/.config
# cp -f $DEVDIR/src/router/configs/northstar/.config_ws880 $DEVDIR/src/router/.config

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

### compile webcomp ###
#cd $DEVDIR/tools/
#rm ./strip
#gcc strip.c -o ./strip
#rm ./write3
#gcc write3.c -o ./write3
#rm ./write4
#gcc write4.c -o ./write4
#rm ./webcomp
#gcc -o webcomp -DUEMF -DWEBS -DLINUX webcomp.c

#echo ................................................................
#echo fixing alconf's
#echo ................................................................
#cd $DEVDIR/src/router/zlib
#aclocal
#cd $DEVDIR/src/router/jansson
#aclocal
#automake --add-missing
#cd $DEVDIR/src/router/daq
#aclocal
#automake --add-missing
#cd $DEVDIR/src/router/pptpd
#aclocal
#automake --add-missing
#cd $DEVDIR/src/router/igmp-proxy
#aclocal
#automake --add-missing
#cd $DEVDIR/src/router/nocat
#aclocal
#cd $DEVDIR/src/router/minidlna
#aclocal
#cd $DEVDIR/src/router/libnfnetlink
#aclocal
#cd $DEVDIR/src/router/libnetfilter_queue
#aclocal
#cd $DEVDIR/src/router/zabbix
#aclocal
#cd $DEVDIR/src/router/openvpn
#aclocal
#autoconf

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
# make -f Makefile.northstar glib20-configure # for nocat
# make -f Makefile.northstar pptpd-configure # for ipeth
# make -f Makefile.northstar openssl-configure # for ipeth
# make -f Makefile.northstar openssl # for ipeth

mkdir -p $DEVDIR/logs
echo ""
echo "************************************"
echo "* Configure Northstar targets..."
echo "************************************"
echo ""
(make -f Makefile.northstar configure | tee $DEVDIR/logs/`date "+%Y.%m.%d-%H.%M"`-stdoutconf.log) 3>&1 1>&2 2>&3 | tee $DEVDIR/logs/`date "+%Y.%m.%d-%H.%M"`-stderrconf.log 
echo ""
echo "************************************"
echo "* Make Northstar targets..."
echo "************************************"
echo ""
# make -f Makefile.northstar install_headers
make -f Makefile.northstar kernel # must be buided first, or opendpi won't compile
make -f Makefile.northstar clean all install 2>&1 | tee $DEVDIR/logs/`date "+%Y.%m.%d-%H.%M"`-stdoutbuild.log
#make -f Makefile.northstar all install 2>&1 | tee $DEVDIR/logs/`date "+%Y.%m.%d-%H.%M"`-stdoutbuild.log

if [ -e arm-uclibc/huawei_ws880-firmware.trx ]
then
   STAMP="`date +%Y-%m-%d_%H:%M`"
   mkdir -p ../../image
   cp arm-uclibc/huawei_ws880-firmware.trx ../../image/dd-wrt.v24-K3_Huawei_WS880_"$STAMP"_r"$REVISION$EXTENDNO".trx
   echo ""
   echo ""
   echo "Image created: dd-wrt.v24-K3_Huawei_WS880_"$STAMP"_r"$REVISION$EXTENDNO".trx"
   echo "Have a look in the \"image\" directory"
else
   echo ""
   echo ""
   echo "Whoops.. something went wrong, please check the logs output and consult the forums.."
fi 

cd $DEVDIR
