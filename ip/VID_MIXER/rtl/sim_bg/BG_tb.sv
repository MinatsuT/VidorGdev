
`timescale 1ps / 1ps
module BG_tb ();
    logic clk = 1'b1;
    always begin
        #50 clk <= ~clk;
    end
    
    logic reset = 1;
    logic [2:0] addr = 0;
    logic [31:0] data = 0;
    logic write = 0;
    BG BG_inst (
    .iCLOCK(clk),
    .iRESET(reset),
    .iSX(sx),
    .iSY(sy),
    .iREG_ADDR(addr),
    .iREG_DATA(data),
    .iREG_WRITE(write)
    );
    
    task test_reg_write;
        forever begin 
            @(posedge clk);
            write <= ~write;
            if (write) begin
                addr <= addr+1;
                data <= addr+1;
            end
        end
    endtask
    
    initial begin
        #25 reset <= 0;
        #50 reset <= 1;
        #200 test_reg_write();
    end
endmodule
