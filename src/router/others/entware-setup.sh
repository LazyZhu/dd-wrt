#!/bin/sh

BOLD="\033[1m"
NORM="\033[0m"
INFO="$BOLD Info: $NORM"
ERROR="$BOLD *** Error: $NORM"
WARNING="$BOLD * Warning: $NORM"
INPUT="$BOLD => $NORM"

i=1 # Will count available partitions (+ 1)
cd /tmp

echo -e $INFO This script will guide you through the Entware installation.
echo -e $INFO Script modifies only \"entware\" folder on the chosen drive,
echo -e $INFO no other data will be touched. Existing installation will be
echo -e $INFO replaced with this one. Also some start scripts will be installed,
echo -e $INFO the old ones will be saved to .\entware\jffs_scripts_backup.tgz
echo 

# if [ ! -d /jffs/etc/config ] # can not exist
if ! /bin/mount | grep 'jffs' > /dev/null;
then
  echo -e "$ERROR Please enable JFFS partition from web UI, reboot router and"
  echo -e "$ERROR try again.  Exiting..."
  exit 1
fi

echo -e $INFO Looking for available  partitions...
for mounted in `/bin/mount | grep -E 'ext2|ext3|ext4|jffs2' | cut -d" " -f3`
do
  isPartitionFound="true"
  echo "[$i] -->" $mounted
  eval mounts$i=$mounted
  i=`expr $i + 1`
done

if [ $i == "1" ]
then
  echo -e "$ERROR No ext2/ext3/jffs partition available. Exiting..."
  exit 1
fi

echo -en "$INPUT Please enter partition number or 0 to exit\n$BOLD[0-`expr $i - 1`]$NORM: "
read partitionNumber
if [ "$partitionNumber" == "0" ]
then
  echo -e $INFO Exiting...
  exit 0
fi

if [ "$partitionNumber" -gt `expr $i - 1` ]                                                           
then                                                                                       
  echo -e "$ERROR Invalid partition number!  Exiting..."                                                                 
  exit 1                                                                                   
fi

eval entPartition=\$mounts$partitionNumber
echo -e "$INFO $entPartition selected.\n"
entFolder=$entPartition/entware

if [ -d $entFolder ]
then
  echo -e "$WARNING Found previous installation, deleting..."
  rm -fr $entFolder
fi
echo -e $INFO Creating $entFolder folder...
mkdir $entFolder

if mount | grep 'opt' > /dev/null;
then
  echo -e "$WARNING Deleting old /opt mount..."
  umount /opt
  sleep 1
fi
echo -e $INFO Binding $entFolder to /opt...
  mount -o bind $entFolder /opt

echo -e $INFO Creating /jffs scripts backup...
tar -czf $entPartition/jffs_scripts_backup.tgz /jffs/etc/config/* >/dev/null

echo -e "$INFO Modifying start scripts..."
# can not exist after format
mkdir -p /jffs/etc
mkdir -p /jffs/etc/config
cat > /jffs/etc/config/entware.startup << EOF
#!/bin/sh
#
# STARTUP
#

# Mount EntWARE from jffs if exist
if [ -d /jffs/entware ]; then
    if ! cat /proc/mounts | grep opt > /dev/null; then 
	logger -s -p local0.notice -t entware.startup "Mount EntWARE from jffs"
	mount -o bind /jffs/entware /opt
    fi
fi
sleep 1
# Start ALL EntWARE services
logger -s -p local0.notice -t entware.startup "Start EntWARE services"
/opt/etc/init.d/rc.unslung start
EOF
chmod +x /jffs/etc/config/entware.startup

cat > /jffs/etc/config/entware.shutdown << EOF
#!/bin/sh
#
# SHUTDOWN
#

# Stop ALL EntWARE services
logger -s -p local0.notice -t entware.shutdown "Shutdown EntWARE services"
/opt/etc/init.d/rc.unslung stop
EOF
chmod +x /jffs/etc/config/entware.shutdown

cat > /jffs/etc/config/post-mount << EOF
#!/bin/sh
#
# POST-MOUNT
#
logger -s -p local0.notice -t post-mount "### Looking for available EntWARE partitions..."
for mounted in `/bin/mount | grep -E 'ext2|ext3|ext4' | cut -d" " -f3`
do
   if [ -d $mounted/entware ]; then
        logger -s -p local0.notice -t post-mount "### found EntWARE on $mounted, bind to /opt and start services"
        # check if already mounted
        if ! cat /proc/mounts | grep opt > /dev/null; then
            mount -o bind $mounted/entware /opt
            sleep 3
            /opt/etc/init.d/rc.unslung start                                     
        else
            logger -s -p local0.notice -t post-mount "### /opt already mounted!"
        fi
   fi
done
EOF
#eval sed -i 's,__Partition__,$entPartition,g' /jffs/etc/config/post-mount
chmod +x /jffs/etc/config/post-mount
# announce mount script to dd-wrt
/usr/sbin/nvram set usb_runonmount=/jffs/etc/config/post-mount

echo -e "$INFO Starting Entware deployment....\n"
wget http://qnapware.zyxmon.org/binaries-armv7/installer/entware_install_arm.sh
sh ./entware_install_arm.sh
sync

