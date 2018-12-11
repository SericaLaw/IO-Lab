ASSUME CS:CODE,  DS: DATA 

DATA SEGMENT
    COUNT DB ?
    STATE DB ?
DATA ENDS

CODE SEGMENT
START:
    MOV AX,  80H
    MOV DS,  AX
    MOV BYTE PTR COUNT, 10
    MOV BYTE PTR STATE, 1
    ; MODIFY IVT
    CLI							
    MOV AX, 0 	; IVT 0000H~03FFH
    MOV ES, AX						
    MOV SI, 40H	; 10H*4
    MOV AX, OFFSET SERVICE	; IP
    MOV ES:[SI], AX
    MOV AX, CS	; CS
    MOV ES:[SI+2], AX  
	; INIT 8259
	; ICW1
    MOV AL, 00010000B				
    OUT 50H, AL
	; ICW2
    MOV AL, 00010000B	; 10H
    OUT 52H, AL

    ; INIT 8254
    MOV AL, 00110110B	; T/C0
    OUT 46H, AL
    MOV AX, 10000	; 1000HZ
    OUT 40H, AL
    MOV AL, AH
    OUT 40H, AL
    MOV AL, 01110110B	; T/C1
    OUT 46H, AL
    MOV AX, 1000 ; 1HZ
    OUT 42H, AL
    MOV AL, AH
    OUT 42H, AL

    ; INIT 8255
    MOV AL, 10000000B;
	OUT 66H, AL
    ; DISPLAY
    MOV AL, 00000001B
    OUT 64H, AL

    STI
    JMP $
    

SERVICE PROC FAR
    PUSH DS
    STI

	CMP STATE, 1H
	JZ S1
	CMP STATE, 2H
	JZ S2
	CMP STATE, 3H
	JZ S3
	CMP STATE, 4H
	JZ S4
S1:
	; GD1 (PA5), RD0 (PA2)
	MOV AL, 24H
	OUT 60H, AL
	DEC COUNT
	CMP COUNT, 0
	MOV AL, COUNT
	OUT 62H, AL
	JA DONE

	MOV COUNT, 4
	MOV STATE, 2
	JMP DONE
S2:
	; YD1 (PA6), RD0 (PA2)
	TEST COUNT, 1H
	JZ S2A ; ENABLE YD1 IF COUNT IS EVEN
    ; DISABLE YD1
	MOV AL, 04H
	OUT 60H, AL
	JMP S2B
S2A:
	MOV AL, 44H
	OUT 60H, AL
S2B:
	DEC COUNT
	CMP COUNT, 0
	MOV AL, COUNT
	OUT 62H, AL
	JA DONE

	MOV COUNT, 10
	MOV STATE, 3
	JMP DONE
S3:
	; GD0 (PA0), RD1(PA7)
	MOV AL, 81H
	OUT 60H, AL
	DEC COUNT
	CMP COUNT, 0
	MOV AL, COUNT
	OUT 62H, AL
	JA DONE

	MOV COUNT, 4
	MOV STATE, 4
	JMP DONE
S4:
	; YD0 (PA1), RD1 (PA7)
	TEST COUNT, 1H
	JZ S4A

	MOV AL, 80H
	OUT 60H, AL
	JMP S4B
S4A:
	MOV AL, 82H
	OUT 60H, AL
	
S4B:
	DEC COUNT
	CMP COUNT, 0
	MOV AL, COUNT
	OUT 62H, AL
	JA DONE

	MOV COUNT, 10
	MOV STATE, 1
	JMP DONE

DONE:
	CLI

    MOV AL, 01100000B			
    OUT 50H, AL
    POP DS

    IRET

SERVICE ENDP

CODE ENDS   
END START
