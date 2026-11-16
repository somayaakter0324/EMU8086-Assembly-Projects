START:
    CALL MENU
    MOV AH,01H
    INT 21H
    CMP AL,'1'
    JE DISPLAY
    CMP AL,'2'
    JE BORROW
    CMP AL,'3'
    JE RETBOOK
    CMP AL,'4'
    JE SEARCH
    CMP AL,'5'
    JE AVAILABLE
    CMP AL,'6'
    JE EXIT
    JMP START

MENU PROC
    MOV DX,OFFSET interphase
    MOV AH,09H
    INT 21H
    RET
MENU ENDP

;  DISPLAY

DISPLAY PROC
    MOV CX,5
    MOV SI,0
NEXT_BOOK:
    ; title  (offset = size =32)
    MOV BX,SI
    SHL BX,5
    MOV DX,OFFSET titles
    ADD DX,BX
    MOV AH,09H
    INT 21H
    
    MOV DL,' '
    MOV AH,02H   ; space
    INT 21H          
   
    MOV BX,SI
    SHL BX,1
    MOV AX,counts[BX]     ; count  (offset = SI * 2, WORD array)
    ADD AL,'0'
    MOV DL,AL
    MOV AH,02H
    INT 21H     
    
    MOV DL,13
    MOV AH,02H   ; newline
    INT 21H
    MOV DL,10
    MOV AH,02H
    INT 21H
    INC SI
    LOOP NEXT_BOOK
    JMP START
DISPLAY ENDP 


; BORROW (was missing) 

BORROW PROC
    MOV DX,OFFSET msgIdx
    MOV AH,09H
    INT 21H
    MOV AH,01H
    INT 21H
    SUB AL,'0'
    CMP AL,1
    JL BBAD
    CMP AL,5
    JG BBAD
    DEC AL              ; make 0-based
    XOR AH,AH           ; clear AH so SI is clean
    MOV SI,AX
    SHL SI,1            ; word offset
    MOV AX,counts[SI]
    CMP AX,0
    JE BUN             ; 0 copies -> block (no decrement)
    DEC counts[SI]
    MOV DX,OFFSET msgOk
    MOV AH,09H
    INT 21H
    JMP START
BUN:
    MOV DX,OFFSET msgUn
    MOV AH,09H
    INT 21H
    JMP START
BBAD:
    MOV DX,OFFSET msgBad
    MOV AH,09H
    INT 21H
    JMP START
BORROW ENDP

; RETURN 
RETBOOK PROC
    MOV DX,OFFSET msgIdx
    MOV AH,09H
    INT 21H
    MOV AH,01H
    INT 21H
    SUB AL,'0'
    CMP AL,1
    JL RBAD
    CMP AL,5
    JG RBAD
    DEC AL
    XOR AH,AH
    MOV SI,AX
    SHL SI,1
    INC counts[SI]
    MOV DX,OFFSET msgOk
    MOV AH,09H
    INT 21H
    JMP START
RBAD:
    MOV DX,OFFSET msgBad
    MOV AH,09H
    INT 21H
    JMP START
RETBOOK ENDP

;  SEARCH 
; reads one character, lists every title that CONTAINS it
SEARCH PROC
    MOV DX,OFFSET msgChar
    MOV AH,09H
    INT 21H
    MOV DX, OFFSET buffer
    MOV AH,0AH
    INT 21H
    MOV AL, buffer+2
    MOV schar,AL        ; save search char in memory (safe)
    MOV DL,13
    MOV AH,02H
    INT 21H
    MOV DL,10
    MOV AH,02H
    INT 21H
    MOV CX,5
    MOV SI,0
S1:
    MOV BX,SI
    SHL BX,5
    MOV DI,OFFSET titles
    ADD DI,BX
SCAN:
    MOV AL,[DI]
    CMP AL,'$'          ; end of this title?
    JE NEXT             ; char not found here
    CMP AL,schar        ; compare with saved char in memory
    JE FOUND
    INC DI
    JMP SCAN
FOUND:
    PUSH CX
    MOV DX,OFFSET titles
    ADD DX,BX
    MOV AH,09H
    INT 21H
    MOV DL,13
    MOV AH,02H
    INT 21H
    MOV DL,10
    MOV AH,02H
    INT 21H
    POP CX
NEXT:
    INC SI
    LOOP S1
    JMP START
SEARCH ENDP

;AVAILABLE 

AVAILABLE PROC
    MOV CX,5
    MOV SI,0
    MOV DL,13
    MOV AH,02H
    INT 21H
    MOV DL,10
    MOV AH,02H
    INT 21H
    
A1:
    MOV BX,SI
    SHL BX,1            ; word offset for counts
    CMP counts[BX],0
    JE SKIP
    MOV BX,SI
    SHL BX,5            ; title offset
    MOV DX,OFFSET titles
    ADD DX,BX
    MOV AH,09H
    INT 21H
    MOV DL,13
    MOV AH,02H
    INT 21H
    MOV DL,10
    MOV AH,02H
    INT 21H
SKIP:
    INC SI
    LOOP A1
    JMP START
AVAILABLE ENDP

EXIT:
    MOV AH,4CH
    INT 21H

;  DATA 
interphase db 13,10,'===== LIBRARY MANAGEMENT SYSTEM =====',13,10
     db '1. Display Catalog',13,10
     db '2. Borrow Book',13,10
     db '3. Return Book',13,10
     db '4. Search Book',13,10
     db '5. Available Books',13,10
     db '6. Exit',13,10,13,10
     db 'Enter Choice: $'

; each title =  total 32 bytes

titles db 'C Programming','$',18 dup(0)       ; 13+1+18 = 32
       db 'Data Structures','$',16 dup(0)     ; 15+1+16 = 32
       db 'Algorithms','$',21 dup(0)          ; 10+1+21 = 32
       db 'Math Book','$',22 dup(0)           ;  9+1+22 = 32
       db 'Physics','$',24 dup(0)             ;  7+1+24 = 32

counts dw 3,0,5,2,1

msgIdx  db 13,10,'Enter index (1-5): $'
msgChar db 13,10,'Enter title: $'
msgOk   db 13,10,'Done!$'
msgUn   db 13,10,'Unavailable!$'
msgBad  db 13,10,'Invalid index!$' 
schar   db 0
buffer    DB 30          
              DB ?           
              DB 30 DUP(?)