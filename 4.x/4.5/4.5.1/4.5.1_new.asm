DATA SEGMENT
    OPD_DEC DW ?
    OPD_BIN DW ?
    OPD_A DW ?
    OPD_B DW ?
    INPUT DW 0
    OP DB 0
    TEN DW 10
DATA ENDS

CODE SEGMENT 'CODE'
    ASSUME CS: CODE, DS: DATA
START:
INIT:
    ; INIT DS
    MOV AX, 0080H
    MOV DS, AX
    MOV INPUT, 0
    ; ENABLE A[7..0]
    XOR AH, AH
    MOV AL, 0FFH
    INT 32H
WAIT_INPUT:
    XOR DX, DX
    MOV CL, 4
WAIT_INPUT_LOOP:
    ; READ INPUT
    XOR AH, AH
    INT 33H
    ; TEST WHEATHER INPUT IS VALID
    TEST AL, 10H
    ; IF NOT VALID, KEEP WAITING
    JZ WAIT_INPUT_LOOP
    ; ELSE CLEAR STATUS BIT
    AND AL, 0FH
    ; IF (AL)>=OA, IT IS AN OPERATOR
    CMP AL, 0AH
    JNC INPUT_OP    
    ; ELSE IT IS A DIGIT
    SHL DX, CL
    OR DL, AL
    ; DISPLAY NEW INPUT
    MOV AH, 1
    INT 32H
    JMP WAIT_INPUT_LOOP
INPUT_OP:
    ; IF OPERATOR IS ' ', DO NOTHING
    CMP AL, 0EH
    JZ WAIT_INPUT
    ; ELSE IF OPERATOR IS '=', CACULATE AND DISPLAY RESULT
    CMP AL, 0FH
    JZ INPUT_EQ

    ; IF INPUT = 1, DO NOTHING AND WAIT '='
    CMP INPUT, 1
    JNZ WAIT_INPUT_LOOP
    
    ; ELSE, STORE THE FIRST OPD IN OPD_A AND SAVE OP
    INC INPUT
    MOV OPD_DEC, DX
    CALL DEC_TO_BIN
    PUSH OPD_BIN
    POP OPD_A   ; SAVE OPD_A
    ; DEBUG
    ; PUSH AX
    ; MOV AH, 2
    ; MOV DX, OPD_A
    ; INT 32H
    ; POP AX
    ; SAVE OP
    SUB AL, 0AH
    MOV OP, AL
    ; DISPLAY OP ON LED
    PUSH CX
    PUSH DX ; SAVE SCENE
    MOV DX, 0001H
    MOV CL, AL
    SHL DX, CL
    XOR AH, AH
    INT 30H
    POP DX  ; RETRIEVE SCENE
    POP CX
    
    JMP WAIT_INPUT
INPUT_EQ:
    ; SAVE OPD_B
    MOV OPD_DEC, DX
    CALL DEC_TO_BIN
    PUSH OPD_BIN
    POP OPD_B
    
    ; DEBUG
    ; PUSH AX
    ; MOV AH, 2
    ; MOV DX, OPD_B
    ; INT 32H
    ; POP AX
    
    ; CALCULATE AND DISPLAY
    CALL CALCULATE
   
    JMP START

CALCULATE PROC
    MOV AX, OPD_A
    MOV BX, OPD_B
    MOV CL, OP
    XOR DX, DX
    CMP CL, 00H
    JZ IS_ADD
    CMP CL, 01H
    JZ IS_SUB
    CMP CL, 02H
    JZ IS_MUL
    CMP CL, 03H
    JZ IS_DIV
IS_ADD:     
    ADD AX, BX
    ADC DX, 0
    JMP R_OUT       ; REGULAR OUTPUT
IS_SUB:     
    SUB AX, BX
    JC E_OUT
    JMP R_OUT
IS_MUL:     
    MUL BX
    CMP DX, 1
    JNC E_OUT       ; IF DX>=1, THEN THE ANSWER IS INVALID AND JMP TO E_OUT
    JMP R_OUT
IS_DIV:    
    CMP BX, 0   ; BX SHOULD NOT BE ZERO
    JZ E_OUT
    XOR DX, DX      ; SERICA: SET DX TO ZERO
    DIV BX          ; DX(remainder), AX(result)<-(DX:AX)/(BX)
    JMP DIV_OUT
E_OUT:      
    MOV DX, 0E000H   ; SHOW E ON THE LEFTMOST DIGIT
    MOV AH, 2
    INT 32H         ; OUTPUT E
    XOR DX, DX
    MOV AH, 1
    INT 32H
    JMP WAIT_IN
R_OUT:
    CALL BIN_TO_DEC
DISPLAY: 
    ; DX STORES THE HIGH DIGITS WHILE BX STORES THE LOW DIGITS
    MOV AH, 2

    INT 32H ; SHOW THE HIGH DIGITS' INPUT
    MOV DX, BX
    ; MOV AX, DX
    ; CALL BIN_TO_DEC
    ; MOV DX, AX

    MOV AH, 1
    INT 32H
    JMP WAIT_IN
DIV_OUT:         ]
    MOV DI,DX
    XOR DX, DX
    CALL BIN_TO_DEC
    MOV AX,DI
    XOR DX, DX
    MOV DI,BX
    CALL BIN_TO_DEC
    MOV DX,BX
    MOV BX,DI
    JMP DISPLAY
WAIT_IN:    
    XOR AH, AH
    INT 33H
    TEST AL, 10H     
    JZ WAIT_IN
    XOR DX, DX
    INT 30H
    MOV AH, 1
    INT 32H
    MOV AH, 2
    INT 32H
    RET
CALCULATE ENDP

DEC_TO_BIN PROC
; PARAM OPD_DEC:
; RETURN OPD_BIN:
    ; SAVE SCENE
    PUSH AX
    PUSH CX
    ; INIT
    XOR AX, AX  ; AX STORES THE RESULT
    MOV CL, 12  ; USE CL AS LOOP COUNTER
DEC_TO_BIN_LOOP:
    MOV DI, 000FH ; USE DI AS MASK
    SHL DI, CL      ; ADJUST MASK ACCORDING TO CL
    MOV DX, OPD_DEC
    AND DX, DI
    SHR DX, CL
    MOV SI, DX  ; 
    MUL TEN     ; (AX) *= 10, MIND IT WILL ALTER DX TOO
    ADD AX, SI  ; (AX) += CURRENT DIGIT
    SUB CL, 4
    CMP CL, 0
    JGE DEC_TO_BIN_LOOP
    MOV OPD_BIN, AX

    ; RETRIEVE SCENE
    POP CX
    POP AX
    RET
DEC_TO_BIN ENDP

BIN_TO_DEC PROC
; PARAM DX:AX:  BIN
; RETURN DX:BX: DEC
    XOR BX, BX
    XOR SI, SI
    MOV CX, 4
BIN_TO_DEC_LOOP:
    PUSH CX
    MOV CX, SI
    DIV TEN     ; DX(remainder), AX(result)<-(DX:AX)/10 
    SHL DX, CL
    ADD SI, 4
    OR BX, DX
    XOR DX, DX  ; DO NOT FORGET CLEAR DX
    POP CX
    CMP AX, 0
    JNZ BIN_TO_DEC_LOOP
    DIV TEN
    RET
BIN_TO_DEC ENDP

CODE ENDS
END START
