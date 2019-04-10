onerror {exit -code 1}
vlib work
vlog -work work rtype.vo
vlog -work work Waveform6.vwf.vt
vsim -novopt -c -t 1ps -L cycloneive_ver -L altera_ver -L altera_mf_ver -L 220model_ver -L sgate work.rtype_vlg_vec_tst -voptargs="+acc"
vcd file -direction rtype.msim.vcd
vcd add -internal rtype_vlg_vec_tst/*
vcd add -internal rtype_vlg_vec_tst/i1/*
run -all
quit -f
