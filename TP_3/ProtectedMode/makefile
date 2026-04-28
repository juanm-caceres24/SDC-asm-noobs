.PHONY: all build run ds dc clean

# File to compile (default provided, can be overridden via args)
SRC ?= main.S

# Default target
all: build

# Option 1: Only build the image
build: main.img

# Option 2: Run QEMU normally
run: main.img
	qemu-system-i386 -fda main.img -boot a -monitor stdio -no-reboot -d int

# Option 3A: Run QEMU and freeze with GDB on port 1234
ds: main.img
	@echo "Starting QEMU. Waiting for GDB connection on port 1234..."
	qemu-system-i386 -fda main.img -boot a -s -S -monitor stdio -no-reboot

# Option 3B: Launch GDB and connect to QEMU
dc:
	@echo "Connecting to QEMU via GDB..."
	gdb -ex "target remote localhost:1234" \
	    -ex "break *0x7c51" \
	    -ex "dashboard -layout breakpoints stack assembly"

# Link the object file into a bootable binary image
main.img: main.o link.ld
	ld --oformat binary -o main.img -T link.ld main.o

# Compile the Assembly file with debug symbols (-g)
main.o: $(SRC)
	as -g -o main.o $(SRC)

# Clean up generated build files
clean:
	rm -f main.o main.img