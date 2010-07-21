CC = gcc
CFLAGS = -I/usr/include/rpm
RPM_VER = $(shell LANG=C rpmbuild --version | cut -d ' ' -f 3 | cut -d '.' -f 1,2)
ifeq ($(RPM_VER), 4.6)
LIBS = -lrpm -lpopt -lrpmio
endif
ifeq ($(RPM_VER), 4.7)
LIBS = -lrpm -lpopt -lrpmio
endif
ifeq ($(RPM_VER), 4.8)
LIBS = -lrpm -lpopt -lrpmio
endif
ifndef LIBS
LIBS = -lrpm -lpopt -lrpmio -lrpmdb
endif
TARGET = rpmvercmp

all: $(TARGET)

$(TARGET): rpmvercmp.c
	$(CC) $(CFLAGS) $(LIBS) -o $@ $<

%.man: %
	file $< | grep 'ruby script' > /dev/null && rd2 -rrd/rd2man-lib $< > $@

clean:
	rm -rf $(TARGET) $(TARGET).o
