vlib work

vdel -all
vlib work

vlog cache_specs.sv
vlog cache.sv 
vlog cache_statistics.sv 
vlog TB.sv


vsim -Gtrace_file=CPUREAD.txt work.TB; run -all 