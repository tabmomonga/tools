CC = gcc
CFLAGS = -I/usr/include/rpm -I/usr/include/db1
RPM_VER = $(shell rpm --version | cut -d ' ' -f 3 | cut -d '.' -f 1)
LIBS = -lrpm -lpopt -lrpmio -lrpmdb
TARGET = rpmvercmp

all: $(TARGET)

$(TARGET): rpmvercmp.c
	$(CC) $(CFLAGS) $(LIBS) -o $@ $<

%.man: %
	file $< | grep 'ruby script' > /dev/null && rd2 -rrd/rd2man-lib $< > $@

clean:
	rm -rf $(TARGET) $(TARGET).o
