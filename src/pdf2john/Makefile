CC      = gcc
CFLAGS  = -Wall -Wextra -O2 -I../../mupdf/include
LDFLAGS = -L../../mupdf/build/release \
          -lmupdf -lmupdf-third \
          -lfreetype -ljpeg -lopenjp2 -lz

TARGET  = pdf2john
SRCS    = pdf2john.c pdfhash.c
OBJS    = $(SRCS:.c=.o)

all: $(TARGET)

$(TARGET): $(OBJS)
	$(CC) $(CFLAGS) -o $@ $^ $(LDFLAGS)

%.o: %.c
	$(CC) $(CFLAGS) -c $< -o $@

run: $(TARGET)
	./$(TARGET) sample.pdf

clean:
	rm -f $(TARGET) $(OBJS)

.PHONY: all clean run
