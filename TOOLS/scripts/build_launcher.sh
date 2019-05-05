# (C) 2001-2018 Intel Corporation. All rights reserved.
# Your use of Intel Corporation's design tools, logic functions and other
# software and tools, and its AMPP partner logic functions, and any output
# files from any of the foregoing (including device programming or simulation
# files), and any associated documentation or information are expressly subject
# to the terms and conditions of the Intel Program License Subscription
# Agreement, Intel FPGA IP License Agreement, or other applicable
# license agreement, including, without limitation, that your use is for the
# sole purpose of programming logic devices manufactured by Intel and sold by
# Intel or its authorized distributors.  Please refer to the applicable
# agreement for further details.



# *********************************************************************
# Description
#
# Script for compiling the DisplayPort Example Design software
#
# *********************************************************************

if [ `quartus_sh --version | grep Lite | wc -l` == "1" ]; then
# compile for lite version
if [ -z $FORCE_FULL ]; then
LITE="_lite"
fi
fi

PROJECT_BSP_NAME=${PWD##*/}
PROJECT_NAME=launcher
# Location where BSP is built
BSP_DIR="./build/software/"$PROJECT_NAME$LITE"_bsp"

# Location where the application is built
APP_DIR=./build/software/launcher

# SOPC file definitions
SOPC_INFO="./build/"$PROJECT_BSP_NAME$LITE"_sys.sopcinfo"

# Various
ELF_NAME=$PROJECT_NAME$LITE.elf
OPTIMIZATION_LEVEL="-Os"
LDFLAGS_USER="-Wl,-gc-sections"
APP_FLAGS="--set APP_CFLAGS_OPTIMIZATION $OPTIMIZATION_LEVEL --set APP_LDFLAGS_USER $LDFLAGS_USER"

if [ -f scripts/bsp_settings_launcher.sh ]; then
echo "##########################################"
echo "#        using local bsp settings        #"
echo "##########################################"
source scripts/bsp_settings_launcher.sh
else
# BSP options
SIMULATION_OPTIMIZED_SUPPORT="false"
BSP_TYPE=hal
BSP_FLAGS=" \
--cmd enable_sw_package CFG \
--cmd enable_sw_package SF \
--cmd enable_sw_package AES \
--cmd enable_sw_package SIGN \
--cmd enable_sw_package MAILBOX \
--cmd enable_sw_package RPC \
--set hal.make.bsp_cflags_defined_symbols -DNO_RPC=1 \
--set hal.enable_c_plus_plus 0 \
--set hal.enable_clean_exit 0 \
--set hal.enable_exit 0 \
--set hal.enable_gprof 0 \
--set hal.enable_lightweight_device_driver_api 1 \
--set hal.enable_mul_div_emulation 0 \
--set hal.enable_reduced_device_drivers 1 \
--set hal.enable_runtime_stack_checking 0 \
--set hal.enable_sim_optimize 0 \
--set hal.enable_small_c_library 1 \
--set hal.enable_sopc_sysid_check 1 \
--set hal.enable_sim_optimize $SIMULATION_OPTIMIZED_SUPPORT \
--set hal.make.bsp_cflags_optimization $OPTIMIZATION_LEVEL \
--set hal.linker.allow_code_at_reset 1 \
--set hal.linker.enable_alt_load 0 \
--set hal.linker.enable_alt_load_copy_exceptions 0 \
--set hal.linker.enable_alt_load_copy_rodata 0 \
--set hal.linker.enable_alt_load_copy_rwdata 1 \
--set hal.linker.enable_exception_stack 0 \
--set hal.linker.enable_interrupt_stack 0 \
--set hal.linker.exception_stack_memory_region_name $SOPC_CODE_MEMORY_NAME \
--set hal.linker.interrupt_stack_memory_region_name $SOPC_CODE_MEMORY_NAME \
--set hal.make.ignore_system_derived.big_endian 0 \
--set hal.make.ignore_system_derived.debug_core_present 0 \
--set hal.make.ignore_system_derived.fpu_present 0 \
--set hal.make.ignore_system_derived.hardware_divide_present 0 \
--set hal.make.ignore_system_derived.hardware_fp_cust_inst_divider_present 0 \
--set hal.make.ignore_system_derived.hardware_fp_cust_inst_no_divider_present 0 \
--set hal.make.ignore_system_derived.hardware_multiplier_present 0 \
--set hal.make.ignore_system_derived.hardware_mulx_present 0 \
--set hal.make.ignore_system_derived.sopc_simulation_enabled 0 \
--set hal.make.ignore_system_derived.sopc_system_base_address 0 \
--set hal.make.ignore_system_derived.sopc_system_id 0 \
--set hal.make.ignore_system_derived.sopc_system_timestamp 0 \
--set hal.max_file_descriptors 4 \
--set hal.stderr none \
--set hal.stdin none \
--set hal.stdout none \
--set hal.sys_clk_timer none \
--script scripts/set_regions.tcl \
--cmd set_driver none remote_update_0 \
--cmd set_driver arduino_generic_quad_spi_controller2 qspi \
--cmd set_driver none arduino_16500_uart \
--cmd set_driver none nina_uart \
--cmd add_section_mapping .rwdata onchip_memory2_0 \
--cmd add_section_mapping .bss onchip_memory2_0 \
--cmd add_section_mapping .heap onchip_memory2_0 \
--cmd add_section_mapping .entry onchip_memory2_0 \
--cmd add_section_mapping .text onchip_memory2_0 \
--cmd add_section_mapping .rodata onchip_memory2_0 \
--cmd add_section_mapping .data onchip_memory2_0 \
--cmd add_section_mapping .stack onchip_memory2_0 \
"
if [ "x"$LITE == "x" ]; then
EXTRA_FLAGS=" \
--set altera_vic_driver.linker_section .rwdata \
--cmd enable_sw_package UART \
"
else
EXTRA_FLAGS="\
--set hal.make.bsp_cflags_user_flags \
-DFREE_VERSION=1 \
"
fi

fi



mkdir -p $APP_DIR

# copy common files
if [ -d software/softcore_launcher ]; then
cp -f software/softcore_launcher/* $APP_DIR
else
cp -f ../../ip/LAUNCHER/softcore/launcher.c $APP_DIR
fi
# generate the BSP in the $BSP_DIR
cmd="nios2-bsp $BSP_TYPE $BSP_DIR $SOPC_INFO $BSP_FLAGS $EXTRA_FLAGS"
$cmd || {
  echo "nios2-bsp failed"
}

# generate the application make file in the $APP_DIR
cmd="nios2-app-generate-makefile --app-dir $APP_DIR --bsp-dir $BSP_DIR --elf-name $ELF_NAME --src-rdir $APP_DIR \
$APP_FLAGS "
$cmd || {
  echo "nios2-app-generate-makefile failed"
#  exit 1
}

# Running make (for application, memory initialization files and the bsp due to dependencies)
cmd="make mem_init_generate --directory=$APP_DIR"
$cmd || {
    echo "make failed"
}

