#!/bin/sh

BOLD="\033[1m"
NORM="\033[0m"
INFO="$BOLD Info: $NORM"
ERROR="$BOLD *** Error: $NORM"
WARNING="$BOLD * Warning: $NORM"
INPUT="$BOLD => $NORM"

i=1 # Will count available partitions (+ 1)
cd /tmp

echo -e $INFO This script will guide you through the Entware-ng installation.
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
  echo -e "$ERROR No ext2/ext3/ext4/jffs partition available. Exiting..."
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
  echo -e "$WARNING Found previous installation, moving..."
  mv $entFolder $entFolder-old_`date +\%F_\%H-\%M`
fi
echo -e $INFO Creating $entFolder folder...
mkdir $entFolder

if mount | grep 'opt' > /dev/null;
then
  echo -e "$WARNING /opt already mounted! unmount..."
  /opt/etc/init.d/rc.unslung stop 2>/dev/null
  sleep 1
  umount /opt
fi
echo -e $INFO Binding $entFolder to /opt...
  mount -o bind $entFolder /opt

echo -e $INFO Creating /jffs scripts backup...
tar -czf $entPartition/jffs_scripts_backup_`date +\%F_\%H-\%M`.tgz /jffs/etc/config/* >/dev/null

echo -e "$INFO Modifying start scripts..."
# can not exist after format jffs
mkdir -p /jffs/etc
mkdir -p /jffs/etc/config
# gids check install
cat > /jffs/etc/config/S01-gids-check.startup << EOF
#!/bin/sh
while : ; do
        # ShairPort
        # If the audio group doesn't exist, add it (needed to alsalib read /opt/etc/asound.conf):
        if ! grep "^audio:" /etc/group 1>/dev/null 2>&1; then
                echo "audio:x:29:root,nobody" >>/etc/group 2>/dev/null
        fi

        # Avahi / D-BUS
        # If the netdev group doesn't exist, add it (exist in avahi-dbus.conf):
        if ! grep "^netdev:" /etc/group 1>/dev/null 2>&1; then
                echo "netdev:x:85:root,nobody" >>/etc/group 2>/dev/null
        fi

        # If the nogroup group doesn't exist, add it:
        if ! grep "^nogroup:" /etc/group 1>/dev/null 2>&1; then
                echo "nogroup:x:65534:" >>/etc/group 2>/dev/null
        fi

        # check interval 1m
        sleep 60
done&
EOF
chmod +x /jffs/etc/config/S01-gids-check.startup
# entware startup install
cat > /jffs/etc/config/S11-entware.startup << EOF
#!/bin/sh

#
# EntWARE STARTUP
#

# Mount EntWARE from jffs if exist
if [ -d /jffs/entware ]; then
    if ! cat /proc/mounts | grep opt > /dev/null; then
	logger -s -p local0.notice -t entware.startup "### mount EntWARE from jffs partition"
	mount -o bind /jffs/entware /opt
	sleep 1
	# Start ALL EntWARE services
	logger -s -p local0.notice -t entware.startup "### start EntWARE services [JFFS]"
	/opt/etc/init.d/rc.unslung start
    fi
fi
EOF
chmod +x /jffs/etc/config/S11-entware.startup
# post-mount install
cat > /jffs/etc/config/post-mount << EOF
#!/bin/sh

#
# POST-MOUNT
#

# HFS+ R/W support
logger -s -p local0.notice -t post-mount "### checking filesystems..."
for mountdev in \`/bin/mount | grep -E 'hfsplus' | grep ro | cut -d" " -f1\`
do
        logger -s -p local0.notice -t post-mount "### checking hfsplus at \$mountdev..."
        fsck_hfs -py \$mountdev
        logger -s -p local0.notice -t post-mount "### remount hfsplus r/w..."
        mount -o remount,rw,force \$mountdev
        # make it world writable
        chmod 777 \`/bin/mount | grep \$mountdev | cut -d" " -f3\`
done

# Search EntWARE on USB disks
logger -s -p local0.notice -t post-mount "### looking for available EntWARE partitions..."
for mountpath in \`/bin/mount | grep -E 'ext2|ext3|ext4' | cut -d" " -f3\`
do
   if [ -d \$mountpath/entware ]; then
        logger -s -p local0.notice -t post-mount "### found EntWARE on \$mountpath, bind it to /opt and start services"
        # check if already mounted
        if ! cat /proc/mounts | grep opt > /dev/null; then
            mount -o bind \$mountpath/entware /opt
            sleep 1
	    # Start ALL EntWARE services
	    logger -s -p local0.notice -t post-mount "### start EntWARE services [USB]"
            /opt/etc/init.d/rc.unslung start
        else
            logger -s -p local0.notice -t post-mount "### /opt already mounted! skip EntWARE setup"
        fi
   fi
done
EOF
chmod +x /jffs/etc/config/post-mount
# announce post-mount script to dd-wrt
/usr/sbin/nvram set usb_runonmount=/jffs/etc/config/post-mount
# mount disks with label path
/usr/sbin/nvram set usb_mntbylabel=1
# store changes permanently
/usr/sbin/nvram commit

echo -e "$INFO Starting Entware-ng deployment....\n"
wget http://entware.zyxmon.org/binaries/armv7/installer/entware_install.sh
sh ./entware_install.sh
sync

