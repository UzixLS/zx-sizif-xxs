create_clock -period 28MHz -name {clk28} [get_ports {clk_in}]

create_generated_clock -name {clkcpu} -divide_by 2 -source [get_ports {clk_in}] [get_registers {cpucontrol:cpucontrol0|clkcpu}]
create_generated_clock -name {hc0[1]}  -divide_by 4 -source [get_ports {clk_in}] [get_registers {screen:screen0|hc0[1]}]

derive_pll_clocks
derive_clocks -period 14MHz

set_multicycle_path -from {vencode:*|*} -to {vencode:*|*} -setup 4
set_multicycle_path -from {vencode:*|*} -to {vencode:*|*} -hold 3

# One screen read cycle = ~71ns. SRAM speed = 55ns
# So we have about 16ns to setup control signals (n_vrd, n_vwr, va - 10ns) and read back data (vd - 6ns)
set_max_delay -from [get_pins -compatibility_mode screen0|*] -to [get_ports n_vrd] 10ns
set_max_delay -from [get_pins -compatibility_mode screen0|*] -to [get_ports n_vwr] 10ns
set_max_delay -from [get_pins -compatibility_mode screen0|*] -to [get_ports va[*]] 10ns
set_max_delay -from [get_ports vd[*]] -to [get_pins -compatibility_mode screen0|*] 6ns
