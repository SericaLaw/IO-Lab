ASSUME DS:DATA, CS:CODE

DATA SEGMENT
    TABLE DB 0, 1, 4, 9, 16, 25, 36, 49, 64, 81
DATA ENDS

CODE SEGMENT
START:
    MOV AX, 0080H   ; DATA segment start from 0080H
    MOV DS, AX  ; reset DS register
    INT 31H     ; read input into DX
    MOV BX, OFFSET TABLE    ; set base address
    MOV AL, DL              ; set offset
    XLAT    ; look up for the table
    MOV DL, AL
    MOV AL, 03H
    INT 32H     ; AH=00H
    INC AH
    INT 32H     ; display
    JMP START
CODE ENDS
    END START
