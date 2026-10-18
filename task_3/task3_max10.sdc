# FPGA input clock: 50 MHz.
create_clock -name MAX10_CLK1_50 -period 20.000 \
    [get_ports {MAX10_CLK1_50}]

derive_pll_clocks
derive_clock_uncertainty

# External SPI signals are asynchronous to the FPGA clock.
# Exclude only the paths into the FIRST synchronizer registers.
set sck_meta_regs [get_registers -nowarn {*|sck_meta}]
set cs_meta_regs  [get_registers -nowarn {*|cs_meta}]

# Stop if register names do not match the current design.
if {[get_collection_size $sck_meta_regs] != 1} {
    error "Expected exactly one sck_meta synchronizer register"
}
if {[get_collection_size $cs_meta_regs] != 1} {
    error "Expected exactly one cs_meta synchronizer register"
}

set_false_path -from [get_ports {SPI_SCK}] \
    -to $sck_meta_regs

set_false_path -from [get_ports {SPI_CS_N}] \
    -to $cs_meta_regs

# KEY0 enters the reset synchronizer in task3_max10_top.
set reset_sync_regs [get_registers -nowarn {reset_sync[*]}]

if {[get_collection_size $reset_sync_regs] != 2} {
    error "Expected two reset_sync registers in task3_max10_top"
}

set_false_path -from [get_ports {KEY0}] \
    -to $reset_sync_regs

# FPGA output delay budgets, in ns.
# Keep Arduino SPI at 1 MHz with the existing 2 us CS startup delay.
set_max_delay 100.000 -to [get_ports {SPI_MISO}]
set_min_delay   0.000 -to [get_ports {SPI_MISO}]

# READY is read as a level by the ESP32.
set_max_delay 100.000 -to [get_ports {BLOCK_READY}]
set_min_delay   0.000 -to [get_ports {BLOCK_READY}]

# Diagnostic outputs have no external synchronous receiver.
set_false_path -to [get_ports {LEDR[*] SAMPLE_TOGGLE}]