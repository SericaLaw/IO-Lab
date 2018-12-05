module Decoder (
        input A,
        input B,
        input C,
        input G1,
        input G2AN,
        input G2BN,
        output Y0N,
        output Y1N,
        output Y2N,
        output Y3N,
        output Y4N,
        output Y5N,
        output Y6N,
        output Y7N
        );
        integer i;
        reg [7:0] YN;
        wire[2:0] cba,G;
        assign cba = {C,B,A};
        assign G = {G1,G2AN,G2BN};
        assign Y0N = YN[0];
         ……//定义寄存器用作always块输出暂存，并将输出与之相对应
        always @(*)
        begin
           ……//填写38译码器
        end
endmodule