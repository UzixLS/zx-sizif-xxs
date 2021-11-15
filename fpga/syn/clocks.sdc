create_clock -period 28MHz -name {clk28} [get_ports {clk_in}]

create_generated_clock -name {clkcpu} -divide_by 2 -source [get_ports {clk_in}] [get_registers {cpucontrol:cpucontrol0|clkcpu}]
create_generated_clock -name {hc0[1]}  -divide_by 4 -source [get_ports {clk_in}] [get_registers {screen:screen0|hc0[1]}]

derive_pll_clocks
derive_clocks -period 14MHz

set_multicycle_path -from {vencode:*|*} -to {vencode:*|*} -setup 4
set_multicycle_path -from {vencode:*|*} -to {vencode:*|*} -hold 3
