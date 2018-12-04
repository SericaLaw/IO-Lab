CODE SEGMENT 'CODE'
    ASSUME CS:CODE
START:
INPUT:  MOV AH, 0
        INT 33H
        CMP AL, 10001B  ;IF AL < 10001, CF = 1
        JC INPUT
        CMP AL, 10111B  ;IF INPUT >= 7, CF= 0
        JNC INPUT
        AND AL, 0FH
        MOV CX, AX
        MOV AX, 1
        ;MOV DX, 1       ; THE RESULT WOULD BE SAVED DIRECTLY TO DX
FAC:    
        MUL CX
        LOOP FAC
        MOV SI, 10
        MOV CL, 0
        MOV BX, 0
OUTPUT: XOR DX, DX
        DIV SI
        SAL DX, CL
        OR BX, DX
        ADD CL, 4
        TEST AX, 0FFFFH
        JNZ OUTPUT
        MOV AL, 0FH
        MOV AH, 0
        INT 32H     ; ENABLE A[3:0] 
        MOV AH, 1
        MOV DX, BX
        INT 32H     ; SHOW THE RESULT
        JMP START
CODE ENDS
    END START

        


        
