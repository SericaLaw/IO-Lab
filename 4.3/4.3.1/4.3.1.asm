;DATA SEGMENT
;    DIVIDER DW 10
;DATA ENDS

CODE SEGMENT 'CODE'
    ASSUME CS:CODE ;, DS:DATA
START:  MOV AH, 0
        INT 31H             ; READ FROM SWITCH
        AND DX, 1FFFH        ; REDUCE INPUT TO 13BIT. NOTE THAT SINCE 2^13=8192, THE RESULT HAS AT MOST 4 BITS
        MOV AX, DX           
        MOV CL, 0           ; THE NUMER TO ROTATE
        MOV BX, 0           ; SET BX TO 0. THE FINAL ANS IS SAVED TO [BX]
        MOV CH, 10
TRANS:  DIV CH         ; AX STORES THE RESULT WHILE DX STORES THE REMAINDERH. NOTE THAT THE RESULT HAS AT MOST 10
        SAL DX, CL          ; SHIFT DX TO THE LEFT 4/8/12/16BITS
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
        


        



