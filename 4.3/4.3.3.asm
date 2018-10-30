DATA SEGMENT
    DIVIDER DW 10
DATA ENDS


CODE SEGMENT
    ASSUME CS:CODE
START:      MOV AH, 0
            INT 31H         ; SAVE (A,B)->(DH,DL)
INPUT:      MOV AH, 0
            INT 33H         ; READ THE CURRENT INPUT AND SAVE TO AL
            TEST AL, 10H    ; IF AL[4]=0, THERE IS NO INPUT, AND WE WAIT FOR AN INPUT AGAIN
            JZ INPUT    
            TEST AL, 0FFH   ; IF AL = 0, INPUT IS INVALID 
            JZ EXCEPTION
            CMP AL, 4       ; IF AL >=4, INPUT IS INVALID (CF=0)
            JNC EXCEPTION
            CMP AL, 3       ; IF AL==3, MULTIPLICATION  (CF=0,ZF=0)
            JZ MULTIPLICATION
            CMP AL, 2
            JZ SUBTRACTION
            CMP AL, 1
            JZ ADDITION
ADDITION:   MOV CL, DH
            AND DX, 0FFH
            ADD DX, CX      ; SAVE THE RESULT TO DX STILL
            JMP OUTPUT
SUBTRACTION:    MOV CL, DH
                AND DX, 0FFH
                SUB DX, CX
                JS EEE
                JMP OUTPUT
MULTIPLICATION: MOV AL, DH
                AND DX, 0FFH
                MUL DL
                CMP AX, 10000   ;COMPARE AX AND 10000. IF AX > 9999(CF=0), JUMP TO EEE
                JNC EEE
                MOV DX, AX
                JMP OUTPUT
EEE:        MOV DX, 0EEEEH
            MOV AH, 0
            INT 30H
            JMP START
EXCEPTION:  MOV DX, 0FFFFH
            MOV AH, 0
            INT 30H         ; PRINT FFFF, INDICATING AN END
            JMP INPUT       ; JUMP TO INPUT AGAIN

OUTPUT: MOV AX, DX           
        MOV CL, 0           ; THE NUMER TO ROTATE
        MOV BX, 0           ; SET BX TO 0. THE FINAL ANS IS SAVED TO [BX]
TRANS:  DIV DIVIDER         ; AX STORES THE RESULT WHILE DX STORES THE REMAINDERH. NOTE THAT THE RESULT HAS AT MOST 10
        SAL DX, CL          ; SHIFT DX TO THE LEFT 0/4/8/12BITS
        OR  BX, DX          ; SAVE THE RESULT TO [BX]
        ADD CL, 4           ; NEXT TIME, SHIFT 4BITS MORE
        TEST AX, 0FFFFH      ; TEST IF THERE ARE NO RESULTS
        JNZ TRANS           ; IF THE RESULT IS 0, THEN LOOP ENDS
        MOV AH, 1
        MOV DX, BX
        INT 32H
        JMP START
CODE ENDS
    END START
