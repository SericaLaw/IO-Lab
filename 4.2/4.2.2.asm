CODE SEGMENT
ASSUME CS:CODE
START:
; 从拨码开关输入两个8位二进制数（A、B）
; 将这两个数的和以16进制数形式输出到数码管上
; A等于SW15~SW8的值
; B等于SW7~SW0的值
    MOV AH, 0
    INT 31H     ; read input
    MOV CX, DX  ; copy DX to CX
    ADD DL, DH  ; add two 8-bit digits
    ADC DH, 0   ; add carry to DH
    SUB DH, CX  ; figure out whether there's a carry
    MOV AL, 07H
    MOV AH, 00H
    INT 32H
    INC AH
    INT 32H     ; display sum
    JMP START
CODE ENDS
    END START