REV = A
REVISION = rev_${REV}

.PHONY: build sof2jic program_sof program_jic clean report

build:
	quartus_sh --no_banner --flow compile zx_ula -c ${REVISION}

sof2jic:
	cp -f "output/${REVISION}.sof" output/zx_ula.sof
	quartus_cpf -c sof2jic.cof
	mv output/zx_ula.jic "output/${REVISION}.jic"
	rm output/zx_ula.sof

program_sof:
	quartus_pgm --no_banner --mode=jtag -o "P;output/${REVISION}.sof"

program_jic:
	quartus_pgm --no_banner --mode=jtag -o "PVBI;output/${REVISION}.jic"

clean:
	rm -rf db incremental_db output

report:
	cat output/${REVISION}.*.smsg output/${REVISION}.*.rpt |grep -e Error -e Critical -e Warning |grep -v -e "Family doesn't support jitter analysis" -e "Force Fitter to Avoid Periphery Placement Warnings"

export PATH:=/opt/quartus13.0sp1/quartus/bin:/cygdrive/c/Hwdev/quartus130sp1/quartus/bin:${PATH}

-include Makefile.local
