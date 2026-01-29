set ::env(DESIGN_NAME) "uart_top"
set ::env(VERILOG_FILES) "    $::env(DESIGN_DIR)/uart_top.v     $::env(DESIGN_DIR)/uart_tx.v     $::env(DESIGN_DIR)/uart_rx.v"

set ::env(SYNTH_ENABLED) 1
set ::env(SYNTH_READ_BLACKBOX_LIB) 1
set ::env(CLOCK_PORT) "clk"
set ::env(CLOCK_PERIOD) "20.0"

set ::env(FP_PIN_ORDER_CFG) $::env(DESIGN_DIR)/pin_order.cfg

set ::env(FP_SIZING) "relative"
set ::env(FP_CORE_UTIL) 65
set ::env(FP_ASPECT_RATIO) 1
set ::env(PL_TARGET_DENSITY) 0.70
set ::env(CELL_PAD) 2

set ::env(VDD_NETS) [list {vccd1}]
set ::env(GND_NETS) [list {vssd1}]
set ::env(FP_PDN_CORE_RING) 1
set ::env(DESIGN_IS_CORE) 0

set ::env(PL_TIME_DRIVEN) 1
set ::env(QUIT_ON_TIMING_VIOLATIONS) 1
