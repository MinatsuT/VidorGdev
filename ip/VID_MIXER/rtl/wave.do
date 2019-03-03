onerror {resume}
quietly WaveActivateNextPane {} 0
add wave -noupdate /SCANLINE_tb/SCANLINE_inst/iPIX_CLK
add wave -noupdate -radix hexadecimal /SCANLINE_tb/SCANLINE_inst/iPIX_DATA
add wave -noupdate /SCANLINE_tb/SCANLINE_inst/iPIX_WRITE
add wave -noupdate /SCANLINE_tb/SCANLINE_inst/iPIX_START
add wave -noupdate /SCANLINE_tb/SCANLINE_inst/oPIX_FULL
add wave -noupdate /SCANLINE_tb/SCANLINE_inst/iFB_CLK
add wave -noupdate -radix decimal /SCANLINE_tb/SCANLINE_inst/oFB_DATA
add wave -noupdate /SCANLINE_tb/SCANLINE_inst/oFB_START
add wave -noupdate /SCANLINE_tb/SCANLINE_inst/iFB_READY
add wave -noupdate -radix hexadecimal /SCANLINE_tb/SCANLINE_inst/wRADDR
add wave -noupdate -radix hexadecimal /SCANLINE_tb/SCANLINE_inst/wWADDR
add wave -noupdate /SCANLINE_tb/SCANLINE_inst/wWEN
add wave -noupdate -radix decimal /SCANLINE_tb/SCANLINE_inst/wSCANLINE_DATA
add wave -noupdate -radix decimal /SCANLINE_tb/SCANLINE_inst/rTMP_DAT
add wave -noupdate -radix decimal /SCANLINE_tb/SCANLINE_inst/rFB_COUNT
add wave -noupdate -color Violet /SCANLINE_tb/SCANLINE_inst/wPIX2FB_WRFULL
add wave -noupdate -color Violet /SCANLINE_tb/SCANLINE_inst/wPIX2FB_WRREQ
add wave -noupdate -color Gold /SCANLINE_tb/SCANLINE_inst/wPIX2FB_RDEMPTY
add wave -noupdate -color Gold /SCANLINE_tb/SCANLINE_inst/wPIX2FB_RDREQ
add wave -noupdate /SCANLINE_tb/SCANLINE_inst/rPIX2FB_DATAVALID
add wave -noupdate /SCANLINE_tb/SCANLINE_inst/oFB_DATAVALID
add wave -noupdate -radix decimal /SCANLINE_tb/SCANLINE_inst/wPIX2FB_DATA
add wave -noupdate /SCANLINE_tb/SCANLINE_inst/rFB_START
TreeUpdate [SetDefaultTree]
WaveRestoreCursors {{Cursor 1} {63 ps} 0}
quietly wave cursor active 1
configure wave -namecolwidth 150
configure wave -valuecolwidth 44
configure wave -justifyvalue left
configure wave -signalnamewidth 1
configure wave -snapdistance 10
configure wave -datasetprefix 0
configure wave -rowmargin 4
configure wave -childrowmargin 2
configure wave -gridoffset 0
configure wave -gridperiod 1
configure wave -griddelta 40
configure wave -timeline 0
configure wave -timelineunits ps
update
WaveRestoreZoom {0 ps} {6188 ps}
