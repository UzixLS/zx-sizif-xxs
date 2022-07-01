OUTDIR=out_new
REV=B

.PHONY: all build_rev clean pipeline pipeline_sof

all:
	mkdir -p ${OUTDIR}/
	${MAKE} REV=A build_rev
	${MAKE} REV=B build_rev
	${MAKE} REV=zero_A build_rev

build_rev:
	${MAKE} REV=${REV} -C rom_src/ clean all
	${MAKE} REV=${REV} -C rom/ clean all
	${MAKE} REV=${REV} -C fpga/syn/ clean build sof2jic
	cp fpga/syn/output/rev_${REV}.jic ${OUTDIR}/rev_${REV}.jic

clean:
	rm -f "${OUTDIR}"
	${MAKE} -C fpga/syn/ clean
	${MAKE} -C fpga/tb/ clean
	${MAKE} -C rom_src/ clean
	${MAKE} -C rom/ clean

pipeline:
	${MAKE} REV=${REV} -C rom_src/
	${MAKE} REV=${REV} -C rom/
	${MAKE} REV=${REV} -C fpga/syn/ build report sof2jic program_jic program_sof

pipeline_sof:
	${MAKE} REV=${REV} -C rom_src/
	${MAKE} REV=${REV} -C fpga/syn/ build report program_sof

-include Makefile.local
