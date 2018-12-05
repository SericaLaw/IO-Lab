`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
module Buzzer(
    input clk_in,           //���������ʱ��
    input CS_N,             //Ƭѡ�źţ��͵�ƽ��Ч��
    input IOW_N,            //д�źţ��͵�ƽ��Ч��
    input  [7:0] din,       //D�˿�����
    output buzzer
    );
    
    wire buzzerrst_n;
    
    assign buzzerrst_n = ((!CS_N) & (!IOW_N)) ? din[0] : buzzerrst_n; //����din[0]���Ʒ������򿪻��߹ر�
    
    assign buzzer = clk_in & buzzerrst_n;

endmodule

