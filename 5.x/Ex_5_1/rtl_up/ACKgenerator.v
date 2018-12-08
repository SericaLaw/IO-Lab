`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
module ACKgenerator(
    input MEMACK,
    input IOCS0_N,
    input IOCS1_N,
    output ACK
    );
    
    assign ACK = MEMACK | (!IOCS0_N) | (!IOCS1_N);
 
endmodule
