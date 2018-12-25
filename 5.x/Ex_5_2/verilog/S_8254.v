`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
module S_8254(
    input clk0,			 // Counter0输入时钟
    input gate0,		 // Counter0使能    
    output reg out0,	 // Counter0输出波形    
    input CS_N,			 // 片选
    input [1:0] a,		 // 地址线
    input [7:0] id,		 // 输入数据 
    output reg [7:0] od, // 输出数据
    input IOR_N,		 // 读信号
    input IOW_N			 // 写信号
    );
    
    //计时器内部寄存器 
    reg [5:0]  MR; //工作方式寄存器
    reg [15:0] CR; //初始值寄存器
    reg [15:0] OL; //输出锁存器
    reg [7:0]  SR; //状态寄存器
    reg [7:0]  SL; //状态锁存器
    reg [15:0] CE; //计数器工作单元

    //读写信号：均为高电平有效
    wire wmode;     //写工作方式字
    wire wnowcount; //锁存当前计数值
    wire wrback;    //写读回命令
    wire rcounter0; //读计数器0
    wire wcounter0; //写计数器0  
    
    //写初值相关寄存器和相关信号
    reg [7:0] CRtemp;  //CR低8位暂存，用于16位初值时暂存低8位
    reg [1:0] crsta;   //记录初值的写入方式
    reg crinitflag;    //记录写入方式控制字后CR是否进行过初始化
    reg crflag;        //用来表示写入初值的状态标志
    reg wcrflag;       //写入初值成功标志    
    wire wcr;          //表示初值已写入
    
    //计数值是否有效状态位
    reg NULL_COUNT; //计数值是否有效：1--无效 0--有效
    
    /*因为写计数器0的工作模式方式字,所以满足写控制字寄存器写控制字的条件，选择计数器0，非锁存计数器。
    所以有csn:0 IOR_N:1 IOW_N:0 a0:1 a1:0 D7D6=00 D5D4!=00 ，逻辑描述如下：*/
    assign wmode = (!CS_N) & (IOR_N) & (!IOW_N) & (a[1]) & (a[0]) & (!id[7]) & (!id[6]) & ((id[5]) | (id[4]));
    // Serica : 读当前计数值的方法： 1. 工作方式控制字 A1A0=11 D7D6 != 11 D5D4=00; 2. 读回命令 A1A0=11 D7D6=11 D5D4=01 D0=0
    // Dae: 另外wnowcount, wrback应该指的是两种读取计数值的方法吧？
    //assign wnowcount = (!CS_N) & (IOR_N) & (!IOW_N) & (a[1]) & (a[0]) & ((!(id[7] & id[6]) & (!id[5]) & (!id[4])) | (id[7] & id[6] & (!id[5]) & id[4] & (!id[0])));
    assign wnowcount = (!CS_N) & (IOR_N) & (!IOW_N) & (a[1]) & (a[0]) & (((!(id[7]&id[6])) & (!id[5]) & (!id[4])) | (id[7] & (id[6]) &(!id[5]) & (id[1]) & (!id[0])));
    // Serica: A1A0=00 D7D6=00 D0=0
    // Dae: D5D4=01
    //assign wrback = (!CS_N) & (!IOR_N) & (IOW_N) & (a[1]) & (a[0]) & (id[7]) & (id[6]) & (!id[0]);
    assign wrback = (!CS_N) & (IOR_N) & (!IOW_N) & (a[1]) & (a[0]) & (id[7]) & (id[6]) & (!(id[5]&id[4])) & (id[1]) & (!id[0]);

    // Serica: 读写计数器0 A1A0=00
    assign rcounter0 = (!CS_N) & (!IOR_N) & (IOW_N) & (!a[1]) & (!a[0]);
    assign wcounter0 = (!CS_N) & (IOR_N) & (!IOW_N) & (!a[1]) & (!a[0]);

             
    //在写工作模式方式字信号的上升沿，对工作方式寄存器赋值，因为只有低6位存有相关工作方式的信息。
    always @ (posedge wmode) begin
        MR <=  id[5:0];
    end 
  
    //状态寄存器SR
    // Serica: 状态字格式： out, NULL_COUNT, 工作方式
    always @ (*) begin
      SR = {out0,NULL_COUNT,MR};
    end
    
    //计数初值寄存器：CR
    // Serica: wcr表示初值已写入
    assign wcr = wcounter0 & wcrflag;
    always @ (posedge wcounter0 or posedge wmode) begin
        // Serica: 写工作方式字
        if(wmode) begin
            CR <= 16'h0000;   //完成清0操作
            CRtemp <= 8'h00;  //清0  
            crsta <= id[5:4]; //写入初值的方式选择
            crflag <= 0;      //标志位请0
            wcrflag <= 0;     //未写入初值
            crinitflag <= 0;  //未初始化
        end else begin
            case (crsta)
                // Serica: 可从状态字中获取工作方式 SR[0]=1为BCD码计数 SR[3:1]=011为方式3
                // 2'b01: if(!((SR[0] & ((id[3:0] > 4'h9) | (id[7:4] > 4'h9))) | ((SR[3:1]==3'b011) & (id[7:0]==8'h01)))) begin   //写入初值满足条件：1.BCD码计数时，满足范围 2.方式3计数时，初值不为1
                // Dae: 实际上要满足：1.BCD码计数时，满足范围 2.方式3计数时，初值不为1
                // Dae: 这个设计简直就是魔鬼……转化成两个条件，两个条件需要同时满足：（为BCD则满足范围|非BCD）& (方式3初值不为1|非方式3)
                2'b01: if((((SR[0]) & (id[3:0] <= 4'h9) & (id[7:4] <= 4'h9))|(!SR[0])) & (((SR[3:1]==3'b011) & (id[7:0]!=8'h01)) | (SR[3:1]!=3'b011)) )) begin   //写入初值满足条件：1.BCD码计数时，满足范围 2.方式3计数时，初值不为1
                           CR <= {8'h00,id};
                           wcrflag <= 1;
                           crinitflag <= 1;  //已初始化
                       end else begin 
                           CR <= CR;
                           wcrflag <= 0;
                       end //只写低8位
                // 2'b10: if(!(SR[0] & (id[3:0] > 4'h9) | (SR[0] &  (id[7:4] > 4'h9)))) begin //当BCD码计数，初值符合要求时，写入初值
                // Dae: 同line 89错误
                2'b10: if(((SR[0]) & (id[3:0] <= 4'h9) & (id[7:4] <= 4'h9))|(!SR[0])) begin //当BCD码计数，初值符合要求时，写入初值
                           CR <= {id,8'h00};
                           wcrflag <= 1;
                           crinitflag <= 1;  //已初始化
                       end else begin
                           CR <= CR;
                           wcrflag <= 0;
                       end //只写高8位
                2'b11: if(!crflag)begin //先写低8位
                           CRtemp <= id; crflag <= 1; wcrflag <= 0;
                    //    end else if(!((SR[0] & ((id[3:0] > 4'h9) | (id[7:4] > 4'h9))) | (SR[0] & ((CRtemp[7:4] > 4'h9) | (CRtemp[3:0] > 4'h9))) | ((SR[3:1]==3'b011) & (id[7:0]==8'h00) & (CRtemp==8'h01)))) begin //写入初值满足条件：1.BCD码计数时，满足范围 2.方式3计数时，初值不为1
                    // Dae: 这里和第89行差不多
                       end else if ((((SR[0]) & (id[3:0] <= 4'h9) & (id[7:4] <= 4'h9) & (CRtemp[7:4]<=4'h9) & (CRtemp[3:0]<=4'h9))|(!SR[0])) & (((SR[3:1]==3'b011) & (id[7:0]!=8'h00)& (CRtemp==8'h01)) | (SR[3:1]!=3'b011)) )) begin //写入初值满足条件：1.BCD码计数时，满足范围 2.方式3计数时，初值不为1
                           CR <= {id, CRtemp}; crflag <= 0; wcrflag <= 1; crinitflag <= 1; 
                       end else begin //再写高8位
                           CR <= CR; crflag <= 0; wcrflag <= 0;
                       end 
                default:begin CR <= 0; crflag<=0; wcrflag <= 0; crinitflag <= 0; end //发生错误
            endcase  
        end
    end     
           
    reg Rflag;//rising edge flag用以标记GATE0上升沿
    reg Rtrace;//用以跟踪Rflag
    always@(posedge gate0 or posedge wmode)begin
        if(wmode) begin
            Rflag <= 0;
        end else begin
            if(Rtrace==Rflag)
                Rflag <= ~Rflag;
        end
    end
  
    reg OEflag; //用以表示方式3下计数初值的奇偶情况，0为偶数，1为奇数
    reg Fwcr;   //用以表示方式3，写入方式字后，第一次写入初值
    reg FWcr1;  //用于防止持续写初值造成的无法记录上升沿，针对所有方式表示第一个初值已被写入
    //控制方式1和方式3下的CE计数，产生方式三下的out输出 
    always@(negedge clk0 or posedge wcr or posedge wmode) begin
        if(wmode)begin //写入工作方式控制字时，逻辑复位
            // Serica: NULL_COUNT = 1 当前计数值有效
            NULL_COUNT <= 1'b1;
            // Serica: OUT在写入控制字后变高
            out0 <= 1'b1; 
            Fwcr <= 1'b1;FWcr1 <= 1'b1;CE <= 0;  
        end else if(wcr)begin //当发生写初值时
            NULL_COUNT <= 1;
            if(FWcr1 == 1)begin //只追踪第一次写入初值后的上升沿，防止重复写初值造成的覆盖上升沿
                Rtrace <= Rflag; 
                FWcr1 <= 0; 
            end
        end else if (!crinitflag)begin
            //未初始化不做任何事情    
        end else if(SR[2:1] == 2'b11) begin//方式3：计数到2重装，GATE上升沿重装，GATE==0停止计数,请自行完成方式3
            if(Fwcr == 1) begin
                Fwcr <= 0;
                CE <= {CR[15:1],1'b0};//思考题：为什么最低位赋0？
                OEflag <= CR[0];
                NULL_COUNT <= 0;
            end else if(Rtrace != Rflag) begin//上升沿重装初始值
                Rtrace <= Rflag;
                NULL_COUNT <= 0;
                CE <= {CR[15:1],1'b0};
                out0 <= 1; // Serica: 重装 out初始化为高
                OEflag <=  CR[0];
            end else if (gate0 == 1'b1) begin //gate0为1时开始计数，为0时停止计数
                if(OEflag==0 && CE == 16'h0002)begin //偶数计数初值，当前计数到2的处理
                    CE <= {CR[15:1],1'b0};//重装计数初值
                    OEflag <= CR[0];//OEflag重新赋值以防止新初始值写入
                    NULL_COUNT <= 0;
                    out0 <= ~out0;//计数到时反向
                end else if(OEflag==1 &&((CE==16'h0002 && out0==0)||(CE==16'h0000 && out0==1)))begin //奇数计数初值，当前计数到要输出反向时的处理
                    CE <= {CR[15:1],1'b0};//重装计数初值
                    OEflag <= CR[0];//OEflag重新赋值以防止新初始值写入
                    NULL_COUNT <= 0;
                    out0 <= ~out0;//计数到时反向    
                end else if(SR[0] == 1'b1) begin //对于BCD码计数
                    //做BCD码减2处理：注意'0'-'2 '的处理
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
                end else begin //否则，二进制计数减2处理 
                    CE = CE - 16'h0002;
                end
            end
        end        
    end 
    
    //SL：状态锁存器
    always @ (posedge wmode or posedge wrback)begin
        if(wmode) begin
        // 初始化
           SL <= 0;
        end else if(wrback & !id[4])begin
        // 读回状态字
           SL <= SR;
        end else begin
        // 锁存
           SL <= SL;
        end
    end  
  
    //OL：完成输出锁存器相关逻辑
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
    reg [2:0] rsta;//[0]表示读状态；[1]表示读低8位； [2]表示读高8位；
    always @ (posedge wrback or posedge wnowcount or posedge wmode) begin
        if(wmode) begin
            rsta  <= 3'b000;
        end else if(wnowcount)begin //读当前计数值
            // Serica: RW1(SR[5])RW0(SR[4]) = 01 只读低字节 10 高字节 11先低后高
            // Serica: 读状态即读状态字
            rsta[2]  <= SR[5];
            rsta[1]  <= SR[4];
            rsta[0]  <= 0;
        end else if(wrback) begin //读回命令
            rsta[2]  <= SR[5];
            rsta[1]  <= SR[4];
            rsta[0]  <= !id[4];    // 读回命令中D4=0表示需要锁存状态    
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
                                 od <= OL[7:0]; // Serica: 先读低字节 
                                 rflag <= 2'b01;
                             end else begin
                                 od <= OL[15:8];
                                 rflag <= 2'b11;
                             end
                           end 
                    3'b101:begin 
                             if(rflag == 2'b00) begin
                                od <= SL; // Serica: 先读状态      
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
