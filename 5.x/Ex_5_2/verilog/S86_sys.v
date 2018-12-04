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
    output [7:0] IO_SEG
 );

    //WB����
    wire [15:0] dat_o;
    wire [15:0] dat_i;
    wire [19:1] adr;
    wire [1:0]  sel;
    wire we, tga, stb, cyc, ack;
    //��д������:ior/iow/memw/memr     
    wire ior_n, iow_n, memw_n, memr_n; 
    //��ַ������
    wire swcsn, digitcsn, s8254csn; 
    //RAM
    wire [15:0] mem_dat_i;
    wire        memack;
    //switch
    wire [15:0] switch_out;
    //S8254
    wire [7:0] s8254out;
 
 
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
 
    //��д�źŷ�����     
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
 
    //��ַ������
    Decoder_0 U1(
        .A(adr[4]),                                                   
        .B(adr[5]),                                                  
        .C(adr[6]),                                                  
        .G1(!adr[9]),                                                
        .G2AN(ior_n & iow_n),                                         
        .G2BN(adr[7] | adr[8]),                                                 
        .Y1N(swcsn),
        .Y2N(digitcsn),
        .Y4N(s8254csn)                                                  
    );
    
    //�������ݶ�·ѡ����
    // Serica: s8254�����Ҫ��չ��16λ
    Muxdati U2(
        .wb_tga_i(tga),
        .RDN(ior_n & memr_n),
        .MEMDATI(mem_dat_i),
        .IOCS0_N(swcsn),
        .IODAT0I(switch_out),
        .IOCS1_N(s8254csn),
        .IODAT1I({8'b00000000,s8254out}),
        .DATO(dat_i)
    );
    
    //Ӧ���źŷ�����
    ACKgenerator U3( 
        .MEMACK(memack),
        .IOCS0_N(swcsn),
        .IOCS1_N(digitcsn),
        .IOCS2_N(s8254csn),
        .ACK(ack)
    );
    
    //�ڴ������
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
    
    wire clk_1HZ;
    divclk U4(.clk(CLK10MHZ), .rst(CPU_RESET),.clk_sys(clk_1HZ));

    S_8254 D2(    
        .clk0(clk_1HZ),      // Counter0����ʱ��
        .gate0(IO_Switch[23]), // Counter0ʹ��
        .out0(IO_LED[23]),     // Counter0�������
        .a(adr[2:1]),        // ��ַ��
        .id(dat_o[7:0]),     // ��������
        .od(s8254out),       // �������
        .CS_N(s8254csn),     // Ƭѡ
        .IOR_N(ior_n),       // ���ź�
        .IOW_N(iow_n)        // д�ź�
    );        

endmodule
