export PATH:=/opt/modelsim201/modelsim_ase/bin:/cygdrive/c/Hwdev/modelsim181/modelsim_ase/win32aloem:/cygdrive/c/Hwdev/iverilog/bin/:/cygdrive/c/Hwdev/sjasmplus/:/cygdrive/c/Dev/srec/:${PATH}
V_AZ80=$(wildcard ./az80/*.v)
V_T80=./t80/t80n_pack.vhd ./t80/t80n.vhd ./t80/t80n_alu.vhd ./t80/t80n_mcode.vhd ./t80/t80na.vhd

all: testbench_zx_ula

testbench_zx_ula: IVFLAGS+=-I./az80/ -I./t80/ -I../rtl/
testbench_zx_ula: V=$@.v ${V_T80} $(wildcard stubs/*.v) $(wildcard ../rtl/*.vhd) $(wildcard ../rtl/*.v) ../rtl/common.sv $(wildcard ../rtl/*.sv)
testbench_zx_ula: rom.mem

xtestbench_%:
	iverilog -g2005-sv ${IVFLAGS} -o $@.vvp ${V}
	vvp $@.vvp
	@rm $@.vvp

testbench_%:
	test ! -d work || rm -rf work
	vlib work
	test ! -n "$(filter %.v %.sv,${V})" || vlog -quiet -sv $(filter %.v %sv,${V})
	test ! -n "$(filter %.vhd %.vhdl,${V})" || vcom -quiet $(filter %.vhd %.vhdl,${V})
	vsim ${VSIMFLAGS} -batch -quiet -do 'run -all' $@
	test ! -r transcript || rm transcript

%.bin: %.asm
	sjasmplus $<
%.mem: %.bin
	srec_cat $< -binary -o $@ -vmem 8

clean:
	rm -rf ivl_vhdl_work/ work/ *.bin *.mem *.vcd

-include Makefile.local
