`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
module S86_sim();
    reg clk;
    reg clkram;
    reg rst;    
    reg  [23:0] sw;
    wire [23:0] led;

    initial
    begin 
        clk = 0;
        clkram = 0;
        rst = 1;
        sw = 24'hffffff;
        #200 rst = 0;
    end

    always #50 clk = ~clk;
    always #25 clkram = ~clkram;
    
    S86_sys S86_sys(
                .CLK10MHZ(clk),
                .CLK20MHZ(clkram),
                .CPU_RESET(rst),
                //UART program downloader slave interface
                .PG_CLKIn(1'b0),
                .PG_RST(1'b1),
                .PG_WEN(2'b00),       
                .PG_DIN(16'h0000),       
                .PG_ADR(16'h0000),
                .PG_DONE(1'b1),   
                .IO_LED(led),
                .IO_Switch(sw)
                );

endmodule
