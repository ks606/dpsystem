transcript on
vlib work

vlog -v +incdir+./ ./dpsystem_top.v
vlog -v +incdir+./ ./dpsystem_top_tb.v
vlog -v +incdir+./ ./fifo_1clk.v
vlog -v +incdir+./ ./fifo_1clk_tb.v
vsim -t 1ns -voptargs="+acc" dpsystem_top_tb

add wave /dpsystem_top_tb/Clock
add wave /dpsystem_top_tb/nReset
add wave /dpsystem_top_tb/CycleStart
add wave -radix Decimal /dpsystem_top_tb/WindowDelay
add wave -radix Decimal /dpsystem_top_tb/WindowSizePow
add wave -radix Decimal /dpsystem_top_tb/data_in
add wave -radix Decimal /dpsystem_top_tb/SampleData
add wave -radix Decimal /dpsystem_top_tb/dpsystem/CycleNumber
add wave -radix Decimal /dpsystem_top_tb/dpsystem/sample_cnt
add wave -radix Decimal /dpsystem_top_tb/dpsystem/winsize
add wave -radix Decimal /dpsystem_top_tb/dpsystem/delay_cnt
add wave -radix Decimal /dpsystem_top_tb/dpsystem/ZeroOffset
add wave -radix Decimal /dpsystem_top_tb/dpsystem/MaxAmpl
add wave -radix Decimal /dpsystem_top_tb/dpsystem/MaxTime
add wave /dpsystem_top_tb/dpsystem/WriteEna
add wave -radix Hexadecimal /dpsystem_top_tb/dpsystem/WriteData
add wave /dpsystem_top_tb/ReadEna
add wave -radix Hexadecimal /dpsystem_top_tb/ReadData
add wave /dpsystem_top_tb/FifoState_empty
add wave /dpsystem_top_tb/FifoState_full

run

wave zoom full

