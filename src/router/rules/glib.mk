ifeq ($(ARCH),i386)
	export SUBARCH:=pc
else
ifeq ($(ARCH),x86_64)
	export SUBARCH:=pc
else
	export SUBARCH:=unknown
endif
endif


glib20-configure:
### jump for fast debug
#ifeq (1,0)
	echo .
	echo ############################################################
	echo # CONFIGURE LIBFFI                                         #
	echo ############################################################
	cd glib20/libffi && ./configure --enable-static --disable-shared --host=$(ARCH)-linux CC="ccache $(CC)" CFLAGS="$(COPTS) -std=gnu89 -D_GNU_SOURCE -fPIC -Drpl_malloc=malloc"
	echo 
	echo ############################################################
	echo # BUILD LIBFFI                                             #
	echo ############################################################
	$(MAKE) -C glib20/libffi clean all

	echo 
	echo ############################################################
	echo # CONFIGURE LIBICONV                                       #
	echo ############################################################
	cd glib20/libiconv && aclocal && ./configure --enable-shared --enable-static --host=$(ARCH)-linux CC="ccache $(CC)" CFLAGS="$(COPTS) -std=gnu89 $(MIPS16_OPT)  -D_GNU_SOURCE -fPIC -Drpl_malloc=malloc"
	echo 
	echo ############################################################
	echo # BUILD LIBICONV                                           #
	echo ############################################################
	$(MAKE) -C glib20/libiconv clean all

	echo 
	echo ############################################################
	echo # CONFIGURE GETTEXT                                        #
	echo ############################################################
	cd glib20/gettext && aclocal && ./configure --enable-shared --disable-static --disable-openmp --host=$(ARCH)-linux CC="ccache $(CC)" LDFLAGS="$(COPTS) -std=gnu89 $(MIPS16_OPT) -D_GNU_SOURCE -fPIC -Drpl_malloc=malloc " CFLAGS="$(COPTS)  $(MIPS16_OPT)  -D_GNU_SOURCE -fPIC -Drpl_malloc=malloc -I$(TOP)/glib20/libiconv/include" CXXFLAGS="$(COPTS)  $(MIPS16_OPT) -D_GNU_SOURCE -fPIC -Drpl_malloc=malloc -I$(TOP)/glib20/libiconv/include"
	echo 
	echo ############################################################
	echo # BUILD GETTEXT                                            #
	echo ############################################################
	$(MAKE) -C glib20/gettext clean all
#endif
	echo 
	echo ############################################################
	echo # CONFIGURE LIBGLIB                                        #
	echo ############################################################
	cd glib20/libglib && ./autogen.sh --host=$(ARCH)-linux \
	LIBFFI_CFLAGS="-I$(TOP)/glib20/libffi/$(ARCH)-$(SUBARCH)-linux-gnu/include" \
	LIBFFI_LIBS="-L$(TOP)/glib20/libffi/$(ARCH)-$(SUBARCH)-linux-gnu/.libs -lffi"
	cd glib20/libglib && ./configure --enable-shared --enable-static --disable-fam --enable-debug=no --disable-selinux --disable-man --host=$(ARCH)-linux --with-libiconv=gnu --disable-modular-tests \
	CC="ccache $(CC)" CFLAGS="$(COPTS) -std=gnu89  $(MIPS16_OPT) -D_GNU_SOURCE=1  -I$(TOP)/zlib -fPIC -Drpl_malloc=malloc -I$(TOP)/glib20/gettext/gettext-runtime/intl  -I$(TOP)/glib20/libiconv/include -I$(TOP)/glib20/libffi/$(ARCH)-$(SUBARCH)-linux-gnu/include  -L$(TOP)/glib20/libffi/$(ARCH)-$(SUBARCH)-linux-gnu/.libs -lffi -L$(TOP)/glib20/libiconv/lib/.libs -liconv -L$(TOP)/glib20/gettext/gettext-runtime/intl/.libs -L$(TOP)/zlib -lz -pthread -lpthread" \
	LIBFFI_CFLAGS="-I$(TOP)/glib20/libffi/$(ARCH)-$(SUBARCH)-linux-gnu/include" \
	LIBFFI_LIBS="-L$(TOP)/glib20/libffi/$(ARCH)-$(SUBARCH)-linux-gnu/.libs -lffi" \
	ZLIB_CFLAGS="-I$(TOP)/zlib" \
	ZLIB_LIBS="-L$(TOP)/zlib -lz" \
	glib_cv_stack_grows=no glib_cv_uscore=no ac_cv_func_mmap_fixed_mapped=yes ac_cv_func_posix_getpwuid_r=yes ac_cv_func_posix_getgrgid_r=yes
	echo 
	echo ############################################################
	echo # BUILD LIBGLIB                                            #
	echo ############################################################
	$(MAKE) -C glib20/libglib clean all

glib20:
	$(MAKE) -C glib20/libffi all
	$(MAKE) -C glib20/libiconv all
	$(MAKE) -C glib20/gettext all
	$(MAKE) -C glib20/libglib all

glib20-clean:
	$(MAKE) -C glib20/libffi clean
	$(MAKE) -C glib20/libiconv clean
	$(MAKE) -C glib20/gettext clean
	$(MAKE) -C glib20/libglib clean

glib20-install:
	install -D glib20/libglib/glib/.libs/libglib-2.0.so.0 $(INSTALLDIR)/glib20/usr/lib/libglib-2.0.so.0
ifeq ($(CONFIG_MC),y)
	install -D glib20/libglib/gmodule/.libs/libgmodule-2.0.so.0 $(INSTALLDIR)/glib20/usr/lib/libgmodule-2.0.so.0
endif
ifeq ($(CONFIG_LIBQMI),y)
	install -D glib20/libglib/gmodule/.libs/libgmodule-2.0.so.0 $(INSTALLDIR)/glib20/usr/lib/libgmodule-2.0.so.0
	install -D glib20/libglib/gthread/.libs/libgthread-2.0.so.0 $(INSTALLDIR)/glib20/usr/lib/libgthread-2.0.so.0
	install -D glib20/libglib/gobject/.libs/libgobject-2.0.so.0 $(INSTALLDIR)/glib20/usr/lib/libgobject-2.0.so.0
	install -D glib20/libglib/gio/.libs/libgio-2.0.so.0 $(INSTALLDIR)/glib20/usr/lib/libgio-2.0.so.0
endif
	install -D glib20/libiconv/lib/.libs/libiconv.so.2 $(INSTALLDIR)/glib20/usr/lib/libiconv.so.2
	-install -D glib20/gettext/gettext-runtime/intl/.libs/libintl.so.8 $(INSTALLDIR)/glib20/usr/lib/libintl.so.8
	-install -D glib20/gettext/gettext-runtime/intl/.libs/libgnuintl.so.8 $(INSTALLDIR)/glib20/usr/lib/libgnuintl.so.8
#	install -D glib20/gettext/gettext-runtime/libasprintf/.libs/libasprintf.so.0 $(INSTALLDIR)/glib20/usr/lib/libasprintf.so.0
	-install -D glib20/gettext/gettext-runtime/src/.libs/envsubst $(INSTALLDIR)/glib20/usr/bin/envsubst
	-install -D glib20/gettext/gettext-runtime/src/.libs/gettext $(INSTALLDIR)/glib20/usr/bin/gettext
	-install -D glib20/gettext/gettext-runtime/src/.libs/ngettext $(INSTALLDIR)/glib20/usr/bin/ngettext

