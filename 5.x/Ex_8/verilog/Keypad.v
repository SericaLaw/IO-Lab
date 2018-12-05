`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
module Keypad(
    input         wb_clk_i,
    input         wb_rst_i,
    input         IOR_N,
    input         CS_N,
    output [15:0] wb_dat_o,
    input  [3:0]  row, // Serica: 
    output reg [3:0]  col
);
    reg         keysta;     // Serica: 键值保持标志
    reg  [3:0]  keynum;     // Serica: 键值
    reg         vaild;      // Serica: 键值有效标志 拼错了可海星
    
    reg  [7:0]  keyvalue = 8'b0000_0000;
    reg [25:0]  counter_clk = 0;
    
    assign wb_dat_o = {10'b0,keysta,vaild,keynum}; // Serica: 输出格式

    reg [1:0] next_state;
    reg [1:0] state;
    parameter [1:0]  scan    = 2'b01,
                      waitend = 2'b10;   //wait to end
                    
    always @ (posedge wb_clk_i or posedge wb_rst_i) begin
        if(wb_rst_i) begin  // reset
            state <= scan;
        end else begin
            state <= next_state;
        end
    end 
    
    always @ * begin
        if(wb_rst_i) begin
            vaild = 0;
            next_state = scan;  
        end else 
            case(state) 
            //完成手册中键盘消抖状态转换图的状态转换，注意对键值有效位的赋值
            
            scan:begin if(keysta & (!IOR_N))begin
            // Serica: 按下且读取，则进入等待状态S1，键值有效标志置1
                    vaild = 1;
                    next_state <= waitend;
                end
                // Serica: 未按下或未读取，继续在状态S0
                else next_state <= state;
            end
            waitend:begin
            // Serica: 状态S1 清楚有效标志，等待计时结束
                vaild = 0;
                if(counter_clk >= 2000000) next_state <= scan;
                else next_state <= state;
            end
            endcase
        end 
    
   always @(posedge wb_clk_i) begin
     if(counter_clk < 2000000) begin   //200ms
//    if(counter_clk < 200) begin   //仿真用时钟   
        counter_clk = counter_clk + 1; 
     end else begin
         case(col)
         // Serica: 所有列线全为0 读出所有行线状态 如果有行线为0 说明有键按下
            4'b0000: begin if(row != 4'b1111) begin
                keysta = 1; col = 4'b1110; end
                else keysta = 0;
            end
            /* Serica: 从第0列开始 每扫描一列 该列对应列线为0 其余为1；
             读入行线状态 如果有一行为0，则该列交叉处的键被按下
             如果所有行都是1 则列号+1 顺序扫描下一列
             */
             4'b1110: begin if(row != 4'b1111) begin
                keyvalue = {4'b1110, row}; col = 4'b0000; counter_clk = 0; end
                else col = 4'b1101;
             end
             4'b1101: begin if(row != 4'b1111) begin
                keyvalue = {4'b1101, row}; col = 4'b0000; counter_clk = 0; end
                else col = 4'b1011;
             end
             4'b1011: begin if(row != 4'b1111) begin
                keyvalue = {4'b1011, row}; col = 4'b0000; counter_clk = 0; end
                else col = 4'b0111;
             end
             4'b0111: begin if(row != 4'b1111) begin
                keyvalue = {4'b0111, row}; col = 4'b0000; counter_clk = 0; end
                else col = 4'b0000; // Serica: 开始新一轮扫描
             end
           default : begin col <= 4'b0000; keysta <= 0;end           
           endcase
       end
   end
    
    always @* begin                           //键值译码
        case(keyvalue[3:0])               //col
            4'b1110: begin
                case(keyvalue[7:4])
                    4'b1110: keynum = 4'b0001; // 1
                    4'b1101: keynum = 4'b0100; // 4
                    4'b1011: keynum = 4'b0111; // 7
                    4'b0111: keynum = 4'b1110; // E
                    default: begin end         //多键按下不处理
                endcase
            end
              
            4'b1101: begin
               case(keyvalue[7:4])
                    4'b1110: keynum = 4'b0010; // 2
                    4'b1101: keynum = 4'b0101; // 5
                    4'b1011: keynum = 4'b1000; // 8
                    4'b0111: keynum = 4'b0000; // 0
                    default: begin end         //多键按下不处理
                endcase
            end
            
            4'b1011: begin
                case(keyvalue[7:4])
                    4'b1110: keynum = 4'b0011; // 3
                    4'b1101: keynum = 4'b0110; // 6
                    4'b1011: keynum = 4'b1001; // 9
                    4'b0111: keynum = 4'b1111; // F
                    default: begin end         //多键按下不处理
                endcase
            end
            
            4'b0111: begin
               case(keyvalue[7:4])
                    4'b1110: keynum = 4'b1010; // A
                    4'b1101: keynum = 4'b1011; // B
                    4'b1011: keynum = 4'b1100; // C
                    4'b0111: keynum = 4'b1101; // D
                    default: begin end         //多键按下不处理
                endcase
            end
           
           default: keynum = 4'b0;
        endcase
    end
	
endmodule
