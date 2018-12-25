`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
module S_8254(
    input clk0,			 // Counter0����ʱ��
    input gate0,		 // Counter0ʹ��    
    output reg out0,	 // Counter0�������    
    input CS_N,			 // Ƭѡ
    input [1:0] a,		 // ��ַ��
    input [7:0] id,		 // �������� 
    output reg [7:0] od, // �������
    input IOR_N,		 // ���ź�
    input IOW_N			 // д�ź�
    );
    
    //��ʱ���ڲ��Ĵ��� 
    reg [5:0]  MR; //������ʽ�Ĵ���
    reg [15:0] CR; //��ʼֵ�Ĵ���
    reg [15:0] OL; //���������
    reg [7:0]  SR; //״̬�Ĵ���
    reg [7:0]  SL; //״̬������
    reg [15:0] CE; //������������Ԫ

    //��д�źţ���Ϊ�ߵ�ƽ��Ч
    wire wmode;     //д������ʽ��
    wire wnowcount; //���浱ǰ����ֵ
    wire wrback;    //д��������
    wire rcounter0; //��������0
    wire wcounter0; //д������0  
    
    //д��ֵ��ؼĴ���������ź�
    reg [7:0] CRtemp;  //CR��8λ�ݴ棬����16λ��ֵʱ�ݴ��8λ
    reg [1:0] crsta;   //��¼��ֵ��д�뷽ʽ
    reg crinitflag;    //��¼д�뷽ʽ�����ֺ�CR�Ƿ���й���ʼ��
    reg crflag;        //������ʾд���ֵ��״̬��־
    reg wcrflag;       //д���ֵ�ɹ���־    
    wire wcr;          //��ʾ��ֵ��д��
    
    //����ֵ�Ƿ���Ч״̬λ
    reg NULL_COUNT; //����ֵ�Ƿ���Ч��1--��Ч 0--��Ч
    
    /*��Ϊд������0�Ĺ���ģʽ��ʽ��,��������д�����ּĴ���д�����ֵ�������ѡ�������0���������������
    ������csn:0 IOR_N:1 IOW_N:0 a0:1 a1:0 D7D6=00 D5D4!=00 ���߼��������£�*/
    assign wmode = (!CS_N) & (IOR_N) & (!IOW_N) & (a[1]) & (a[0]) & (!id[7]) & (!id[6]) & ((id[5]) | (id[4]));
    // Serica : ����ǰ����ֵ�ķ����� 1. ������ʽ������ A1A0=11 D7D6 != 11 D5D4=00; 2. �������� A1A0=11 D7D6=11 D5D4=01 D0=0
    // Dae: ����wnowcount, wrbackӦ��ָ�������ֶ�ȡ����ֵ�ķ����ɣ�
    //assign wnowcount = (!CS_N) & (IOR_N) & (!IOW_N) & (a[1]) & (a[0]) & ((!(id[7] & id[6]) & (!id[5]) & (!id[4])) | (id[7] & id[6] & (!id[5]) & id[4] & (!id[0])));
    assign wnowcount = (!CS_N) & (IOR_N) & (!IOW_N) & (a[1]) & (a[0]) & (((!(id[7]&id[6])) & (!id[5]) & (!id[4])) | (id[7] & (id[6]) &(!id[5]) & (id[1]) & (!id[0])));
    // Serica: A1A0=00 D7D6=00 D0=0
    // Dae: D5D4=01
    //assign wrback = (!CS_N) & (!IOR_N) & (IOW_N) & (a[1]) & (a[0]) & (id[7]) & (id[6]) & (!id[0]);
    assign wrback = (!CS_N) & (IOR_N) & (!IOW_N) & (a[1]) & (a[0]) & (id[7]) & (id[6]) & (!(id[5]&id[4])) & (id[1]) & (!id[0]);

    // Serica: ��д������0 A1A0=00
    assign rcounter0 = (!CS_N) & (!IOR_N) & (IOW_N) & (!a[1]) & (!a[0]);
    assign wcounter0 = (!CS_N) & (IOR_N) & (!IOW_N) & (!a[1]) & (!a[0]);

             
    //��д����ģʽ��ʽ���źŵ������أ��Թ�����ʽ�Ĵ�����ֵ����Ϊֻ�е�6λ������ع�����ʽ����Ϣ��
    always @ (posedge wmode) begin
        MR <=  id[5:0];
    end 
  
    //״̬�Ĵ���SR
    // Serica: ״̬�ָ�ʽ�� out, NULL_COUNT, ������ʽ
    always @ (*) begin
      SR = {out0,NULL_COUNT,MR};
    end
    
    //������ֵ�Ĵ�����CR
    // Serica: wcr��ʾ��ֵ��д��
    assign wcr = wcounter0 & wcrflag;
    always @ (posedge wcounter0 or posedge wmode) begin
        // Serica: д������ʽ��
        if(wmode) begin
            CR <= 16'h0000;   //�����0����
            CRtemp <= 8'h00;  //��0  
            crsta <= id[5:4]; //д���ֵ�ķ�ʽѡ��
            crflag <= 0;      //��־λ��0
            wcrflag <= 0;     //δд���ֵ
            crinitflag <= 0;  //δ��ʼ��
        end else begin
            case (crsta)
                // Serica: �ɴ�״̬���л�ȡ������ʽ SR[0]=1ΪBCD����� SR[3:1]=011Ϊ��ʽ3
                // 2'b01: if(!((SR[0] & ((id[3:0] > 4'h9) | (id[7:4] > 4'h9))) | ((SR[3:1]==3'b011) & (id[7:0]==8'h01)))) begin   //д���ֵ����������1.BCD�����ʱ�����㷶Χ 2.��ʽ3����ʱ����ֵ��Ϊ1
                // Dae: ʵ����Ҫ���㣺1.BCD�����ʱ�����㷶Χ 2.��ʽ3����ʱ����ֵ��Ϊ1
                // Dae: �����Ƽ�ֱ����ħ����ת������������������������Ҫͬʱ���㣺��ΪBCD�����㷶Χ|��BCD��& (��ʽ3��ֵ��Ϊ1|�Ƿ�ʽ3)
                2'b01: if((((SR[0]) & (id[3:0] <= 4'h9) & (id[7:4] <= 4'h9))|(!SR[0])) & (((SR[3:1]==3'b011) & (id[7:0]!=8'h01)) | (SR[3:1]!=3'b011)) )) begin   //д���ֵ����������1.BCD�����ʱ�����㷶Χ 2.��ʽ3����ʱ����ֵ��Ϊ1
                           CR <= {8'h00,id};
                           wcrflag <= 1;
                           crinitflag <= 1;  //�ѳ�ʼ��
                       end else begin 
                           CR <= CR;
                           wcrflag <= 0;
                       end //ֻд��8λ
                // 2'b10: if(!(SR[0] & (id[3:0] > 4'h9) | (SR[0] &  (id[7:4] > 4'h9)))) begin //��BCD���������ֵ����Ҫ��ʱ��д���ֵ
                // Dae: ͬline 89����
                2'b10: if(((SR[0]) & (id[3:0] <= 4'h9) & (id[7:4] <= 4'h9))|(!SR[0])) begin //��BCD���������ֵ����Ҫ��ʱ��д���ֵ
                           CR <= {id,8'h00};
                           wcrflag <= 1;
                           crinitflag <= 1;  //�ѳ�ʼ��
                       end else begin
                           CR <= CR;
                           wcrflag <= 0;
                       end //ֻд��8λ
                2'b11: if(!crflag)begin //��д��8λ
                           CRtemp <= id; crflag <= 1; wcrflag <= 0;
                    //    end else if(!((SR[0] & ((id[3:0] > 4'h9) | (id[7:4] > 4'h9))) | (SR[0] & ((CRtemp[7:4] > 4'h9) | (CRtemp[3:0] > 4'h9))) | ((SR[3:1]==3'b011) & (id[7:0]==8'h00) & (CRtemp==8'h01)))) begin //д���ֵ����������1.BCD�����ʱ�����㷶Χ 2.��ʽ3����ʱ����ֵ��Ϊ1
                    // Dae: ����͵�89�в��
                       end else if ((((SR[0]) & (id[3:0] <= 4'h9) & (id[7:4] <= 4'h9) & (CRtemp[7:4]<=4'h9) & (CRtemp[3:0]<=4'h9))|(!SR[0])) & (((SR[3:1]==3'b011) & (id[7:0]!=8'h00)& (CRtemp==8'h01)) | (SR[3:1]!=3'b011)) )) begin //д���ֵ����������1.BCD�����ʱ�����㷶Χ 2.��ʽ3����ʱ����ֵ��Ϊ1
                           CR <= {id, CRtemp}; crflag <= 0; wcrflag <= 1; crinitflag <= 1; 
                       end else begin //��д��8λ
                           CR <= CR; crflag <= 0; wcrflag <= 0;
                       end 
                default:begin CR <= 0; crflag<=0; wcrflag <= 0; crinitflag <= 0; end //��������
            endcase  
        end
    end     
           
    reg Rflag;//rising edge flag���Ա��GATE0������
    reg Rtrace;//���Ը���Rflag
    always@(posedge gate0 or posedge wmode)begin
        if(wmode) begin
            Rflag <= 0;
        end else begin
            if(Rtrace==Rflag)
                Rflag <= ~Rflag;
        end
    end
  
    reg OEflag; //���Ա�ʾ��ʽ3�¼�����ֵ����ż�����0Ϊż����1Ϊ����
    reg Fwcr;   //���Ա�ʾ��ʽ3��д�뷽ʽ�ֺ󣬵�һ��д���ֵ
    reg FWcr1;  //���ڷ�ֹ����д��ֵ��ɵ��޷���¼�����أ�������з�ʽ��ʾ��һ����ֵ�ѱ�д��
    //���Ʒ�ʽ1�ͷ�ʽ3�µ�CE������������ʽ���µ�out��� 
    always@(negedge clk0 or posedge wcr or posedge wmode) begin
        if(wmode)begin //д�빤����ʽ������ʱ���߼���λ
            // Serica: NULL_COUNT = 1 ��ǰ����ֵ��Ч
            NULL_COUNT <= 1'b1;
            // Serica: OUT��д������ֺ���
            out0 <= 1'b1; 
            Fwcr <= 1'b1;FWcr1 <= 1'b1;CE <= 0;  
        end else if(wcr)begin //������д��ֵʱ
            NULL_COUNT <= 1;
            if(FWcr1 == 1)begin //ֻ׷�ٵ�һ��д���ֵ��������أ���ֹ�ظ�д��ֵ��ɵĸ���������
                Rtrace <= Rflag; 
                FWcr1 <= 0; 
            end
        end else if (!crinitflag)begin
            //δ��ʼ�������κ�����    
        end else if(SR[2:1] == 2'b11) begin//��ʽ3��������2��װ��GATE��������װ��GATE==0ֹͣ����,��������ɷ�ʽ3
            if(Fwcr == 1) begin
                Fwcr <= 0;
                CE <= {CR[15:1],1'b0};//˼���⣺Ϊʲô���λ��0��
                OEflag <= CR[0];
                NULL_COUNT <= 0;
            end else if(Rtrace != Rflag) begin//��������װ��ʼֵ
                Rtrace <= Rflag;
                NULL_COUNT <= 0;
                CE <= {CR[15:1],1'b0};
                out0 <= 1; // Serica: ��װ out��ʼ��Ϊ��
                OEflag <=  CR[0];
            end else if (gate0 == 1'b1) begin //gate0Ϊ1ʱ��ʼ������Ϊ0ʱֹͣ����
                if(OEflag==0 && CE == 16'h0002)begin //ż��������ֵ����ǰ������2�Ĵ���
                    CE <= {CR[15:1],1'b0};//��װ������ֵ
                    OEflag <= CR[0];//OEflag���¸�ֵ�Է�ֹ�³�ʼֵд��
                    NULL_COUNT <= 0;
                    out0 <= ~out0;//������ʱ����
                end else if(OEflag==1 &&((CE==16'h0002 && out0==0)||(CE==16'h0000 && out0==1)))begin //����������ֵ����ǰ������Ҫ�������ʱ�Ĵ���
                    CE <= {CR[15:1],1'b0};//��װ������ֵ
                    OEflag <= CR[0];//OEflag���¸�ֵ�Է�ֹ�³�ʼֵд��
                    NULL_COUNT <= 0;
                    out0 <= ~out0;//������ʱ����    
                end else if(SR[0] == 1'b1) begin //����BCD�����
                    //��BCD���2����ע��'0'-'2 '�Ĵ���
                    // 10-2=8
                    if((CE[3:0]==4'h0) && (CE[7:4]!=4'h0))begin
                        CE=CE-16'h0008;
                     // 100-2=98
                    end else if((CE[3:0]==4'h0) && (CE[7:4]==0) && (CE[11:8]!=4'h0)) begin
                        CE=CE-16'h0068;
                     // 1000-2=998
                    end else if((CE[3:0]==4'h0) && (CE[7:4]==0) && (CE[11:8]==4'h0)) begin
                        CE=CE-16'h0668;   
                    end  else begin
                        CE = CE - 16'h0002;
                    end                 
                end else begin //���򣬶����Ƽ�����2���� 
                    CE = CE - 16'h0002;
                end
            end
        end        
    end 
    
    //SL��״̬������
    always @ (posedge wmode or posedge wrback)begin
        if(wmode) begin
        // ��ʼ��
           SL <= 0;
        end else if(wrback & !id[4])begin
        // ����״̬��
           SL <= SR;
        end else begin
        // ����
           SL <= SL;
        end
    end  
  
    //OL������������������߼�
    always @ (posedge wmode or posedge wnowcount or posedge wrback) begin
        if(wmode) begin
            OL <= 0;
        end else if(wnowcount) begin 
            OL <= CE;
        end else if(wrback & !id[5]) begin
            OL <= CE;
        end else begin
            OL <= OL;
        end
    end  
    
    //od 
    reg [2:0] rsta;//[0]��ʾ��״̬��[1]��ʾ����8λ�� [2]��ʾ����8λ��
    always @ (posedge wrback or posedge wnowcount or posedge wmode) begin
        if(wmode) begin
            rsta  <= 3'b000;
        end else if(wnowcount)begin //����ǰ����ֵ
            // Serica: RW1(SR[5])RW0(SR[4]) = 01 ֻ�����ֽ� 10 ���ֽ� 11�ȵͺ��
            // Serica: ��״̬����״̬��
            rsta[2]  <= SR[5];
            rsta[1]  <= SR[4];
            rsta[0]  <= 0;
        end else if(wrback) begin //��������
            rsta[2]  <= SR[5];
            rsta[1]  <= SR[4];
            rsta[0]  <= !id[4];    // ����������D4=0��ʾ��Ҫ����״̬    
        end else begin    
            rsta  <= rsta;  
        end
    end     
     
    reg [1:0] rflag;
    wire rflagreset;
    assign rflagreset = wmode | wnowcount | wrback;
    always @ (posedge rflagreset or posedge rcounter0) begin       
        if(rflagreset) begin
            rflag <= 2'b00;
            od <= od;
        end else begin 
            if(rflag == 2'b11) begin
                od <= od;
            end else begin
                case (rsta)
                    3'b100:begin od <= OL[15:8]; rflag <= 2'b11; end
                    3'b010:begin od <= OL[7:0]; rflag <= 2'b11; end
                    3'b001:begin od <= SL; rflag <= 2'b11; end
                    3'b110:begin
                             if(rflag == 2'b00) begin 
                                 od <= OL[7:0]; // Serica: �ȶ����ֽ� 
                                 rflag <= 2'b01;
                             end else begin
                                 od <= OL[15:8];
                                 rflag <= 2'b11;
                             end
                           end 
                    3'b101:begin 
                             if(rflag == 2'b00) begin
                                od <= SL; // Serica: �ȶ�״̬      
                                rflag <= 2'b01;
                             end else begin
                                od <= OL[15:8];
                                rflag <= 2'b11;
                             end
                           end    
                    3'b011:begin 
                             if(rflag == 2'b00) begin
                                  od <= SL;      
                                  rflag <= 2'b01;
                             end else begin
                                  od <= OL[7:0];
                                  rflag <= 2'b11;
                              end
                          end    
                    3'b111:begin 
                              if(rflag == 2'b00) begin
                                  od <= SL;      
                                  rflag <= 2'b01;
                              end else if (rflag==2'b01)begin
                                  od <= OL[7:0]; 
                                  rflag <= 2'b10;
                              end else begin
                                  od <= OL[15:8];
                                  rflag <= 2'b11;
                              end               
                          end
                    default: begin od <= CE[7:0];end
                endcase 
            end
       end
    end      
 
endmodule
