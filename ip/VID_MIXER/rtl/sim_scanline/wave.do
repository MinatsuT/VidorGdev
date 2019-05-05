onerror {resume}
quietly WaveActivateNextPane {} 0
add wave -noupdate /SCANLINE_tb/SCANLINE_inst/iPIX_CLK
add wave -noupdate /SCANLINE_tb/SCANLINE_inst/iPIX_RGB
add wave -noupdate /SCANLINE_tb/SCANLINE_inst/iPIX_WRITE
add wave -noupdate /SCANLINE_tb/SCANLINE_inst/iPIX_START
add wave -noupdate /SCANLINE_tb/SCANLINE_inst/oPIX_FULL
add wave -noupdate -color {Slate Blue} /SCANLINE_tb/SCANLINE_inst/iFB_CLK
add wave -noupdate /SCANLINE_tb/SCANLINE_inst/oFB_START
add wave -noupdate /SCANLINE_tb/SCANLINE_inst/oFB_RGB
add wave -noupdate /SCANLINE_tb/SCANLINE_inst/oFB_DATAVALID
add wave -noupdate /SCANLINE_tb/SCANLINE_inst/iFB_READY
add wave -noupdate /SCANLINE_tb/SCANLINE_inst/wWEN
add wave -noupdate -radix unsigned /SCANLINE_tb/SCANLINE_inst/wWADDR
add wave -noupdate -radix unsigned /SCANLINE_tb/SCANLINE_inst/rHEAD
add wave -noupdate -radix unsigned /SCANLINE_tb/SCANLINE_inst/rTAIL
add wave -noupdate -radix unsigned /SCANLINE_tb/SCANLINE_inst/wDAT_LEN
add wave -noupdate /SCANLINE_tb/SCANLINE_inst/wSCANLINE_START
add wave -noupdate /SCANLINE_tb/SCANLINE_inst/rSCANLINE_START_RESET
add wave -noupdate -radix unsigned /SCANLINE_tb/SCANLINE_inst/rSCANLINE_COL
add wave -noupdate -radix unsigned /SCANLINE_tb/SCANLINE_inst/wSCANLINE_IN_COL
add wave -noupdate /SCANLINE_tb/SCANLINE_inst/wSCANLINE_ODD
add wave -noupdate /SCANLINE_tb/SCANLINE_inst/rSCANLINE_ROW
add wave -noupdate -color Salmon -radix unsigned /SCANLINE_tb/SCANLINE_inst/rSCANLINE_RADDR
add wave -noupdate -radix unsigned /SCANLINE_tb/SCANLINE_inst/wRADDR
add wave -noupdate -color Salmon -radix unsigned /SCANLINE_tb/SCANLINE_inst/wSCANLINE_RGB
add wave -noupdate /SCANLINE_tb/SCANLINE_inst/rSCANLINE_START_0
add wave -noupdate -radix unsigned /SCANLINE_tb/SCANLINE_inst/rSCANLINE_RGB_0
add wave -noupdate /SCANLINE_tb/SCANLINE_inst/rSCANLINE_START_1
add wave -noupdate -color Gold /SCANLINE_tb/SCANLINE_inst/rSCANLINE_RGB_1
add wave -noupdate /SCANLINE_tb/SCANLINE_inst/wPIX2FB_WRFULL
add wave -noupdate -color Cyan /SCANLINE_tb/SCANLINE_inst/wPIX2FB_WRREQ
add wave -noupdate /SCANLINE_tb/SCANLINE_inst/wPIX2FB_RDEMPTY
add wave -noupdate /SCANLINE_tb/SCANLINE_inst/wPIX2FB_RDREQ
add wave -noupdate -color {Slate Blue} -radix unsigned /SCANLINE_tb/SCANLINE_inst/wPIX2FB_DATA
TreeUpdate [SetDefaultTree]
WaveRestoreCursors {{Cursor 1} {5200 ps} 0}
quietly wave cursor active 1
configure wave -namecolwidth 156
configure wave -valuecolwidth 69
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
WaveRestoreZoom {2712 ps} {7688 ps}
