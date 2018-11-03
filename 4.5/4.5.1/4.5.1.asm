CODE SEGMENT 'CODE'
    ASSUME CS:CODE
START:      MOV DX, 0
            MOV CL, 4
            MOV AH, 0
            INT 30H         ; DISABLE ALL THE LIGHTS
IN_DIGIT:   MOV AH, 0
            MOV AL, 0FH     ; THE FOUR LOWER DIGITS ALIGHT
            INT 32H         ; SHOW THE CURRENT OPD
            INT 33H         ; READ INPUT FROM KEYBOARD
            TEST AL, 10H    ; TEST IF THERE IS AN INPUT
            JZ IN_DIGIT     ; IF AL[4]=0, KEEP READING
            AND AL, 10H     
            TEST AL,0AH     ; IF X>='A', THEN WE JUMP TO 
            JNC IS_OP
            SHL DX, CL      ; IF X IS A DIGIT, MOVE DX FOUR BITS AND
            OR DL, AL       ; MOVE AL'S LAST FOUR DIGIT TO DL
            JMP IN_DIGIT
IS_OP:      MOV AH, 1
            INT 32H         ; SHOW THE LAST INPUTED DIGIT
            CMP AL, 0FH     ; IF THE INPUT IS ' ', THEN IT'S INVALID
            JMP IN_DIGIT    ; IGNORE THE INPUT AND GET ANOTHER
            PUSH DX         ; SAVE THE LAST OPD IN STACK
            CMP AL, 0EH     ; IF THE INPUT IS '='
            JZ CALCULATE    ; START THE CALCULATION SESSION
            MOV AH, 0
            PUSH AX         ; SAVE THE OP IN STACK
            SUB AX, 0AH     ; IF ADDITION, SET GLED0 ALIGHT
            ; 本来想用跳转的，突然发现sub就行
            ; 我可真是个小天才(( •�? ω •�? )�??)
            MOV DX, AX      ; STORE THE KIND OF OPD IN DX
            MOV AX, 0
            INT 30H         ; OUTPUT THE LIGHTS
            MOV DX, 0
            JMP IN_DIGIT
CALCULATE:  POP BX          ; THE LAST OPD
            POP CX          ; OP
            POP AX          ; THE FIRST OPD
            MOV DX, 0    
            CMP CX, 0AH 
            JZ IS_ADD
            CMP CX, 0BH
            JZ IS_SUB
            CMP CX, 0CH
            JZ IS_MUL
            CMP DX, 0DH
            JZ IS_DIV
IS_ADD:     ADD AX, BX
            JC E_OUT
            JMP R_OUT       ; REGULAR OUTPUT
IS_SUB:     SUB AX, BX
            JC E_OUT
            JMP R_OUT
IS_MUL:     MUL BX
            CMP DX, 1
            JNC E_OUT       ; IF DX>=1, THEN THE ANSWER IS INVALID AND JMP TO E_OUT
            JMP R_OUT
IS_DIV:     TEST BX, 0FFFFH
            JZ E_OUT
            DIV BX
            SHL DX, CL      ; SHIFT DX LEFT FOUR BITS
            OR AX, DX
            JMP R_OUT
E_OUT:      MOV AL, 80H     ; ALIGHT THE LEFTMOST DIGIT
            MOV AH, 0
            INT 32H
            MOV DX, 0E000H   ; SHOW E ON THE LEFTMOST DIGIT
            MOV AH, 2
            INT 32H         ; OUTPUT E
WAIT_IN:    MOV AH, 0
            INT 33H
            TEST AL, 10F     
            JZ WAIT_IN      
            JMP START
R_OUT:      PUSH AX ;DX STORES THE HIGH DIGITS WHILE AX STORES THE HIGH DIGITS 
            MOV AH, 2
            INT 32H ; SHOW THE HIGHI DIGITS' INPUT
            POP DX
            MOV AH, 1
            INT 32H
            JMP WAIT_IN
CODE ENDS
    END START

