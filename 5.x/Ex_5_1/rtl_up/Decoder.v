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
        assign Y1N = YN[1];
        assign Y2N = YN[2];
        assign Y3N = YN[3];
        assign Y4N = YN[4];
        assign Y5N = YN[5];
        assign Y6N = YN[6];
        assign Y7N = YN[7];
        always @(A or B or C or G1 or G2AN or G2BN)
            begin
                YN = 8'b11111111;
                if(G==3'b100)   YN[cba] = 0;
            end
endmodule