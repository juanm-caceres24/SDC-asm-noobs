all: aplicacion.efi

aplicacion.o: aplicacion.c
	gcc -I/usr/include/efi \
	-I/usr/include/efi/x86_64 \
	-I/usr/include/efi/protocol \
	-fpic -ffreestanding \
	-fno-stack-protector -fno-strict-aliasing \
	-fshort-wchar -mno-red-zone \
	-maccumulate-outgoing-args \
	-Wall -c aplicacion.c -o aplicacion.o

aplicacion.so: aplicacion.o
	ld -shared -Bsymbolic \
	-L/usr/lib -L/usr/lib/efi \
	-T /usr/lib/elf_x86_64_efi.lds \
	/usr/lib/crt0-efi-x86_64.o aplicacion.o \
	-o aplicacion.so -lefi -lgnuefi

aplicacion.efi: aplicacion.so
	objcopy \
	-j .text -j .sdata -j .data -j .dynamic \
	-j .dynsym -j .rel -j .rela -j .rel.* -j .rela.* -j .reloc \
	--target=efi-app-x86_64 \
	aplicacion.so aplicacion.efi

clean:
	rm -f *.o *.so *.efi
