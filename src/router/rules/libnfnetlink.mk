libnfnetlink-configure:
	cd libnfnetlink && autoreconf -ivf && ./configure \
		--build=$(ARCH)-linux \
		--host=$(ARCH)-linux-gnu \
		--prefix=/usr \
		--enable-shared \
		--disable-static \
		--libdir=$(TOP)/libnfnetlink/src/.libs
	$(MAKE) -C libnfnetlink CFLAGS="$(COPTS) -D_GNU_SOURCE -DNEED_PRINTF"	

libnfnetlink:
	$(MAKE) -C libnfnetlink CFLAGS="$(COPTS) $(MIPS16_OPT) -D_GNU_SOURCE -DNEED_PRINTF"	

libnfnetlink-install:
	install -D libnfnetlink/src/.libs/libnfnetlink.so.0 $(INSTALLDIR)/libnfnetlink/usr/lib/libnfnetlink.so.0

