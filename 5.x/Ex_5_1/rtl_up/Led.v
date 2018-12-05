`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
module Led(
    // Wishbone slave interface
    input         wb_clk_i,
    input         wb_rst_i,
    input  [15:0] wb_dat_i,
    input         wb_adr_i,
    input         IOW_N,
    input         CS_N,
    output reg [23:0] ledout
    );
    always @ (posedge wb_clk_i or posedge wb_rst_i) begin
        if(wb_rst_i) begin
            ledout <= 0;
        end else if ((!CS_N)&(!IOW_N)&(!wb_adr_i)) begin
            ledout[15:0] <= wb_dat_i;
        end else if((!CS_N)&(!IOW_N)&(wb_adr_i)) begin
            ledout[23:16] <= wb_dat_i[7:0];
        end
    end

endmodule
