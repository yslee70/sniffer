##### CPU variants #####
GCCARCH = $(shell uname -m)
MTUNE =

ifeq ($(GCCARCH),amd64)
  GCCARCH = core2
  MTUNE = -mtune=core2
endif

ifeq ($(GCCARCH),i386)
  GCCARCH = core2
  MTUNE = -mtune=core2
endif

ifeq ($(GCCARCH),x86_64)
  GCCARCH = core2
  MTUNE = -mtune=core2
endif

ifeq ($(findstring arm,$(GCCARCH)),arm)
  GCCARCH = armv6k
endif

ifeq ($(GCCARCH),aarch64)
  GCCARCH = native
endif

#GCCVERSION = $(shell gcc --version | grep ^gcc | sed 's/^.* //g' | cut -f1,2 -d.)  
#ifeq "$(GCCVERSION)" "4.1"
#  GCCARCH = core2
#endif

FBSDDEF =
PLATFORM = $(shell uname)
ifeq ($(PLATFORM),FreeBSD)
  FBSDDEF = -D __vm_FREEBSD__
endif

.DEFAULT_GOAL := shared
.PHONY: default
default: shared ;


WIRESHARKLIBSTATIC =$(shell pkg-config --libs-only-l --static wireshark)
WIRESHARKCFLAGS =$(shell pkg-config --cflags wireshark)

core2cust: GCCARCH = core2
core2: GCCARCH = core2
armv6k: GCCARCH = armv6k
clean: GCCARCH = core2
ss7: core2 static
ss7: CXXFLAGS += -DHAVE_LIBWIRESHARK -DLIBWIRESHARK_VERSION=30605 ${WIRESHARKCFLAGS}
ss7: SS7= ${WIRESHARKLIBSTATIC} -lwiretap -lwsutil -llua5.2 -lxml2 -llz4 -llzma -lz -lcares -lnghttp2
#Makefile.deps: GCCARCH = core2


version = $(shell grep RTPSENSOR_VERSION voipmonitor_define.h | cut -d" " -f 3 | tr -d "\"")

objects = $(shell ls -1 *.cpp | sed 's/\.cpp/.o/' | tr "\n" " ") $(shell ls -1 jitterbuffer/*.c | sed 's/\.c/.o/' | tr "\n" " ") $(shell ls -1 dssl/*.c dssl/*.cpp | sed 's/\.cpp/.o/' | sed 's/\.c/.o/' | tr "\n" " ") cloud_router/cloud_router_base.o cloud_router/cloud_router_client.o

#headers = $(shell ls -1 *.h | tr "\n" " ") $(shell ls -1 jitterbuffer/*.h | tr "\n" " ") $(shell ls -1 jitterbuffer/asterisk/*.h | tr "\n" " ")

JSONLIB = $(shell pkg-config --libs json-c)
JSONCFLAGS = $(shell pkg-config --cflags json-c)

MYSQLLIB=-L/usr/lib/x86_64-linux-gnu -lmysqlclient -lpthread -ldl -lssl -lcrypto -lresolv -lm -lrt 
MYSQLINC=-I/usr/include/mysql 
MYSQL_WITHOUT_SSL_SUPPORT=yes
DPDKINC=
DPDKLIB=
KAFKALIB=-L/home/posicube/librdkafka/src /home/posicube/librdkafka/src/librdkafka.so
KAFKAINC=-I/home/posicube/librdkafka/src

ifeq ($(MYSQL_WITHOUT_SSL_SUPPORT),yes)
  MYSQL_WITHOUT_SSL_SUPPORT = -D MYSQL_WITHOUT_SSL_SUPPORT
endif

GLIBCFLAGS =$(shell pkg-config --cflags glib-2.0)
GLIBLIB =$(shell pkg-config --libs glib-2.0)
GLIBLIBPATH =$(shell pkg-config --libs-only-L glib-2.0)
CURLCFLAGS =$(shell pkg-config --cflags libcurl)
CURLLIB =$(shell pkg-config --libs libcurl)
CURLLIBSTATIC =$(shell pkg-config --libs --static libcurl)
PCAPLIBSTATIC =$(shell pkg-config --libs --static libpcap)

LIBPNG=-lpng
LIBFFT=-lfftw3
LIBLD=-ldl
LIBLZMA=-llzma
LIBGNUTLS=
LIBGNUTLSSTATIC=-lgcrypt -lgpg-error $(shell pkg-config gnutls --libs --static)
SHARED_LIBS = ${LIBLD} -licuuc -licudata -lpthread -lpcap -lz -lvorbis -lvorbisenc -logg -lodbc ${MYSQLLIB} ${KAFKALIB} -lrt -lsnappy -lcurl -lssl -lcrypto ${JSONLIB} -lxml2 -lrrd ${LIBGNUTLS}  ${GLIBLIB} ${LIBLZMA} -llzo2 ${LIBPNG} ${LIBFFT} 
STATIC_LIBS = -static   -licuuc -licudata -lodbc -lltdl -lrt -lz -lcrypt -lm ${CURLLIBSTATIC} -lssl -lcrypto -static-libstdc++ -static-libgcc ${PCAPLIBSTATIC} -lpthread ${MYSQLLIB} ${KAFKALIB} -lpthread -lz -lc -lvorbis -lvorbisenc -logg -lrt -lsnappy ${JSONLIB} -lrrd -lxml2 ${GLIBLIB} -lpcre -lz -ldbi -llzma ${LIBGNUTLSSTATIC} ${LIBGNUTLSSTATIC} -llzo2 ${LIBPNG} ${LIBFFT} -lpthread ${SS7} ${LIBLD}
INCLUDES =  ${DPDKINC} -I/usr/local/include ${MYSQLINC} ${KAFKAINC} -I jitterbuffer/ ${JSONCFLAGS} ${GLIBCFLAGS} 
LIBS_PATH = ${DPDKLIB} -L/usr/local/lib/  ${GLIBLIBPATH}
CXXFLAGS +=  -Wall -fPIC -g3 -O2 -march=$(GCCARCH) ${MTUNE} ${INCLUDES} ${FBSDDEF} ${MYSQL_WITHOUT_SSL_SUPPORT}  
CFLAGS += ${CXXFLAGS}
LIBS = ${SHARED_LIBS} 
LIBS2 = @LIBS2@

shared: LDFLAGS += -Wl,--allow-multiple-definition
shared: cleantest $(objects) 
	${CXX} $(objects) ${LDFLAGS} -o voipmonitor ${LIBS_PATH} ${LIBS}

static: LDFLAGS += -Wl,--allow-multiple-definition
static: cleantest $(objects) 
	${CXX} $(objects) ${LDFLAGS} -o voipmonitor ${LIBS_PATH} ${STATIC_LIBS}

core2: cleantest static

armv6k: cleantest static

armv5shared: CXXFLAGS+= -DPACKED 
armv5shared: CFLAGS+= -DPACKED 
armv5shared: cleantest shared

armv5static: CXXFLAGS+= -DPACKED 
armv5static: CFLAGS+= -DPACKED 
armv5static: cleantest static

core2cust: LDFLAGS = -nostartfiles -static -Wl,--allow-multiple-definition
core2cust: GLIBCDIR = /opt/libc/lib
core2cust: STARTFILES = $(GLIBCDIR)/crt1.o $(GLIBCDIR)/crti.o $(shell gcc --print-file-name=crtbegin.o)
core2cust: ENDFILES = $(shell gcc --print-file-name=crtend.o) $(GLIBCDIR)/crtn.o
core2cust: LIBGROUP = -Wl,--start-group $(GLIBCDIR)/libc.a -lgcc -lgcc_eh -Wl,--end-group
core2cust: CXXFLAGS += -I /opt/libc/include 
core2cust: CFLAGS += ${CXXFLAGS}
core2cust: cleantest $(objects)
	${CXX} $(LDFLAGS) -o voipmonitor $(STARTFILES) ${objects} $(LIBGROUP) $(ENDFILES) -L/opt/libc/lib ${STATIC_LIBS} ${LIBS_PATH}

DEPENDSC:=${shell find . -type f -name '*.c' -print}
DEPENDSCPP:=${shell find . -type f -name '*.cpp' -print}

-include Makefile.deps

Makefile.deps:
	cp /dev/null Makefile.deps
	for F in $(DEPENDSC); do \
	 D=`dirname $$F | sed "s/^\.\///"`; \
	 echo -n "$$D/" >> Makefile.deps; \
	 $(CC) $(CFLAGS) -MM -MG $$F \
	 >> Makefile.deps; \
	done
	for F in $(DEPENDSCPP); do \
	 D=`dirname $$F | sed "s/^\.\///"`; \
	 echo -n "$$D/" >> Makefile.deps; \
	 $(CXX) $(CXXFLAGS) -MM -MG $$F \
	 >> Makefile.deps; \
	done

cleantest:
	@cmp -s .cleancount .lastclean || $(MAKE) clean

clean :
	rm -f Makefile.deps
	rm -f $(objects) voipmonitor
	cp -f .cleancount .lastclean

targzarmv6k: armv6k
	rm -rf voipmonitor-armv6k-${version}-static*
	mkdir -p voipmonitor-armv6k-${version}-static/usr/local/sbin
	cp voipmonitor voipmonitor-armv6k-${version}-static/usr/local/sbin/
	chmod +x voipmonitor-armv6k-${version}-static/usr/local/sbin/voipmonitor
	mkdir -p voipmonitor-armv6k-${version}-static/usr/local/share/voipmonitor/audio
	cp samples/audio/* voipmonitor-armv6k-${version}-static/usr/local/share/voipmonitor/audio/
	mkdir -p voipmonitor-armv6k-${version}-static/etc/init.d
	cp config/voipmonitor.conf voipmonitor-armv6k-${version}-static/etc/
	cp config/init.d/voipmonitor voipmonitor-armv6k-${version}-static/etc/init.d/
	chmod +x voipmonitor-armv6k-${version}-static/etc/init.d/voipmonitor 
	cp scripts/install-script.sh voipmonitor-armv6k-${version}-static/
	chmod +x voipmonitor-armv6k-${version}-static/install-script.sh
	tar -czf voipmonitor-armv6k-${version}-static.tar.gz voipmonitor-armv6k-${version}-static
	rm -rf voipmonitor-armv6k-${version}-static

targz64: core2
	rm -rf voipmonitor-amd64-${version}-static*
	mkdir -p voipmonitor-amd64-${version}-static/usr/local/sbin
	cp voipmonitor voipmonitor-amd64-${version}-static/usr/local/sbin/
	chmod +x voipmonitor-amd64-${version}-static/usr/local/sbin/voipmonitor
	mkdir -p voipmonitor-amd64-${version}-static/usr/local/share/voipmonitor/audio
	cp samples/audio/* voipmonitor-amd64-${version}-static/usr/local/share/voipmonitor/audio/
	mkdir -p voipmonitor-amd64-${version}-static/etc/init.d
	cp config/voipmonitor.conf voipmonitor-amd64-${version}-static/etc/
	cp config/init.d/voipmonitor voipmonitor-amd64-${version}-static/etc/init.d/
	chmod +x voipmonitor-amd64-${version}-static/etc/init.d/voipmonitor 
	cp scripts/install-script.sh voipmonitor-amd64-${version}-static/
	chmod +x voipmonitor-amd64-${version}-static/install-script.sh
	tar -czf voipmonitor-amd64-${version}-static.tar.gz voipmonitor-amd64-${version}-static
	rm -rf voipmonitor-amd64-${version}-static

targz64heapprof: core2
	rm -rf voipmonitor-heapprof-amd64-${version}-static*
	mkdir -p voipmonitor-heapprof-amd64-${version}-static/usr/local/sbin
	cp voipmonitor voipmonitor-heapprof-amd64-${version}-static/usr/local/sbin/
	chmod +x voipmonitor-heapprof-amd64-${version}-static/usr/local/sbin/voipmonitor
	mkdir -p voipmonitor-heapprof-amd64-${version}-static/usr/local/share/voipmonitor/audio
	cp samples/audio/* voipmonitor-heapprof-amd64-${version}-static/usr/local/share/voipmonitor/audio/
	mkdir -p voipmonitor-heapprof-amd64-${version}-static/etc/init.d
	cp config/voipmonitor.conf voipmonitor-heapprof-amd64-${version}-static/etc/
	cp config/init.d/voipmonitor voipmonitor-heapprof-amd64-${version}-static/etc/init.d/
	chmod +x voipmonitor-heapprof-amd64-${version}-static/etc/init.d/voipmonitor 
	cp scripts/install-script.sh voipmonitor-heapprof-amd64-${version}-static/
	chmod +x voipmonitor-heapprof-amd64-${version}-static/install-script.sh
	tar -czf voipmonitor-heapprof-amd64-${version}-static.tar.gz voipmonitor-heapprof-amd64-${version}-static
	rm -rf voipmonitor-heapprof-amd64-${version}-static

targz64debug: core2
	rm -rf voipmonitor-amd64-${version}-static*
	mkdir -p voipmonitor-amd64-${version}-static/usr/local/sbin
	cp voipmonitor voipmonitor-amd64-${version}-static/usr/local/sbin/
	chmod +x voipmonitor-amd64-${version}-static/usr/local/sbin/voipmonitor
	mkdir -p voipmonitor-amd64-${version}-static/usr/local/share/voipmonitor/audio
	cp samples/audio/* voipmonitor-amd64-${version}-static/usr/local/share/voipmonitor/audio/
	mkdir -p voipmonitor-amd64-${version}-static/etc/init.d
	cp config/voipmonitor.conf voipmonitor-amd64-${version}-static/etc/
	cp config/init.d/voipmonitor voipmonitor-amd64-${version}-static/etc/init.d/
	chmod +x voipmonitor-amd64-${version}-static/etc/init.d/voipmonitor 
	cp scripts/install-script.sh voipmonitor-amd64-${version}-static/
	chmod +x voipmonitor-amd64-${version}-static/install-script.sh
	tar -czf voipmonitor-amd64-${version}-static-debug.tar.gz voipmonitor-amd64-${version}-static
	rm -rf voipmonitor-amd64-${version}-static

targz64ss7: ss7
	rm -rf voipmonitor-wireshark-amd64-${version}-static*
	mkdir -p voipmonitor-wireshark-amd64-${version}-static/usr/local/sbin
	cp voipmonitor voipmonitor-wireshark-amd64-${version}-static/usr/local/sbin/
	chmod +x voipmonitor-wireshark-amd64-${version}-static/usr/local/sbin/voipmonitor
	mkdir -p voipmonitor-wireshark-amd64-${version}-static/usr/local/share/voipmonitor/audio
	cp samples/audio/* voipmonitor-wireshark-amd64-${version}-static/usr/local/share/voipmonitor/audio/
	mkdir -p voipmonitor-wireshark-amd64-${version}-static/etc/init.d
	cp config/voipmonitor.conf voipmonitor-wireshark-amd64-${version}-static/etc/
	cp config/init.d/voipmonitor voipmonitor-wireshark-amd64-${version}-static/etc/init.d/
	chmod +x voipmonitor-wireshark-amd64-${version}-static/etc/init.d/voipmonitor 
	cp scripts/install-script.sh voipmonitor-wireshark-amd64-${version}-static/
	chmod +x voipmonitor-wireshark-amd64-${version}-static/install-script.sh
	tar -czf voipmonitor-wireshark-amd64-${version}-static.tar.gz voipmonitor-wireshark-amd64-${version}-static
	rm -rf voipmonitor-wireshark-amd64-${version}-static

targz32: core2cust
	rm -rf voipmonitor-i686-${version}-static*
	mkdir -p voipmonitor-i686-${version}-static/usr/local/sbin
	cp voipmonitor voipmonitor-i686-${version}-static/usr/local/sbin/
	chmod +x voipmonitor-i686-${version}-static/usr/local/sbin/voipmonitor
	mkdir -p voipmonitor-amd64-${version}-static/usr/local/share/voipmonitor/audio
	cp samples/audio/* voipmonitor-amd64-${version}-static/usr/local/share/voipmonitor/audio/
	mkdir -p voipmonitor-i686-${version}-static/etc/init.d
	cp config/voipmonitor.conf voipmonitor-i686-${version}-static/etc/
	cp config/init.d/voipmonitor voipmonitor-i686-${version}-static/etc/init.d/
	chmod +x voipmonitor-i686-${version}-static/etc/init.d/voipmonitor 
	cp scripts/install-script.sh voipmonitor-i686-${version}-static/
	chmod +x voipmonitor-i686-${version}-static/install-script.sh
	tar -czf voipmonitor-i686-${version}-static.tar.gz voipmonitor-i686-${version}-static
	rm -rf voipmonitor-i686-${version}-static

source: clean
	rm -rf voipmonitor-${version}-src
	mkdir voipmonitor-${version}-src
	cp -a * voipmonitor-${version}-src/
	rm -rf voipmonitor-${version}-src/voipmonitor-${version}-src
	rm -rf `find voipmonitor-${version}-src -type d -name .svn`
	rm voipmonitor-${version}-src/Makefile
	echo 1 > voipmonitor-${version}-src/.cleancount
	tar -czf voipmonitor-${version}-src.tar.gz voipmonitor-${version}-src


install: 
	install voipmonitor /usr/local/sbin/

