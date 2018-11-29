DATA SEGMENT
    OPD_BIN DW ?
    OPD_DEC DW ?
    OPD_A DW ?
    OPD_B DW ?
    OP DB ?
    INPUTED DW 0
    TEN DW 10
DATA ENDS
CODE SEGMENT 'CODE'
    ASSUME CS:CODE, DS:DATA
START:
INIT:
    MOV AX, 80H
    MOV DS, AX  ; INIT DS
    XOR AX, AX
    XOR DX, DX
    INT 30H         ; DISABLE ALL THE LED LIGHTS
    MOV AL, 0FFH
    INT 32H         ; ENABLE A[7..0]
IN_DIGIT_S:
    XOR DX, DX      ;
IN_DIGIT:  
    XOR AH, AH
    INT 33H         ; READ INPUT FROM KEYBOARD
    TEST AL, 10H    ; TEST IF THERE IS AN INPUT
    JZ IN_DIGIT     ; IF AL[4]=0, KEEP READING
    AND AL, 0FH     ; ELSE
    CMP AL, 0AH      
    JNC IS_OP       ; IF X>='A', THEN WE JUMP TO    
    MOV CL, 4
    SHL DX, CL      ; IF X IS A DIGIT, MOVE DX FOUR BITS AND
    OR DL, AL       ; MOVE AL'S LAST FOUR DIGIT TO DL
    MOV AH, 2
    INT 32H         ; SHOW THE LAST INPUTED DIGIT
    JMP IN_DIGIT
IS_OP:      
    ; MOV AH, 1
    ; INT 32H         ; SHOW THE LAST INPUTED DIGIT
    CMP AL, 0EH     ; IF THE INPUT IS ' ', THEN IT'S INVALID
    ; JMP IN_DIGIT    ; IGNORE THE INPUT AND GET ANOTHER
    JZ IN_DIGIT_S     ; SERICA: SHOULD BE JZ IN_DIGIT
    PUSH DX         ; SAVE THE LAST OPD IN STACK
    CMP AL, 0FH     ; IF THE INPUT IS '='
    JZ CALCULATE    ; START THE CALCULATION SESSION
    MOV CX, AX
    PUSH AX         ; SAVE THE OP IN STACK
    SUB CX, 0AH     ; IF ADDITION, SET GLED0 ALIGHT
    ; PUSH CX
    MOV DX, 1
    ; MOV CL, AL
    SHL DX, CL
    XOR AH, AH
    INT 30H
    ; POP CX
  
    JMP IN_DIGIT_S
CALCULATE:  
    POP OPD_DEC          ; THE LAST OPD
    CALL DEC_TO_BIN
    MOV BX, OPD_BIN
      ; DEBUG
    MOV DX, OPD_BIN
    MOV AH, 2
    INT 32H
    ; POP BX
    POP CX          ; OP
    POP AX
    ; POP SI          ; THE FIRST OPD
    ; CALL DEC_TO_BIN
    ; MOV AX, DI

    ; MOV DX, 0    
    CMP CX, 0AH 
    JZ IS_ADD
    CMP CX, 0BH
    JZ IS_SUB
    CMP CX, 0CH
    JZ IS_MUL
    CMP DX, 0DH
    JZ IS_DIV
IS_ADD:     
    ADD AX, BX
    JC E_OUT
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
    TEST BX, 0FFFFH ; BX SHOULD NOT BE ZERO
    JZ E_OUT
    XOR DX, DX      ; SERICA: SET DX TO ZERO
    DIV BX          ; DX(remainder), AX(result)<-(DX:AX)/(BX)
    ; MOV CL, 4       ; SERICA: THE "POP CX" HAS CHANGED CL
    ; SHL DX, CL      ; SHIFT DX LEFT FOUR BITS
    ; OR AX, DX
    JMP R_OUT
E_OUT:      
    MOV AL, 80H     ; ALIGHT THE LEFTMOST DIGIT
    MOV AH, 0
    INT 32H
    MOV DX, 0E000H   ; SHOW E ON THE LEFTMOST DIGIT
    MOV AH, 2
    INT 32H         ; OUTPUT E
WAIT_IN:    
    XOR AH, AH
    INT 33H
    TEST AL, 10F     
    JZ WAIT_IN      
    JMP START
R_OUT:      
    PUSH AX ;DX STORES THE HIGH DIGITS WHILE AX STORES THE LOW DIGITS 
    MOV AH, 2

    INT 32H ; SHOW THE HIGH DIGITS' INPUT
    POP DX
    ; MOV AX, DX
    ; CALL BIN_TO_DEC
    ; MOV DX, AX
    MOV AH, 1
    INT 32H
    JMP WAIT_IN

DEC_TO_BIN PROC
; PARAM:    SI: DEC NUM
; RETURN:   DI: BIN NUM
    PUSH AX ; AX STORES THE RESULT
    PUSH BX ; USE BX AS MASK
    PUSH CX ; USE CX AS LOOP COUNTER
    PUSH DX ; DX STORES CURRENT DIGIT

    XOR AX, AX  ; INIT AX
    XOR DI, DI  ; INIT DI
    MOV CX, 12
DEC_TO_BIN_LOOP:
    MOV DX, OPD_DEC  ; SAVE A COPY OF DEC NUM
    MOV BX, 000FH   ; MASK
    SHL BX, CL  ; ADJUST THE MASK ACCORDING TO CL

    AND DX, BX
    SHR DX, CL  ; EXTRACT CURRENT DIGIT AND SAVE IT TO DX
    MOV SI, DX  ; STORE THE RESULT IN SI
    MOV BX, 1O
    MUL BX      ; (AX) *= 10
    ADD AX, SI  ; (AX) += (DX)

    SUB CL, 4   ; LOOP CONTROL
    CMP CL, -4  ; END
    JNZ DEC_TO_BIN_LOOP

    MOV OPD_BIN, AX  ; RETURN PARAM
    
    POP DX
    POP CX
    POP BX
    POP AX      ; RETRIEVE SCENE
    RET
DEC_TO_BIN ENDP

BIN_TO_DEC PROC
; PARAM: (DX:AX) AS BIN NUM
; RETURN: (DX:AX) AS DEC NUM
    PUSH BX
    PUSH CX
    PUSH DX
    PUSH SI

    MOV CL, 0
    MOV BX, 0
    MOV SI, 10
BIN_TO_DEC_LOOP:
    XOR DX, DX
    DIV SI
    SAL DX, CL
    OR BX, DX
    ADD CL, 4
    CMP AX, 0
    JNZ BIN_TO_DEC_LOOP
    MOV AX, BX

    POP SI
    POP DX
    POP CX
    POP BX
    RET
BIN_TO_DEC ENDP
CODE ENDS
    END START
    
