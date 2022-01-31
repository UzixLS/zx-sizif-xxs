# Each bank = 16Kb
bank00=128-0.rom              # 0x00000
bank01=128-1.rom              # 0x04000
bank02=../rom_src/main.bin    # 0x08000
bank03=ESXMMC.BIN ESXMMC.BIN  # 0x0C000
bank04=zcen3e0.rom            # 0x10000
bank05=zcen3e1.rom            # 0x14000
bank06=zcen3e2.rom            # 0x18000
bank07=zero8k.bin zero8k.bin  # 0x1C000

sizif.rom: ${bank00} ${bank01} ${bank02} ${bank03} ${bank04} ${bank05} ${bank06} ${bank07}

%.rom:
	cat $+ > $@

%.hex: %.rom
	objcopy --input-target=binary --output-target=ihex $< $@

.DEFAULT_GOAL := all
all: sizif.hex

clean:
	rm -f sizif.rom sizif.hex
