onerror {resume}
quietly WaveActivateNextPane {} 0
add wave -noupdate /BG_tb/BG_inst/pPCG_ADDR
add wave -noupdate /BG_tb/BG_inst/pSCREEN_ADDR
add wave -noupdate /BG_tb/BG_inst/pSCREEN_W
add wave -noupdate /BG_tb/BG_inst/pSCREEN_H
add wave -noupdate /BG_tb/BG_inst/pCHR_W
add wave -noupdate /BG_tb/BG_inst/pCHR_H
add wave -noupdate /BG_tb/BG_inst/pPCG_W
add wave -noupdate /BG_tb/BG_inst/pPCG_H
add wave -noupdate /BG_tb/BG_inst/iCLOCK
add wave -noupdate /BG_tb/BG_inst/iRESET
add wave -noupdate /BG_tb/BG_inst/iSX
add wave -noupdate /BG_tb/BG_inst/iSY
add wave -noupdate /BG_tb/BG_inst/iREG_ADDR
add wave -noupdate /BG_tb/BG_inst/iREG_DATA
add wave -noupdate /BG_tb/BG_inst/iREG_WRITE
add wave -noupdate -expand /BG_tb/BG_inst/rO
add wave -noupdate -expand /BG_tb/BG_inst/rU
add wave -noupdate -expand /BG_tb/BG_inst/rV
add wave -noupdate /BG_tb/BG_inst/eCOMMAND
add wave -noupdate /BG_tb/addr
add wave -noupdate /BG_tb/data
add wave -noupdate /BG_tb/write
TreeUpdate [SetDefaultTree]
WaveRestoreCursors {{Cursor 1} {245 ps} 0}
quietly wave cursor active 1
configure wave -namecolwidth 156
configure wave -valuecolwidth 128
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
WaveRestoreZoom {0 ps} {1780 ps}
