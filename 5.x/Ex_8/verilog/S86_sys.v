`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
module S86_sys (
    input         CLK10MHZ,
    input         CLK20MHZ,
    input         CPU_RESET,
	//UART program downloader slave interface
    input         PG_CLKIn,
    input         PG_RST,
    input         PG_WEN,       
    input  [15:0] PG_DIN,       
    input  [15:0] PG_ADR,
    input         PG_DONE,
    //IO
    output [23:0] IO_LED,//led    
    input  [23:0] IO_Switch,//switch
    //segs
    output [7:0] IO_AN, //digit
    output [7:0] IO_SEG,
    //buzzzer
    output IO_Buzzer,
    //keypad
    input   [3:0] IO_ROW,
    output  [3:0] IO_COL
 );

    //WB总线
    wire [15:0] dat_o;
    wire [15:0] dat_i;
    wire [19:1] adr;
    wire [1:0]  sel;
    wire we, tga, stb, cyc, ack;
    //读写发生器:ior/iow/memw/memr     
    wire ior_n, iow_n, memw_n, memr_n; 
    //地址译码器
    wire swcsn, digitcsn, s8254csn, buzzercsn, keypadcsn; 
    //RAM
    wire [15:0] mem_dat_i;
    wire        memack;
    //switch
    wire [15:0] switch_out;
    //S8254
    wire [7:0] s8254out;
    //Keypad
    wire [15:0] keypad_out;
 
    //S86 processor
    S86_0 S86_proc (
        //Wishbone master interface
        .wb_clk_i (CLK10MHZ),
        .wb_rst_i (CPU_RESET),
        .wb_dat_i (dat_i),
        .wb_dat_o (dat_o),
        .wb_adr_o (adr),
        .wb_we_o  (we),
        .wb_sel_o (sel),
        .wb_tga_o (tga),
        .wb_stb_o (stb),
        .wb_cyc_o (cyc),
        .wb_ack_i (ack),
        .wb_tgc_i (1'b0),
        .nmi(1'b0)
    );
 
    //读写信号发生器     
    WRgenerator U0 (
        .wb_tga_i(tga),
        .wb_we_i(we),
        .wb_cyc_i(cyc),
        .wb_stb_i(stb),
        .IOR_N(ior_n),
        .IOW_N(iow_n),
        .MEMW_N(memw_n),
        .MEMR_N(memr_n)
    );  
 
    //地址译码器
    Decoder_0 U1(
        .A(adr[4]),                                                   
        .B(adr[5]),                                                  
        .C(adr[6]),                                                  
        .G1(!adr[9]),                                                
        .G2AN(ior_n & iow_n),                                         
        .G2BN(adr[7] | adr[8]),                                                 
        .Y1N(swcsn),
        .Y2N(digitcsn),
        .Y3N(keypadcsn),              
        .Y4N(s8254csn),
        .Y6N(buzzercsn)                                                          
    );
    
    //输入数据多路选择器
    Muxdati U2(
        .wb_tga_i(tga),
        .RDN(ior_n & memr_n),
        .MEMDATI(mem_dat_i),
        .IOCS0_N(swcsn),
        .IODAT0I(switch_out),
        .IOCS1_N(s8254csn),
        .IODAT1I({8'h00,s8254out}),
        .IOCS2_N(keypadcsn),
        .IODAT2I(keypad_out),
        .DATO(dat_i)
    );
    
    //应答信号发生器
    ACKgenerator U3( 
        .MEMACK(memack),
        .IOCS0_N(swcsn),
        .IOCS1_N(digitcsn),
        .IOCS2_N(s8254csn),
        .IOCS3_N(buzzercsn),
        .IOCS4_N(keypadcsn),
        .ACK(ack)
    );
    
    //内存控制器
    RAM_BIOS M0(
	   //UART program downloader slave interface
        .pg_clk_i(PG_CLKIn),                 
        .pg_rst_i(PG_RST),               
        .pg_wen(PG_WEN),                   
        .pg_din(PG_DIN),                 
        .pg_adr(PG_ADR),                  
        .pg_done(PG_DONE),  
        // Wishbone slave interface
        .wb_clk_i (CLK20MHZ),       
        .wb_dat_o (mem_dat_i),
        .wb_dat_i (dat_o),
        .wb_adr_i (adr),
        .wb_sel_i (sel),
        .wb_ack_o (memack),   
        .MEMW_N (memw_n),
        .MEMR_N (memr_n)
    );
    
    //SW
    Switch D0(
         .wb_dat_o(switch_out),
         .wb_adr_i(adr[1]),
         .IOR_N(ior_n),
         .CS_N(swcsn),
         .switch_i(IO_Switch)
    );      
    
    //Digit
    Digit_0 D1(
        .wb_clk_i(CLK10MHZ),
        .wb_rst_i(CPU_RESET), 
        .wb_dat_i(dat_o),
        .wb_adr_i(adr[2:1]),
        .IOW_N(iow_n),
        .CS_N(digitcsn),
        .an(IO_AN),
        .segs(IO_SEG)
    );
    
    //定时计数器
    wire out0;
    S_8254 D2(    
        .clk0(CLK10MHZ),  //Counter0输入时钟
        .gate0(1'b1),    //Counter0使能
        .out0(out0),     //Counter0输出波形
        .a(adr[2:1]),    //地址线
        .id(dat_o[7:0]), //输入数据
        .od(s8254out),   //输出数据
        .CS_N(s8254csn), //片选
        .IOR_N(ior_n),   //读信号
        .IOW_N(iow_n)    //写信号
    );      
    
    //并行口扩展
    Buzzer D3(
        .clk_in(out0), //蜂鸣器输入时钟
        .CS_N(buzzercsn),
        .IOW_N(iow_n),
        .din(dat_o[7:0]),
        .buzzer(IO_Buzzer)
    );    
    
    //4X4键盘    
    Keypad D4(
        .wb_clk_i(CLK10MHZ),
        .wb_rst_i(CPU_RESET),
        .wb_dat_o(keypad_out),
        .IOR_N(ior_n),
        .CS_N(keypadcsn),
        .row(IO_ROW),
        .col(IO_COL)
    );
        
endmodule
