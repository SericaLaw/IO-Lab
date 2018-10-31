CODE SEGMENT    ; the start of code segment
ASSUME CS:CODE ; initialize CS register
START:
    MOV AH, 0H  ; get the switch's value
    INT 31H     ; get the switch's value
    INT 30H     ; display on leds
    JMP START
CODE ENDS   ; the end of code segment
    END START
