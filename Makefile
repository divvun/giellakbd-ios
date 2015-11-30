ARCHS="armv7 armv7s arm64 i386 x86_64"
FRAMEWORKS = Frameworks/libarchive.framework \
	     Frameworks/liblzma.framework \
	     Frameworks/libhfstospell.framework

all: $(FRAMEWORKS)

libarchive: # Cool stub!
xz: # Cool stub!
hfst-ospell: # Cool stub!


Frameworks/liblzma.framework: xz
	cd $< && ./autogen.sh 2>&1
	cd $< && PREFIX=$(PROJECT_DIR) ARCHS=$(ARCHS) autoframework liblzma liblzma.a \
		--disable-xz \
		--disable-xzdec \
		--disable-lzmadec \
		--disable-lzmainfo \
		--disable-lzma-links \
	       	--disable-scripts \
		--disable-encoders \
		--disable-doc \
		--disable-rpath

Frameworks/libhfstospell.framework: hfst-ospell
	cd $< && ./autogen.sh
	cd $< && PREFIX=$(PROJECT_DIR) ARCHS=$(ARCHS) autoframework libhfstospell libhfstospell.a \
		--disable-silent-rules \
		--disable-hfst-ospell-office \
		--disable-xml \
		--disable-tool \
		--enable-zhfst \
		--disable-caching \
		--with-extract=tmpdir

Frameworks/libarchive.framework: libarchive
	#cd $< && ./autogen.sh
	# $(PROJECT_DIR)  set by Xcode
	# $(ARCHS)        set by Xcode, but sadly does not include all target architectures
	cd $< && PREFIX=$(PROJECT_DIR) ARCHS=$(ARCHS) autoframework libarchive libarchive.a \
		--without-bz2lib \
		--without-lzmadec \
		--without-iconv \
		--without-lzo2 \
		--without-nettle \
		--without-openssl \
		--without-xml2 \
		--without-expat \
		--disable-bsdcpio \
		--disable-bsdtar
		#--with-lzma \
		#--with-zlib \

