all:
	cat 128-0.rom \
		128-1.rom \
		../rom_src/main.bin \
		ESXMMC.BIN ESXMMC.BIN \
		dvmen3e0.rom \
		dvmen3e1.rom \
		dvmen3e2.rom \
		opense.rom \
		>sizif.bin
	objcopy --input-target=binary --output-target=ihex sizif.bin sizif.hex
	rm sizif.bin
