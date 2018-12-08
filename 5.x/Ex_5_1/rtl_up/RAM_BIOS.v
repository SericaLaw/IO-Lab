`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
module RAM_BIOS(
	//UART program downloader slave interface
    input         pg_clk_i,
    input         pg_rst_i,
    input         pg_wen,       
    input  [15:0] pg_din,       
    input  [15:0] pg_adr,
    input         pg_done,
    // Wishbone slave interface
    input         wb_clk_i,
    input  [15:0] wb_dat_i,
    output [15:0] wb_dat_o,
    input  [19:1] wb_adr_i,
    input  [1:0]  wb_sel_i,
    output        wb_ack_o,
    input         MEMW_N,
    input         MEMR_N
    );

    wire        ram_cs;
    wire        ram_mem_arena;
    wire [1:0]  ram_we;
    //RAM EN
    assign ram_mem_arena = (wb_adr_i[19:16]==4'h0 || wb_adr_i[19:16]==4'hf);
    assign ram_cs   = ((!(MEMW_N&MEMR_N)) & ram_mem_arena);
    assign ram_we = (!MEMW_N) ? wb_sel_i : 2'b00;
    assign wb_ack_o = ram_cs;
    
	wire kickOff = pg_rst_i | ((!pg_rst_i) & pg_done);
	
    bios_ram ram_bios1(
        .addra(kickOff ? wb_adr_i[16:1] : pg_adr),
        .douta(wb_dat_o),
        .wea(kickOff ? ram_we : {pg_wen, pg_wen}),//wea–≈∫≈≤È—Ø
        .dina(kickOff ? wb_dat_i : pg_din),
        .ena(kickOff ? ram_cs : 1),
        .clka(kickOff ? wb_clk_i : pg_clk_i)
    );
    
endmodule
