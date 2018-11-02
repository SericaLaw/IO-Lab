CODE SEGMENT 'CODE'
    ASSUME CS:CODE
START:  
INPUT_SESS: MOV AL, 0FFH     ; SET AL TO 1111 1111 B
            XOR AH, AH      ; SET AH=0
            INT 32H         ; ENABLE A[5:0]
            MOV DX, 0FFFFH  
            MOV AH, 1       
            INT 32H         ; SET A[3:0] TO FFFF
            XOR DX, DX      ; THE RESULT WOULD BE SAVED TO DX(DL), AND IT IS INITIALIED INTO 00H
            MOV CL, 4
SAVE_RES:   XOR AH, AH
            INT 33H         ; SAVE INPUT TO AL. THE REAL INPUT IS AL[3..0]
            CMP AL, 10H     ; COMPARE AL WITH 0. IF CF=1, THEN INPUT IS INVALID
            JC SAVE_RES
            CMP AL, 1AH     ; COMPARE AL WITH A. IF ZF=1, JUMP TO GUESS. ELSE IF CF = 0, INPUT IS INVALID.
            JZ GUESS_SESS
            JNC SAVE_RES
            SHL DL, CL      ; ROTATE CH TO ITS LEFT BY FOUR BITS
            AND AL, 0FH     ; DELETE A[4]
            OR DL, AL       ; SAVE THE NEWLY INPUT DIGIT TO DL
            MOV AH, 2
            INT 32H         ; SHOW THE NEWLY INPUT DIGIT.
            JMP SAVE_RES

GUESS_SESS: MOV BX, DX      ; REMOVE THE RESULT FROM REGISTER DX TO REGISTER BX(BL)
            MOV DX, 0FFFFH  ; SET A[7:4] TO FFFF
            MOV AH, 2
            INT 32H         ; HIDE THE TRUE RESULT AND SHOW FFFF INSTEAD ON A[7:4]

; DOES ANY MORE OPERATION NEED OT BE INSERTED?
; CAN WE USE SI TO SAVE THE NUMBER OF TRIALS?
            XOR SI, SI
            MOV DX, SI
            MOV AH, 1
            INT 32H         ; SET A[3:0] TO THE NUMBER OF TRIALS TAKEN

G_INPUT:    MOV CX, 2       
            XOR DX, DX
            XOR AH, AH
            INT 33H         ; READ FROM KEYBOARD, STORE IN AL
            CMP AL, 10H     ; COMPARE AL WITH 0. IF CF=1, THEN INPUT IS INVALID AND WE DO NOT SHOW IT
            JC G_INPUT
            CMP AL, 1AH     ; COMPARE AL WITH A. IF CF=0, INPUT IS INVALID AND WE DO NOT SHOW IT
            JZ SHOW_RES
            JC G_INPUT
            AND AL, 0FH     ; IF INPUT IS VALID, THEN
            ADD DL, DL      ; SHIFT DX LEFT 4 BITS
            ADD DL, DL
            ADD DL, DL
            ADD DL, DL
            OR DL, AL       ; SAVE DIGIT
            LOOP G_INPUT
            INC SI
            CMP DX, BX
            MOV DX, SI
            MOV AH, 1
            INT 32H         ; SET A[3:0] TO THE NUMBER OF TRIALS TAKEN
            JZ G_EQ         ; IF GUESS EQUALS TO THE TRUE RESULT
            JC G_LT         ; IF GUESS IS LESS THAN THE TRUE RESULT
G_GT:       XOR AH, AH      
            MOV DX, 8000H   ; YLED7=1
            INT 30H
            JMP G_INPUT
G_EQ:       XOR AH, AH
            XOR DX, DX      ; ALL LIGHTS ARE OFF
            INT 30H
            JMP NEXT_SESS
G_LT:       MOV DX, 80H     ; GLED7=1
            INT 30H
            JMP G_INPUT
SHOW_RES:   MOV DX, BX      ; SHOW THE TRUE RESULT IMMEDIATELLY AFTER PRESSING 'A'
            MOV AH, 2
            INT 32H         
            JMP NEXT_SESS   ; AND PRESS ANY BUTTON TO ENTER INPUT_SESS AGAIN
NEXT_SESS:  XOR AH, AH      ; ENTER A DIGIT 0~A AND ENTER THE NEXT INPUT SESSION
            INT 33H         ; ATTAIN THE RESULT AND SAVE TO AL
            CMP AL, 10H
            JC NEXT_SESS
            CMP AL, 1BH
            JC NEXT_SESS
            JMP INPUT_SESS

CODE ENDS
    END START




