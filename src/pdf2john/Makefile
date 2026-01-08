CC      = gcc
CFLAGS  = -Wall -Wextra -O2 -I../../mupdf/include
LDFLAGS = -L../../mupdf/build/release \
		  -lmupdf -lmupdf-third -lz -lm

TARGET  = pdf2john
SRCS    = pdf2john.c pdfhash.c
OBJS    = $(SRCS:.c=.o)

ifeq ($(OS),Windows_NT)
	LIBTARGET = libpdfhash.dll
else
	UNAME_S := $(shell uname -s)
	ifeq ($(UNAME_S),Linux)
		LIBTARGET = libpdfhash.so
	else ifeq ($(UNAME_S),Darwin)
		LIBTARGET = libpdfhash.dylib
	endif
endif

all: $(TARGET) $(LIBTARGET)

# Executable build (standalone, no DLL import/export)
$(TARGET): $(OBJS)
	$(CC) $(CFLAGS) -DPDFHASH_STATIC -o $@ $^ $(LDFLAGS)
	mkdir -p dist
	cp -f $(TARGET) dist/

%.o: %.c
	$(CC) $(CFLAGS) -DPDFHASH_STATIC -c $< -o $@

# Shared library builds

# Linux
libpdfhash.so: $(SRCS)
	$(CC) -fPIC -shared -DPDFHASH_EXPORTS -o $@ $^ $(CFLAGS) $(LDFLAGS)
	mkdir -p dist
	cp -f libpdfhash.so dist/

# macOS
libpdfhash.dylib: $(SRCS)
	$(CC) -fPIC -dynamiclib -DPDFHASH_EXPORTS -o $@ $^ $(CFLAGS) $(LDFLAGS)
	mkdir -p dist
	cp -f libpdfhash.dylib dist/

# Windows
libpdfhash.dll: $(SRCS)
	$(CC) -shared -DPDFHASH_EXPORTS \
	-o $@ $^ \
	$(CFLAGS) $(LDFLAGS) \
	-static-libgcc
	mkdir -p dist
	cp -f libpdfhash.dll dist/

clean:
	rm -f $(TARGET) $(OBJS) *.so *.dylib *.dll *.a
	rm -rf dist
