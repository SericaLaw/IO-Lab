`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
module S86_top (
    input         clk_100_,
    input         button_rst,
    //led
    output [23:0] led_,
    //switch
    input  [23:0] switch_,
    //segs
    output [7:0] an,
    output [7:0] segs
 );
 
    //clock
    wire  clk, clk_ram, lock;
    //reset
    wire  rst;
    //WB����
    wire [15:0] dat_o;
    wire [15:0] dat_i;
    wire [19:1] adr;
	wire [1:0] sel;
    wire we, tga, stb, cyc, ack, intr, inta;
    //��д������:ior/iow/memw/memr
    wire ior_n, iow_n, memw_n, memr_n; 
    //��ַ������
    wire piccsn, s8254csn, s8255csn; 
    //RAM
    wire [15:0] mem_dat_i;
    wire        memack;
    //PIC
    wire [7:0] picout;
    //S8254
    wire [7:0] s8254out;
    //S8255
    wire [7:0] s8255out;
    
    pll CLOCK(.clk_in1 (clk_100_), .clk_out1(clk),.clk_out2(clk_ram),.locked (lock));
    
    reset RESET(.lock(lock),.button(button_rst),.reset(rst));
 
    //S86 processor
    S86_0 S86_proc (
        //Wishbone master interface
        .wb_clk_i (clk),
        .wb_rst_i (rst),
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
    
    //�������ݶ�·ѡ����
    Muxdati U2(
        .wb_tga_i(tga),
        .RDN(ior_n & memr_n),
        .INTA_N(!inta),//����PICʱ����Ҫ����
        .MEMDATI(mem_dat_i),
        .IOCS0_N(piccsn),
        .IODAT0I({8'h00,picout}),
        .IOCS1_N(s8254csn),
        .IODAT1I({8'h00,s8254out}),
        .IOCS2_N(s8255csn),
        .IODAT2I({8'h00,s8255out}),
        .DATO(dat_i)
    );
    
    //Ӧ���źŷ�����
    ACKgenerator U3( 
        .MEMACK(memack),
        .IOCS0_N(piccsn),
        .IOCS1_N(s8254csn),
        .IOCS2_N(s8255csn),
        .ACK(ack)
    );
    
    RAM_BIOS M0(
        .wb_clk_i (clk_ram),
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
    // Serica: ��ʱ�����ж������IR0
	assign ir = {7'b0000000, out1};    //���ж���ʹ��PIC��IR0~IR7�е��ĸ����ţ�ע�⣬����д�ĳ���Ҫ��֮��Ӧ
    PIC_0 D0(
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
    wire clk0;
    wire gate0;
    wire out0;
    wire clk1;
    wire gate1;
    wire out1;
    wire clk2;
    wire gate2;
    wire out2;
    S_8254_0 D1(    
        .clk0(clk0),			 // Counter0����ʱ��
        .gate0(gate0),		 // Counter0ʹ��
        .out0(out0),			 // Counter0�������
        .clk1(clk1),			 // Counter1����ʱ��
        .gate1(gate1),		 // Counter1ʹ��
        .out1(out1),			 // Counter1�������
        .clk2(clk2),			 // Counter2����ʱ��
        .gate2(gate2),		 // Counter2ʹ��
        .out2(out2),			 // Counter2�������                
        .a(adr[2:1]),			 // ��ַ��
        .id(dat_o[7:0]),		 // ��������
        .od(s8254out),        // �������
        .CS_N(s8254csn),	    // Ƭѡ
        .IOR_N(ior_n),	    // ���ź�
        .IOW_N(iow_n)		  	// д�ź�
    );
	assign clk0  = clk;			// 10MHz
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
        .reset(rst),
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
	
	//LED����8255�����������о��������������Ҫ��֮��Ӧ
	assign led_[1]	  = paout[5]; // GD1 - PA5
	assign led_[9]	  = paout[6]; // YD1 - PA6
	assign led_[17]	  = paout[7]; // RD1 - PA7
	assign led_[0]	  = paout[0]; // GD0 - PA0
	assign led_[8]	  = paout[1]; // YD0 - PA1
	assign led_[16]	  = paout[2]; // RD0 - PA2
	
	//Display
    Digit48255_0 D3 (
        .clk(clk),
        .rst(rst),
        .Hdata(16'hffff),
        .Ldata({8'h00,pbout}),
        .sel(pcout),
        .an(an),
        .segs(segs)
    );
	
endmodule
