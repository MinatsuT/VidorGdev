# setup variables for simulation script
set TOP_LEVEL_NAME   SCANLINE_tb
#set LIB              "-L altera_common_sv_packages -L altera_mf_ver"
set LIB              "-L altera_mf_ver"
set FLAGS            "-sv -y ../ +incdir+../+ +libext+.v+.sv+"
set SOURCES          ${TOP_LEVEL_NAME}.sv

if { [ file exists work ] != 1 } then {
   vlib work
}

# compile testbench and test program
eval vlog $FLAGS $SOURCES $LIB

# load and run simulation
eval vsim -msgmode both -displaymsgmode both $TOP_LEVEL_NAME $LIB
do wave.do
run 1us

# alias to re-compile changes made to test program, load and run simulation
alias rerun {
   eval vlog $FLAGS $SOURCES $LIB
   restart -force
   run 1us
}

