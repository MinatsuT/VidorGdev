# setup variables for simulation script
set TOP_LEVEL_NAME   SCANLINE_tb
#set LIB              "-L altera_common_sv_packages -L altera_mf_ver"
set LIB              "-L altera_mf_ver"

# compile testbench and test program
eval vlog -sv SCANLINE_tb.sv SCANLINE.sv ram_2port.v pix2fbfifo.v $LIB

# load and run simulation
eval vsim $TOP_LEVEL_NAME $LIB
do wave.do
run 50ns

# alias to re-compile changes made to test program, load and run simulation
alias rerun {
   eval vlog -sv SCANLINE_tb.sv SCANLINE.sv ram_2port.v pix2fbfifo.v $LIB
   restart -force
   run 50ns
}

