# TCL File Generated by Component Editor 18.1
# Tue Feb 05 03:23:26 JST 2019
# DO NOT MODIFY


# 
# GFX "GFX Hardware Accelerator" v1.0
# Minatsu Tukisima 2019.02.05.03:23:26
# GFX Hardware Accelerator
# 

# 
# request TCL package from ACDS 16.1
# 
package require -exact qsys 16.1


# 
# module GFX
# 
set_module_property DESCRIPTION ""
set_module_property NAME GFX
set_module_property VERSION 1.0
set_module_property INTERNAL false
set_module_property OPAQUE_ADDRESS_MAP true
set_module_property GROUP tukisima
set_module_property AUTHOR "Minatsu Tukisima"
set_module_property DISPLAY_NAME "GFX Hardware Accelerator"
set_module_property INSTANTIATE_IN_SYSTEM_MODULE true
set_module_property EDITABLE true
set_module_property REPORT_TO_TALKBACK false
set_module_property ALLOW_GREYBOX_GENERATION false
set_module_property REPORT_HIERARCHY false


# 
# file sets
# 
add_fileset QUARTUS_SYNTH QUARTUS_SYNTH "" ""
set_fileset_property QUARTUS_SYNTH TOP_LEVEL GFX
set_fileset_property QUARTUS_SYNTH ENABLE_RELATIVE_INCLUDE_PATHS false
set_fileset_property QUARTUS_SYNTH ENABLE_FILE_OVERWRITE_MODE false
add_fileset_file GFX.v VERILOG PATH GFX.v TOP_LEVEL_FILE


# 
# parameters
# 
add_parameter pFB_OFFSET INTEGER 614400
set_parameter_property pFB_OFFSET DEFAULT_VALUE 614400
set_parameter_property pFB_OFFSET DISPLAY_NAME pFB_OFFSET
set_parameter_property pFB_OFFSET TYPE INTEGER
set_parameter_property pFB_OFFSET UNITS None
set_parameter_property pFB_OFFSET HDL_PARAMETER true
add_parameter pFB_SIZE INTEGER 307200
set_parameter_property pFB_SIZE DEFAULT_VALUE 307200
set_parameter_property pFB_SIZE DISPLAY_NAME pFB_SIZE
set_parameter_property pFB_SIZE TYPE INTEGER
set_parameter_property pFB_SIZE UNITS None
set_parameter_property pFB_SIZE HDL_PARAMETER true
add_parameter pADDRESS_BITS INTEGER 22
set_parameter_property pADDRESS_BITS DEFAULT_VALUE 22
set_parameter_property pADDRESS_BITS DISPLAY_NAME pADDRESS_BITS
set_parameter_property pADDRESS_BITS TYPE INTEGER
set_parameter_property pADDRESS_BITS UNITS None
set_parameter_property pADDRESS_BITS HDL_PARAMETER true


# 
# display items
# 


# 
# connection point clock
# 
add_interface clock clock end
set_interface_property clock clockRate 0
set_interface_property clock ENABLED true
set_interface_property clock EXPORT_OF ""
set_interface_property clock PORT_NAME_MAP ""
set_interface_property clock CMSIS_SVD_VARIABLES ""
set_interface_property clock SVD_ADDRESS_GROUP ""

add_interface_port clock iCLOCK clk Input 1


# 
# connection point reset
# 
add_interface reset reset end
set_interface_property reset associatedClock clock
set_interface_property reset synchronousEdges DEASSERT
set_interface_property reset ENABLED true
set_interface_property reset EXPORT_OF ""
set_interface_property reset PORT_NAME_MAP ""
set_interface_property reset CMSIS_SVD_VARIABLES ""
set_interface_property reset SVD_ADDRESS_GROUP ""

add_interface_port reset iRESET reset Input 1


# 
# connection point AVL
# 
add_interface AVL avalon end
set_interface_property AVL addressUnits WORDS
set_interface_property AVL associatedClock clock
set_interface_property AVL associatedReset reset
set_interface_property AVL bitsPerSymbol 8
set_interface_property AVL bridgedAddressOffset 0
set_interface_property AVL burstOnBurstBoundariesOnly false
set_interface_property AVL burstcountUnits WORDS
set_interface_property AVL explicitAddressSpan 0
set_interface_property AVL holdTime 0
set_interface_property AVL linewrapBursts false
set_interface_property AVL maximumPendingReadTransactions 0
set_interface_property AVL maximumPendingWriteTransactions 0
set_interface_property AVL readLatency 0
set_interface_property AVL readWaitTime 1
set_interface_property AVL setupTime 0
set_interface_property AVL timingUnits Cycles
set_interface_property AVL writeWaitTime 0
set_interface_property AVL ENABLED true
set_interface_property AVL EXPORT_OF ""
set_interface_property AVL PORT_NAME_MAP ""
set_interface_property AVL CMSIS_SVD_VARIABLES ""
set_interface_property AVL SVD_ADDRESS_GROUP ""

add_interface_port AVL iAVL_ADDRESS address Input 8
add_interface_port AVL iAVL_READ read Input 1
add_interface_port AVL oAVL_READ_DATA readdata Output 32
add_interface_port AVL iAVL_WRITE write Input 1
add_interface_port AVL iAVL_WRITE_DATA writedata Input 32
add_interface_port AVL oAVL_WAIT_REQUEST waitrequest Output 1
set_interface_assignment AVL embeddedsw.configuration.isFlash 0
set_interface_assignment AVL embeddedsw.configuration.isMemoryDevice 0
set_interface_assignment AVL embeddedsw.configuration.isNonVolatileStorage 0
set_interface_assignment AVL embeddedsw.configuration.isPrintableDevice 0


# 
# connection point SDRAM
# 
add_interface SDRAM avalon start
set_interface_property SDRAM addressUnits WORDS
set_interface_property SDRAM associatedClock clock
set_interface_property SDRAM associatedReset reset
set_interface_property SDRAM bitsPerSymbol 8
set_interface_property SDRAM burstOnBurstBoundariesOnly false
set_interface_property SDRAM burstcountUnits WORDS
set_interface_property SDRAM doStreamReads false
set_interface_property SDRAM doStreamWrites false
set_interface_property SDRAM holdTime 0
set_interface_property SDRAM linewrapBursts false
set_interface_property SDRAM maximumPendingReadTransactions 0
set_interface_property SDRAM maximumPendingWriteTransactions 0
set_interface_property SDRAM readLatency 0
set_interface_property SDRAM readWaitTime 1
set_interface_property SDRAM setupTime 0
set_interface_property SDRAM timingUnits Cycles
set_interface_property SDRAM writeWaitTime 0
set_interface_property SDRAM ENABLED true
set_interface_property SDRAM EXPORT_OF ""
set_interface_property SDRAM PORT_NAME_MAP ""
set_interface_property SDRAM CMSIS_SVD_VARIABLES ""
set_interface_property SDRAM SVD_ADDRESS_GROUP ""

add_interface_port SDRAM oSDRAM_ADDRESS address Output pADDRESS_BITS
add_interface_port SDRAM oSDRAM_READ read Output 1
add_interface_port SDRAM iSDRAM_WAIT_REQUEST waitrequest Input 1
add_interface_port SDRAM iSDRAM_READ_DATA readdata Input 16
add_interface_port SDRAM oSDRAM_WRITE write Output 1
add_interface_port SDRAM oSDRAM_WRITE_DATA writedata Output 16
add_interface_port SDRAM iSDRAM_READ_DATA_VALID readdatavalid Input 1

