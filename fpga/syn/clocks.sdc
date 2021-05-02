create_clock -period 28MHz -name {clk28} [get_ports {clk_in}]

# clkcpu 3.5 or 7 MHz
create_generated_clock -name {clkcpu} -divide_by 4 -source [get_ports {clk_in}] [get_registers {cpucontrol:cpucontrol0|clkcpu}]

# hc0[2] 3.5 MHz
create_generated_clock -name {hc0_2} -divide_by 8 -source [get_ports {clk_in}] [get_registers {screen:screen0|hc0[2]}]

# hsync len 4.7uS, 14e6/(1/4.7e-6) ~= 65
create_generated_clock -name {hsync} -divide_by 126 -source [get_ports {clk_in}] [get_registers {screen:screen0|hsync}]

derive_pll_clocks
derive_clocks -period 14MHz