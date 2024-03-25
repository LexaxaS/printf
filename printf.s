global MyPrintf

;-------------------------------------------------------------;

BufLen equ 1024
EOL equ 00

;-------------------------------------------------------------;

section .bss


buffer resb BufLen

;-------------------------------------------------------------;

section .data


hexTable    db "0123456789ABCDEF"

;--------------------------------------------------------------;

section .text

;--------------------------------------------------------------;
;   
; Entry: format string - rdi
;            arguments - rsi, rdx, rcx, r8, r9, stack
;
;--------------------------------------------------------------;

MyPrintf:
        pop r11

        push r9
        push r8
        push rcx
        push rdx
        push rsi
        push rdi

        push r11

        push rbp
        mov rbp, rsp

        call MyPrintfAsm

        pop rbp 

        pop r11

        add rsp, 6 * 8

        push r11

        ret

;--------------------------------------------------------------;
;
; Entry: format string - rdi
;            arguments - stack
;
;--------------------------------------------------------------;

MyPrintfAsm:

    mov rsi, [rbp + 16]
    mov rdi, buffer
    xor rbx, rbx
        
    ;-----------------------------------------------------------;
    ;
    ; Gets symbols
    ;
    ;-----------------------------------------------------------;
    .stringParse:
        xor rax, rax

        lodsb

        cmp al, `\0`
        je .MyPrintfAsm__End

        cmp al, '%'
        je .parseSpecifier

        mov [rdi], al
        inc rdi

        jmp .stringParse

    ;-----------------------------------------------------------;
    ;
    ; Gets the symbol after percent
    ;
    ;-----------------------------------------------------------;

    .parseSpecifier:
        xor rax, rax

        lodsb

        cmp al, '%'
        je .percentSym

        cmp al, 'a'
        jb .wrongLetter

        cmp al, 'z'
        ja .wrongLetter

        sub al, 'a'

        mov rax, [.jumpTable + 8 * rax]
        jmp rax

    ;------------------------------------------------------------;
    ;
    ; Jump Table
    ;
    ;------------------------------------------------------------;

    .jumpTable:
        
                            dq .wrongLetter

                            dq .bSpecifier
                            dq .cSpecifier
                            dq .dSpecifier

        times ('n' - 'd')   dq .wrongLetter

                            dq .oSpecifier

        times ('r' - 'o')   dq .wrongLetter
                            dq .sSpecifier

        times ('w' - 's')   dq .wrongLetter

                            dq .xSpecifier

                            dq .wrongLetter
                            dq .wrongLetter

    ;------------------------------------------------------------;
    ;
    ; All cases of specifiers
    ;
    ;------------------------------------------------------------;

    .bSpecifier:
        inc rbx
        mov cl, 1
        call Base2nToStr

        jmp .stringParse

    .cSpecifier:
        inc rbx
        mov al, [rbp + 16 + 8 * rbx]
        stosb

        jmp .stringParse

    .dSpecifier:
        inc rbx
        call DecToStr

        jmp .stringParse
    
    .oSpecifier:
        inc rbx
        mov cl, 3
        call Base2nToStr

        jmp .stringParse

    .sSpecifier:
        inc rbx
        push rsi
        mov rsi, [rbp + 16 + 8 * rbx]

        call StrToBuf
        
        pop rsi

        jmp .stringParse

    .xSpecifier:
        inc rbx
        mov cl, 4
        call Base2nToStr

        jmp .stringParse

    .percentSym:
        stosb

        jmp .stringParse

    .wrongLetter:
        inc rbx
        mov byte [rdi], '%'
        inc rdi

        jmp .stringParse
    ;--------------------------------------------------------------;

.MyPrintfAsm__End:
    call flushBuffer

    xor rax, rax

ret

;--------------------------------------------------------------;
; Copies str to buf
; Expects: rdi - buffer
; Destr: rsi
;--------------------------------------------------------------;

StrToBuf:
    .loop:
        lodsb
        cmp al, EOL

        je .end
        stosb

        jmp .loop
.end:
ret

;--------------------------------------------------------------;
; Moves number of base 10 to buf
;
; Destr: rdx, rax, r8, r15, r14
;--------------------------------------------------------------;

DecToStr:
    mov rdx, [rbp + 16 + 8 * rbx]

    test edx, edx
    jns .ifnotnegative
    
    mov al, '-'
    stosb

    neg edx

.ifnotnegative:

    mov rax, rdx
    mov r8, rdx

    xor r15, r15        ;count bytes

    mov r14, 10

    .countDecBytes:

        xor rdx, rdx
        div r14          
        
        inc r15
        test eax, eax

        jne .countDecBytes
    
    add rdi, r15
    mov rax, r8

    .loop:
        xor rdx, rdx
        div r14

        add dl, '0'
        mov [rdi], dl
        dec rdi

        test eax, eax
        jne .loop

        add rdi, r15
        inc rdi

ret

;--------------------------------------------------------------;
; Moves number of base 2^n to buf
; Expects: cl - base
; Destr: rdx, r12, rax, 
;--------------------------------------------------------------;

Base2nToStr:
    mov rdx, [rbp + 16 + 8 * rbx]
    
    test edx, edx
    jns .ifnotnegative

    mov al, '-'
    stosb

    neg edx

.ifnotnegative:
    call countBase2nBytes

    add rdi, rax
    
    dec rdi

    push rax

    mov r12, 01b        ;r12 for bit mask
    shl r12, cl
    dec r12        

    .loop:

        mov rax, r12
        and rax, rdx
        shr edx, cl

        mov al, [hexTable + rax]
        mov [rdi], al
        dec rdi

        test edx, edx
        jne .loop
    
    pop rax
    add rdi, rax

    inc rdi

    ret
    
;--------------------------------------------------------------;
; Counts bytes needed for the number 
; 
; Result is in rax
;--------------------------------------------------------------;

countBase2nBytes:
    xor r12, r12
    mov rax, rdx

    .loop:
        inc r12
        shr rax, cl

        test rax, rax
        jne .loop

    mov rax, r12

ret

;--------------------------------------------------------------;
; Flushes buffer
; 
;
;--------------------------------------------------------------;
flushBuffer:
    push rsi
    push rdx

    sub rdi, buffer
    mov rdx, rdi

    mov rax, 0x01           ;print syscall
    mov rdi, 1
    mov rsi, buffer
    syscall

    pop rdx
    pop rsi

    mov rdi, buffer

    ret
