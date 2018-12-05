`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
module Buzzer(
    input clk_in,           //输入蜂鸣器时钟
    input CS_N,             //片选信号（低电平有效）
    input IOW_N,            //写信号（低电平有效）
    input  [7:0] din,       //D端口输入
    output buzzer
    );
    
    wire buzzerrst_n;
    
    assign buzzerrst_n = ((!CS_N) & (!IOW_N)) ? din[0] : buzzerrst_n; //根据din[0]控制蜂鸣器打开或者关闭
    
    assign buzzer = clk_in & buzzerrst_n;

endmodule

