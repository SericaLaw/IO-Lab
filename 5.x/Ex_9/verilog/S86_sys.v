`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
module S86_sys (
    input         CLK10MHZ,
    input         CLK20MHZ,
    input         
    CPU_RESET,
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
    output [7:0] IO_SEG
 );

    //WB总线
    wire [15:0] dat_o;
    wire [15:0] dat_i;
    wire [19:1] adr;
    wire [1:0]  sel;
    wire we, tga, stb, cyc, ack, intr, inta;
    //读写发生器:ior/iow/memw/memr     
    wire ior_n, iow_n, memw_n, memr_n; 
    //地址译码器
    wire piccsn, s8254csn, s8255csn; 
    //RAM
    wire [15:0] mem_dat_i;
    wire        memack;
    //PIC
    wire [7:0] picout;
    //S8254
    wire clk0;
    wire gate0;
    wire out0;
    wire clk1;
    wire gate1;
    wire out1;
    wire clk2;
    wire gate2;
    wire out2;
    wire [7:0] s8254out;
    //S8255
    wire [7:0] s8255out;
 
    //S86 processor
    S86_0 S86_proc (
        //Wishbone master interface
        .wb_clk_i (CLK10MHZ),
        .wb_rst_i (CPU_RESET),
        .wb_dat_i (dat_i),
        .wb_dat_o (dat_o),
        .wb_adr_o (adr),
        .wb_we_o  (we),
        .wb_tga_o (tga),
        .wb_sel_o (sel),
        .wb_stb_o (stb),
        .wb_cyc_o (cyc),
        .wb_ack_i (ack),
        .wb_tgc_i (intr),
        .wb_tgc_o (inta),
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
    Decoder U1(
        .A(adr[4]),
        .B(adr[5]),
        .C(adr[6]),
        .G1(!adr[9]),                                                
        .G2AN(ior_n & iow_n),     
        .G2BN(adr[7] | adr[8]),
        .Y4N(s8254csn),
        .Y5N(piccsn),
        .Y6N(s8255csn)
    );
    
    //输入数据多路选择器
    Muxdati U2(
        .wb_tga_i(tga),
        .RDN(ior_n & memr_n),
        .INTA_N(!inta),//加入PIC时，需要加入
        .MEMDATI(mem_dat_i),
        .IOCS0_N(piccsn),
        .IODAT0I({8'h00,picout}),
        .IOCS1_N(s8254csn),
        .IODAT1I({8'h00,s8254out}),
        .IOCS2_N(s8255csn),
        .IODAT2I({8'h00,s8255out}),
        .DATO(dat_i)
    );
    
    //应答信号发生器
    ACKgenerator U3( 
        .MEMACK(memack),
        .IOCS0_N(piccsn),
        .IOCS1_N(s8254csn),
        .IOCS2_N(s8255csn),
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
    
    //PIC
    wire [7:0] ir;
    assign ir = {7'b0000000, out1};    //自行定义使用PIC中IR0~IR7中的哪个引脚：注意，所编写的程序要与之对应
    PIC_0 D0(
        .RESET(!PG_RST),
        .INTA_N(!inta),
        .A(adr[1]),
        .IR(ir),
        .DB_I(dat_o[7:0]),
        .INT(intr),
        .DB_O(picout),
        .CS_N(piccsn),
        .IOR_N(ior_n),
        .IOW_N(iow_n)
    );
    
    //8254
    S_8254_0 D1(    
        .clk0(clk0),             // Counter0输入时钟
        .gate0(gate0),         // Counter0使能
        .out0(out0),             // Counter0输出波形
        .clk1(clk1),             // Counter1输入时钟
        .gate1(gate1),         // Counter1使能
        .out1(out1),             // Counter1输出波形
        .clk2(clk2),             // Counter2输入时钟
        .gate2(gate2),         // Counter2使能
        .out2(out2),             // Counter2输出波形                
        .a(adr[2:1]),             // 地址线
        .id(dat_o[7:0]),         // 输入数据
        .od(s8254out),   // 输出数据
        .CS_N(s8254csn),        // 片选
        .IOR_N(ior_n),        // 读信号
        .IOW_N(iow_n)              // 写信号
    );
    assign clk0  = CLK10MHZ;            // 10MHz
    assign clk1  = out0;
    assign clk2  = 0;    
    assign gate0 = 1;
    assign gate1 = 1;
    assign gate2 = 0;    
       
    //8255
    wire [7:0] pain,paout;
    wire [7:0] pbin,pbout;
    wire [7:0] pcin,pcout;   
    S_8255_0 D2(
        .CS_N(s8255csn),
        .IOR_N(ior_n),
        .IOW_N(iow_n),
        .reset(CPU_RESET),
        .a(adr[2:1]),
        .din(dat_o[7:0]),
        .dout(s8255out),
        .PA_in(pain),
        .PB_out(pbout),
        .PC_in(pcin),
        .PA_out(paout),
        .PB_in(pbin),
        .PC_out(pcout)
    );
    assign pain = 8'h00;
    assign pbin = 8'h00;
    assign pcin = 8'h00;
    
    assign IO_LED[1]   = paout[5];
    assign IO_LED[9]   = paout[6];
    assign IO_LED[17]  = paout[7];
    assign IO_LED[0]   = paout[0];
    assign IO_LED[8]   = paout[1];
    assign IO_LED[16]  = paout[2];
    
    //Display
    // Serica: .sel = pcout
    Digit48255_0 D3 (
        .clk(CLK10MHZ),
        .rst(CPU_RESET),
        .Hdata(16'hffff),
        .Ldata({8'h00,pbout}),
        .sel(pcout),
        .an(IO_AN),
        .segs(IO_SEG)
    );
        
endmodule
