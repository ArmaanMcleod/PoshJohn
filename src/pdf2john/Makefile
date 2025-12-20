CC      = gcc
CFLAGS  = -Wall -Wextra -O2 -I../../mupdf/include
LDFLAGS = -L../../mupdf/build/release \
          -lmupdf -lmupdf-third \
          -lfreetype -ljpeg -lopenjp2 -lz

TARGET  = pdf2john
SRCS    = pdf2john.c pdfhash.c
OBJS    = $(SRCS:.c=.o)

all: $(TARGET)

# Executable build (standalone, no DLL import/export)
$(TARGET): $(OBJS)
	$(CC) $(CFLAGS) -DPDFHASH_STATIC -o $@ $^ $(LDFLAGS)

%.o: %.c
	$(CC) $(CFLAGS) -DPDFHASH_STATIC -c $< -o $@

# Shared library builds

# Linux
libpdfhash.so: $(SRCS)
	$(CC) -fPIC -shared -DPDFHASH_EXPORTS -o $@ $^ $(CFLAGS) $(LDFLAGS)

# macOS
libpdfhash.dylib: $(SRCS)
	$(CC) -fPIC -dynamiclib -DPDFHASH_EXPORTS -o $@ $^ $(CFLAGS) $(LDFLAGS)

# Windows
pdfhash.dll: $(SRCS)
	$(CC) -shared -DPDFHASH_EXPORTS \
	      -o $@ $^ \
	      $(CFLAGS) $(LDFLAGS) \
	      -Wl,--out-implib,libpdfhash.a \
	      -static-libgcc -static-libstdc++ -static

clean:
	rm -f $(TARGET) $(OBJS) *.so *.dylib *.dll *.a
