DATA SEGMENT 'DATA'
    DIVIDER DW 10
DATA ENDS


CODE SEGMENT 'CODE'
    ASSUME CS:CODE, DS:DATA
START:      MOV AX, 0080H
            MOV DS, AX
            XOR AX, AX
            MOV AL,0FH      ; Serica: 设置数码管d3~d0允许显示
            INT 32H         ; Serica: 设置数码管d3~d0允许显示
            XOR AL,AL       ; Serica: AL清零
            INT 31H         ; SAVE (A,B)->(DH,DL)
INPUT:      XOR AH, AH
            INT 33H         ; READ THE CURRENT INPUT AND SAVE TO AL
            ;TEST AL, 10H    ; IF AL[4]=0, THERE IS NO INPUT, AND WE WAIT FOR AN INPUT AGAIN
            ;JZ INPUT    
            ;TEST AL, 0FFH   ; IF AL = 0, INPUT IS INVALID 
            ;JZ EXCEPTION
            ;CMP AL, 4       ; IF AL >=4, INPUT IS INVALID (CF=0)
            ;JNC EXCEPTION
            CMP AL, 10011B       ; IF AL==10011B, MULTIPLICATION  (CF=0,ZF=0)
            JZ MULTIPLICATION
            CMP AL, 10010B
            JZ SUBTRACTION
            CMP AL, 10001B
            JZ ADDITION
            JMP START ; Serica: 除了上面三种情况，其余输入都是非法的，直接返回START
ADDITION:   MOV CL, DH ; STORE THE VALUE OF NUMBER A INTO CL
            AND DX, 0FFH ; 
            ADD DX, CX      ; SAVE THE RESULT TO DX STILL
            CMP DX, 10000   ; Serica: COMPARE THE RESULT WITH 10000
            JNC EEE   ; CF=0, => (DX)>=10000(>9999) => DISPLAY E
            JMP OUTPUT
SUBTRACTION:    MOV CL, DH
                AND DX, 0FFH
                AND CX, 0FFH
                SUB CX, DX
                MOV DX, CX
                JC EEE
                JMP OUTPUT
MULTIPLICATION: MOV AL, DH
                ; AND DX, 0FFH Serica: not necessary
                MUL DL
                CMP AX, 10000   ; COMPARE AX AND 10000. IF AX > 9999(CF=0), JUMP TO EEE
                JNC EEE
                MOV DX, AX
                JMP OUTPUT
EEE:        MOV DX, 0EEEEH
            MOV AH, 1   ; Serica：是显示到数码管上orz
            INT 32H     ; Serica：是显示到数码管上orz
            JMP START
EXCEPTION:  MOV DX, 0FFFFH
            MOV AH, 0
            INT 30H         ; PRINT FFFF, INDICATING AN END
            JMP INPUT       ; JUMP TO INPUT AGAIN

OUTPUT: 
        MOV AX, DX           
        MOV CL, 0           ; THE NUMER TO ROTATE
        MOV BX, 0           ; SET BX TO 0. THE FINAL ANS IS SAVED TO BX
        MOV SI, 10          ; SI SHOULD ONLY BE SET ONCE DURING THE LOOP. OTHERWISE IT'S A WASTE OF TIME
        ; MOV AH, 1
        ; INT 32H
        ; MOV AX, DX
TRANS:  XOR DX, DX
        DIV SI              ; AX STORES THE RESULT WHILE DX STORES THE REMAINDERH. NOTE THAT THE RESULT HAS AT MOST 10
        SAL DX, CL          ; SHIFT DX TO THE LEFT 0/4/8/12BITS
        OR  BX, DX          ; SAVE THE RESULT TO [BX]
        ADD CL, 4           ; NEXT TIME, SHIFT 4BITS MORE
        CMP AX, 0      ; TEST IF THERE ARE NO RESULTS
        ; PUSH AX
        ; MOV DX, 101H
        ; MOV AH, 1
        ; INT 32H
        ; POP AX
        JNZ TRANS           ; IF THE RESULT IS 0, THEN LOOP ENDS
        ; MOV DX, 123H
        MOV AH, 1
        MOV DX, BX
        INT 32H
        JMP START
CODE ENDS
    END START
