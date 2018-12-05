`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
module reset(
   
    input lock,
    input btnreset,
	input btnu,
    output reset,
	output reg upg_rst
    );
    
    assign reset = (!lock) | (btnreset); 
	
	always @ (posedge btnu or negedge btnreset) begin
		if (btnu == 1)
			upg_rst = 0;
		if (btnreset == 1)
			upg_rst = 1;
	end

endmodule
