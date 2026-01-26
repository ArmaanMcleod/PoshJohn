CC       = gcc
LZMA_SDK_DIR = ../../lzma-sdk
CFLAGS   = -Wall -Wextra -O2 -ICPP -I$(LZMA_SDK_DIR)/C -DREPACK7Z_STATIC
LDFLAGS  = -L$(LZMA_SDK_DIR)/C

TARGET   = repack7z
SRCS     = repack7z_main.c repack7z.c
OBJS     = $(SRCS:.c=.o)

# OS detection
ifeq ($(OS),Windows_NT)
    LIBTARGET = librepack7z.dll
    SHARED_FLAGS = -shared -static-libgcc -static-libstdc++
else
    UNAME_S := $(shell uname -s)
    ifeq ($(UNAME_S),Linux)
        LIBTARGET = librepack7z.so
        SHARED_FLAGS = -shared
    else ifeq ($(UNAME_S),Darwin)
        LIBTARGET = librepack7z.dylib
        SHARED_FLAGS = -dynamiclib
    endif
endif


all: $(TARGET) $(LIBTARGET)

# Executable

$(TARGET): $(OBJS)
	$(CC) -o $@ $^ $(LDFLAGS)
	mkdir -p dist
	cp -f $(TARGET) dist/

# Shared library

$(LIBTARGET): $(OBJS)
	$(CC) $(SHARED_FLAGS) -o $@ $^ $(LDFLAGS)
	mkdir -p dist
	cp -f $(LIBTARGET) dist/

%.o: %.c
	$(CC) $(CFLAGS) -c $< -o $@

clean:
	rm -f $(TARGET) $(OBJS) $(LIBTARGET)
	rm -rf dist
