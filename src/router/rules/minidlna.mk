minidlna-configure: zlib
	cd minidlna && make clean
	cd minidlna && make distclean
	cd minidlna && make

minidlna: zlib
	cd minidlna && make

minidlna-clean:
	cd minidlna && make clean

minidlna-distclean:
	cd minidlna && make distclean
	-rm -f $(TOP)/minidlna/libogg-1.3.0/Makefile
	-rm -f $(TOP)/minidlna/sqlite-3.6.22/Makefile	
	-rm -f $(TOP)/minidlna/libvorbis-1.3.3/Makefile	
	-rm -f $(TOP)/minidlna/flac-1.2.1/Makefile	
	-rm -f $(TOP)/minidlna/jpeg-8/Makefile	

minidlna-install:
	cd minidlna && make install TARGETDIR=$(TOP)/$(ARCH)-uclibc/install/minidlna
	install -D minidlna/config/minidlna.webnas $(INSTALLDIR)/minidlna/etc/config/minidlna.webnas
	install -D minidlna/config/minidlna.nvramconfig $(INSTALLDIR)/minidlna/etc/config/minidlna.nvramconfig
