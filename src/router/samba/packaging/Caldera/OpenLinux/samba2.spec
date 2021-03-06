Summary: Samba SMB client and server
Name: samba
Version: 2.0.7
Release: 20000425
Copyright: GNU GPL version 2
Group: Server/Network
Source: ftp://samba.org/pub/samba/samba-2.0.7.tar.gz
Patch: makefile-path.patch
Patch1: smbw.patch
Packager: John H Terpstra [Samba-Team] <jht@samba.org>
BuildRoot: /var/tmp/samba

%Description
Samba provides an SMB server which can be used to provide
network services to SMB (sometimes called "Lan Manager")
clients, including various versions of MS Windows, OS/2,
and other Linux machines. Samba also provides some SMB
clients, which complement the built-in SMB filesystem
in Linux. Samba uses NetBIOS over TCP/IP (NetBT) protocols
and does NOT need NetBEUI (Microsoft Raw NetBIOS frame)
protocol.

Samba-2 features an almost working NT Domain Control
capability and includes the new SWAT (Samba Web Administration
Tool) that allows samba's smb.conf file to be remotely managed
using your favourite web browser. For the time being this is
being enabled on TCP port 901 via inetd.

Please refer to the WHATSNEW.txt document for fixup information.
This binary release includes encrypted password support.
Please read the smb.conf file and ENCRYPTION.txt in the
docs directory for implementation details.

%ChangeLog
* Mon Nov 16 1998 John H Terpstra <jht@samba.org>
 - Ported to Caldera OpenLinux


%Prep
%setup
%patch -p1
%patch1 -p1


%Build
cd source
./configure --prefix=/usr --libdir=/etc --with-lockdir=/var/lock/samba --with-privatedir=/etc --with-swatdir=/usr/share/swat --with-pam
make all


%Install
${mkDESTDIR}
mkdir -p $DESTDIR
mkdir -p $DESTDIR/etc/codepages/src
mkdir -p $DESTDIR/etc/{logrotate.d,pam.d}
mkdir -p $DESTDIR/etc/rc.d/init.d
mkdir -p $DESTDIR/home/samba
mkdir -p $DESTDIR/usr/{bin,sbin}
mkdir -p $DESTDIR/usr/share/swat/{images,help,include}
mkdir -p $DESTDIR/usr/man/{man1,man5,man7,man8}
mkdir -p $DESTDIR/var/lock/samba
mkdir -p $DESTDIR/var/log/samba
mkdir -p $DESTDIR/var/spool/samba

# Install standard binary files
for i in nmblookup smbclient smbpasswd smbstatus testparm testprns \
      make_smbcodepage make_printerdef rpcclient
do
install -m755 -s source/bin/$i $DESTDIR/usr/bin
done
for i in addtosmbpass mksmbpasswd.sh smbtar 
do
install -m755 source/script/$i $DESTDIR/usr/bin
done

# Install secure binary files
for i in smbd nmbd swat
do
install -m755 -s source/bin/$i $DESTDIR/usr/sbin
done

# Install level 1 man pages
for i in smbclient.1 smbrun.1 smbstatus.1 smbtar.1 testparm.1 testprns.1 make_smbcodepage.1 nmblookup.1
do
install -m644 docs/manpages/$i $DESTDIR/usr/man/man1
done

# Install codepage source files
for i in 437 737 850 852 861 866 932 936 949 950
do
install -m644 source/codepages/codepage_def.$i $DESTDIR/etc/codepages/src
done

# Install SWAT helper files
for i in swat/help/*.html docs/htmldocs/*.html
do
install -m644 $i $DESTDIR/usr/share/swat/help
done
for i in swat/images/*.gif
do
install -m644 $i $DESTDIR/usr/share/swat/images
done
for i in swat/include/*.html
do
install -m644 $i $DESTDIR/usr/share/swat/include
done

# Install the miscellany
install -m644 swat/README $DESTDIR/usr/share/swat
install -m644 docs/manpages/smb.conf.5 $DESTDIR/usr/man/man5
install -m644 docs/manpages/lmhosts.5 $DESTDIR/usr/man/man5
install -m644 docs/manpages/smbpasswd.5 $DESTDIR/usr/man/man5
install -m644 docs/manpages/samba.7 $DESTDIR/usr/man/man7
install -m644 docs/manpages/smbd.8 $DESTDIR/usr/man/man8
install -m644 docs/manpages/nmbd.8 $DESTDIR/usr/man/man8
install -m644 docs/manpages/swat.8 $DESTDIR/usr/man/man8
install -m644 docs/manpages/smbpasswd.8 $DESTDIR/usr/man/man8
install -m644 packaging/Caldera/OpenLinux/smb.conf $DESTDIR/etc/smb.conf
install -m644 packaging/Caldera/OpenLinux/smbusers $DESTDIR/etc/smbusers
install -m755 packaging/Caldera/OpenLinux/smbprint $DESTDIR/usr/bin
install -m755 packaging/Caldera/OpenLinux/findsmb $DESTDIR/usr/bin
install -m755 packaging/Caldera/OpenLinux/smbadduser.perl $DESTDIR/usr/bin/smbadduser
install -m755 packaging/Caldera/OpenLinux/smb.init $DESTDIR/etc/rc.d/init.d/smb
ln -s /etc/rc.d/init.d/smb $DESTDIR/usr/sbin/samba
install -m644 packaging/Caldera/OpenLinux/samba.pamd $DESTDIR/etc/pam.d/samba
install -m644 packaging/Caldera/OpenLinux/samba.log $DESTDIR/etc/logrotate.d/samba
echo 127.0.0.1 localhost > $DESTDIR/etc/lmhosts

%{fixManPages}


%Clean
%{rmDESTDIR}


%Post
lisa --SysV-init install samba S91 3:4:5 K09 0:1:2:6

# Build codepage load files
for i in 437 737 850 852 861 866 932 936 949 950
do
/usr/bin/make_smbcodepage c $i /etc/codepages/src/codepage_def.$i /etc/codepages/codepage.$i
done


# Add swat entry to /etc/inetd.conf if needed
lisa --inetd install swat stream tcp nowait.400 root /usr/sbin/tcpd swat
perl -pi -e '$s=1 if /^swat/;
  print "swat:ALL EXCEPT 127.0.0.2\n" if eof && ! $s' /etc/hosts.deny
killall -1 inetd || :


%PreUn
if [ $1 = 0 ] ; then
    for n in /etc/codepages/*; do
	if [ $n != /etc/codepages/src ]; then
	    rm -rf $n
	fi
    done
    # We want to remove the browse.dat and wins.dat files so they can not interfer with a new version of samba!
    if [ -e /var/lock/samba/browse.dat ]; then
	    rm -f /var/lock/samba/browse.dat
    fi
    if [ -e /var/lock/samba/wins.dat ]; then
	    rm -f /var/lock/samba/wins.dat
    fi
fi

%PostUn
lisa --SysV-init remove samba $1
lisa --inetd disable swat $1
[ -x /usr/sbin/swat ]||perl -ni -e '/^swat\s*\:/||print' /etc/hosts.deny
killall -1 inetd || :

# Only delete remnants of samba if this is the final deletion.
if [ $1 != 0 ] ; then
    exit 0

    if [ -e /etc/pam.d/samba ]; then
      rm -f /etc/pam.d/samba
    fi
    if [ -e /var/log/samba ]; then
      rm -rf /var/log/samba
    fi
    if [ -e /var/lock/samba ]; then
      rm -rf /var/lock/samba
    fi
fi


%Files
%defattr(-,root,root)
%doc README COPYING Manifest Read-Manifest-Now
%doc WHATSNEW.txt Roadmap
%doc docs
%doc swat/README
%doc examples
/usr/sbin/smbd
/usr/sbin/nmbd
/usr/sbin/swat
%attr(0750,root,root) /usr/sbin/samba
/usr/bin/addtosmbpass
/usr/bin/mksmbpasswd.sh
/usr/bin/smbclient
/usr/bin/rpcclient
/usr/bin/testparm
/usr/bin/testprns
/usr/bin/findsmb
/usr/bin/smbstatus
/usr/bin/nmblookup
/usr/bin/make_smbcodepage
/usr/bin/make_printerdef
/usr/bin/smbpasswd
/usr/bin/smbtar
/usr/bin/smbprint
/usr/bin/smbadduser
/usr/share/swat/help/welcome.html
/usr/share/swat/help/DOMAIN_MEMBER.html
/usr/share/swat/help/lmhosts.5.html
/usr/share/swat/help/make_smbcodepage.1.html
/usr/share/swat/help/nmbd.8.html
/usr/share/swat/help/nmblookup.1.html
/usr/share/swat/help/samba.7.html
/usr/share/swat/help/smb.conf.5.html
/usr/share/swat/help/smbclient.1.html
/usr/share/swat/help/smbd.8.html
/usr/share/swat/help/smbpasswd.5.html
/usr/share/swat/help/smbpasswd.8.html
/usr/share/swat/help/smbrun.1.html
/usr/share/swat/help/smbstatus.1.html
/usr/share/swat/help/smbtar.1.html
/usr/share/swat/help/swat.8.html
/usr/share/swat/help/testparm.1.html
/usr/share/swat/help/testprns.1.html
/usr/share/swat/images/globals.gif
/usr/share/swat/images/home.gif
/usr/share/swat/images/passwd.gif
/usr/share/swat/images/printers.gif
/usr/share/swat/images/shares.gif
/usr/share/swat/images/samba.gif
/usr/share/swat/images/status.gif
/usr/share/swat/images/viewconfig.gif
/usr/share/swat/include/header.html
/usr/share/swat/include/footer.html
%config(noreplace) /etc/lmhosts
%config(noreplace) /etc/smb.conf
%config(noreplace) /etc/smbusers
/etc/rc.d/init.d/smb
/etc/logrotate.d/samba
/etc/pam.d/samba
/etc/codepages/src/codepage_def.437
/etc/codepages/src/codepage_def.737
/etc/codepages/src/codepage_def.850
/etc/codepages/src/codepage_def.852
/etc/codepages/src/codepage_def.861
/etc/codepages/src/codepage_def.866
/etc/codepages/src/codepage_def.932
/etc/codepages/src/codepage_def.936
/etc/codepages/src/codepage_def.949
/etc/codepages/src/codepage_def.950
/usr/man/man1/smbstatus.1*
/usr/man/man1/smbclient.1*
/usr/man/man1/make_smbcodepage.1*
/usr/man/man1/smbrun.1*
/usr/man/man1/smbtar.1*
/usr/man/man1/testparm.1*
/usr/man/man1/testprns.1*
/usr/man/man1/nmblookup.1*
/usr/man/man5/smb.conf.5*
/usr/man/man5/lmhosts.5*
/usr/man/man5/smbpasswd.5*
/usr/man/man7/samba.7*
/usr/man/man8/smbd.8*
/usr/man/man8/nmbd.8*
/usr/man/man8/smbpasswd.8*
/usr/man/man8/swat.8*
%attr(-,root,nobody) %dir /home/samba
%dir /etc/codepages
%dir /etc/codepages/src
%dir /var/lock/samba
%dir /var/log/samba
%attr(1777,root,root) %dir /var/spool/samba
