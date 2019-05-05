//
// I2C Bridge
// Author: minatsu
//

module I2C_BRIDGE (
    input  iCLK,
    input  iSCL_MASTER,
    output oSCL_SLAVE,
    inout  bPORT_A,
    inout  bPORT_B
    );
    assign oSCL_SLAVE = iSCL_MASTER;
    
    logic rACTIVE = 1'b0; // During port A or B is externally pulled, it is active.
    logic rACTIVE_PORT; // externally pulled port: 1=A, 0=B
    
    // When port A or B is externally pulled LOW, pull the other port.
    // Otherwise keep Hi-Z.
    assign bPORT_A = (rACTIVE & rACTIVE_PORT==1'b0 & !bPORT_B) ? 1'b0 : 1'bZ;
    assign bPORT_B = (rACTIVE & rACTIVE_PORT==1'b1 & !bPORT_A) ? 1'b0 : 1'bZ;
    
    logic [3:0] rDEAD_COUNT = 1'b0;
    
    always_ff @(posedge iCLK) begin
        if (rDEAD_COUNT) begin
            rDEAD_COUNT <= rDEAD_COUNT - 1'b1;
        end
        
        if (!rACTIVE) begin // Now IDLE
            if (!rDEAD_COUNT & (!bPORT_A ^ !bPORT_B)) begin
                rACTIVE <= 1'b1; // Transit to ACTIVE.
                rACTIVE_PORT <= (!bPORT_A) ? 1'b1 : 1'b0; // Remember pulled port.
            end
        end else begin // Now ACTIVE
            if ((rACTIVE_PORT==1'b1 & bPORT_A) | (rACTIVE_PORT==1'b0 & bPORT_B)) begin
                rACTIVE <= 1'b0; // Transig to IDLE.
                rDEAD_COUNT <= 4'd15;
            end
        end
    end
    
endmodule
