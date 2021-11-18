OUTDIR=out_new

all:
	mkdir -p ${OUTDIR}/
	${MAKE} build_rev REV=A

build_rev:
	${MAKE} -C rom_src/ REV=${REV} clean all
	${MAKE} -C rom/ REV=${REV} clean all
	${MAKE} -C fpga/syn/ REVISION=rev_${REV} clean build sof2jic
	cp fpga/syn/output/rev_${REV}.jic ${OUTDIR}/rev_${REV}.jic

clean:
	rm -f "${OUTDIR}"
	${MAKE} -C fpga/syn/ clean
	${MAKE} -C fpga/tb/ clean
	${MAKE} -C rom_src/ clean
	${MAKE} -C rom/ clean
