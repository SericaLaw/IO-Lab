`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
module S86SoC(
    input         CLK100MHZ,
    input         BTN_RESET,
    // UART program
    input         BTNU,
    input         UART_RX,
    output        UART_TX,        
    //led
    output [23:0] LED,
    //switch
    input  [23:0] SW
    );
    
    //clk
    wire clk, clkram;
    //rst
    wire lock, rst;
	//UART program downloader slave interface
    wire pg_clk, pg_rst, pg_wen, pg_done;
    wire [15:0] pg_dat;
    wire [15:0] pg_adr;
     
   // wire upg_rst;
    //clk  
    pll CLOCK(.clk_in1 (CLK100MHZ), .clk_out1(clk),.clk_out2(clkram),.locked (lock));
    
    //reset
    reset RESET(.lock(lock),
                .btnreset(BTN_RESET),
                .reset(rst),
                .btnu(BTNU),
                .upg_rst(pg_rst)
                ); 
     
    //S86 system
    S86_sys S86_sys(
    .CLK10MHZ(clk & pg_rst),
    .CLK20MHZ(clkram),
    .CPU_RESET(rst),
	//UART program downloader slave interface
	.PG_CLKIn(pg_clk),
    .PG_RST(pg_rst),
    .PG_WEN(pg_wen),       
    .PG_DIN(pg_dat),       
    .PG_ADR(pg_adr),
    .PG_DONE(pg_done),    
    //IO
    .IO_LED(LED),//led    
    .IO_Switch(SW)//switch    
    );
    
    uart_bmpg_16bit_0 uart_bmpg_inst (
            .upg_clk_i        (clk),          // 10MHz
            .upg_rst_i        (pg_rst),      // High active
            // blkmem signals
            .upg_clk_o        (pg_clk),
            .upg_wen_o        (pg_wen),
            .upg_adr_o        (pg_adr),
            .upg_dat_o        (pg_dat),
            .upg_done_o        (pg_done),
            // uart signals
            .upg_rx_i        (UART_RX),
            .upg_tx_o        (UART_TX)
        );

    
    
   
    
endmodule
