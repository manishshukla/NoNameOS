MAKEFILE=Makefile

TARGET_BIN=test.bin

TARGET_DIR=../../../bin/apps/

INCLUDE_DIR=../../../include/

AMOS_LIBC=../../../bin/lib/libc.a

CC=gcc
LD=ld
RM=del

LDFLAGS=-T ../apps.ld -s -nostdlib -Map $(TARGET_DIR)test.map
CCFLAGS=-Wall -O -nostdlib -fno-builtin -nostdinc -I $(INCLUDE_DIR)

OBJ=test.o
	
all: $(TARGET_BIN)

$(TARGET_BIN): $(OBJ)
	$(LD) $(LDFLAGS) -o $(TARGET_DIR)$(TARGET_BIN) $(OBJ) $(AMOS_LIBC)

%.o: %.c
	$(CC) $(CCFLAGS) -c -o $@ $<

clean:
	$(RM) *.o
