global _print

section .text

;-----------------------------------------------------------------
;common enter:
;       r13 - printed symbols
;       r12 - added arguments amount
;       r10 - current buffer size
;       r9 = rbp (for easy using args in stack)
;       rsi - main string
;       rdi - buffer
;exit:  rax - writed symbols amount
;-----------------------------------------------------------------

_print:     push    r15                                         ;push registers for standart
            push    r14
            push    r13
            push    r12
            push    rbx

            push    rbp
            mov     rbp, rsp

            push    r9                                          ;push arguments for using                            
            push    r8
            push    rcx
            push    rdx
            push    rsi

            mov     r9, rbp                                     ;rbp!!                           
            sub     r9, 5 * POINTERSIZE                         ;return stack to the first argument

            mov     rsi, rdi                                    ;main line is in rsi
            mov     rdi, buffer                                 ;buffer is in rdi  
            ;mov     rsi, mstr

            xor     r13, r13                                    ;null printed symbols amount
            xor     r12, r12                                    ;null added arguments amount
            xor     r10, r10                                    ;null curren buffer size

newpassage: cmp     r10, BUFSIZE                                ;check if buffer is filled
            jbe     getsymb

            call    outputbuf

getsymb:    lodsb                                               ;get symbol from main string
            cmp     al, PERCENT
            jne     notspec                                     ;just go to next symb if not specifier 

            lodsb                                               ;get specifier

            cmp     al, PERCENT                                 ;percent case
            jne     getspec                                     ;not func to simply get percent specifier
            stosb                                               

            inc     r10                                         ;caller callee
            inc     r13
            jmp     newpassage

notspec:    cmp     al, 0                                       ;if end of line
            je      printline

            stosb                                               ;next symb
            inc     r10
            inc     r13

            jmp     newpassage

printline:  call    outputbuf
            mov     rax, r13                                    ;return value

return:     mov     rsp, rbp
            pop     rbp

            pop     rbx                                         ;pop registers for standart                               
            pop     r12
            pop     r13
            pop     r14  
            pop     r15

            ret
    
getspec:    cmp     al, 'b'                                     ;min specifier symbol code
            jb      error
            cmp     al, 'x'                                     ;max specifier symbol code
            ja      error

            mov     rdx, [specs + (rax - 'b') * 8]

            inc     r12
            mov     rbx, [r9]                                   ;get next argument from stack
            add     r9, POINTERSIZE                             ;add stack

            cmp     r12, 5                                      ;maximum amount of arguments in registers
            jne     spec                                        ;moving ut in stack to get other arguments in function frame
            add     r9, 56                                      ;pushed arguments and rbp
                                                                
spec:       jmp     rdx

bin:        mov     rax, 2
            call    printdig
            jmp     newpassage

char:       call    printchar
            jmp     newpassage

dec:        mov     rax, 10
            call    printdig
            jmp     newpassage

oct:        mov     rax, 8
            call    printdig
            jmp     newpassage

hex:        mov     rax, 16
            call    printdig
            jmp     newpassage

str:        call    printstr
            jmp     newpassage

error:      mov     rax, 1                                      ;output command
            mov     rdi, 1                                      ;stdout
            mov     rsi, ERRMSG
            mov     rdx, ERRMSGLEN
            syscall

            mov     rax, ERRETVAL
            jmp     return
        

;------------------------------------------
;output buffer and brings pointer to the start
;enter: r10 - buffer size
;       rdi - current buffer address   
;       rsi - main string current address
;exit:  rdi - buffer at start position
;destr: rdx, rax
;------------------------------------------
outputbuf:  push    rsi
            push    rdx
            push    rax

            mov     rax, 1                              ;output command
            mov     rdi, 1                              ;stdout
            mov     rsi, buffer                         
            mov     rdx, r10
            syscall

            pop     rax
            pop     rdx
            pop     rsi

            mov     rdi, buffer                         ;to the buffer start
            mov     r10, 0

            ret

;------------------------------------------
;adds char to the buffer
;enter: rbx - symbol
;       r10 - current buffer size      
;       rdi - current buffer position
;exit:  rdi - buffer at next symbols
;       r10 - new buffer size
;------------------------------------------
printchar:  mov     [rdi], bl
            inc     rdi
            inc     r10
            inc     r13

            ret

;------------------------------------------
;adds string to the buffer
;enter: rbx - string
;       r10 - current buffer size      
;       rdi - current buffer position
;       rsi - main string
;exit:
;destr: r8
;------------------------------------------
printstr:   mov     r8, rsi                         ;save main line curren address for using string functions
            mov     rsi, rbx                        ;string for copy is in rsi

newsymb:    lodsb

            cmp     al, 0
            je      strend

            cmp     r10, BUFSIZE                        ;check if overflow
            jbe     next

            call    outputbuf

next:       stosb
            inc     r10
            inc     r13

            jmp     newsymb

strend:     mov     rsi, r8
            ret

;-------------------------------------------------------
;adds digit to the buffer in definite number system
;enter: rbx - digit (->rax)
;       rax - base of number system (->rbx)
;       r10 - current buffer size     
;       rdi - current buffer address
;destr: rdx, rcx
;-------------------------------------------------------
printdig:       push    rdx
                xor     r14, r14
                ;mov     rbx, -5
                push    rcx                                 ;save rcx    
                xor     rcx, rcx                            ;rcx - number counter      
                mov     r14, intbuf                         ;buffer for digit
                add     r14, INTSIZE                        ;in right order -> go to end of int buffer
                sub     r14, 2                              ;end symb    
                xchg    rax, rbx                            ;dig is in rax for div, base of number system in rbx
                
                push    rax
                shl     rax, 1                              ;check first bit
                pop     rax
                jnc     getnum  

                cmp     rbx, 10                         
                jne     nullpart

                cmp     r10, BUFSIZE
                jb      getsign                             ;add minus and go to additional code just in case 10 number system    

                call    outputbuf

getsign:        push    rax                                 ;!!dif funcs
                mov     al, MINUS
                stosb 
                pop     rax
                inc     r10
                inc     r13                                 ;inc current buffer size

                neg     rax                                 ;go to additional code
                jmp     getnum

nullpart:       shl     rax, 32                             ;null first 4 bytes for negative digits (not 10 num sys)
                shr     rax, 32

getnum:         xor     rdx, rdx                            ;null for div
                div     rbx
                
                cmp     rdx, OCTMAX                         ;test if it should be alpha (hex number system)

                jbe     notalpha
                add     rdx, DIGALPHAOFFSET                 ;to alpha

notalpha:       add     rdx, DIGSYMBOFFSET                  ;to char that code this dig
                inc     rcx
                mov     byte [r14], dl
                dec     r14                                 ;<- to the int buffer
                cmp     rax, 0
                jne     getnum

                inc     r14                                 ;to the last writed number 
tobuf:          cmp     r10, BUFSIZE
                jbe     nextnum

                call outputbuf

nextnum:        mov     al, [r14]
                stosb
                inc     r14
                inc     r10
                inc     r13
                loop    tobuf 

                pop     rcx
                pop     rdx

                ret


section .data

POINTERSIZE         equ 8
BUFSIZE             equ 128
PERCENT             equ '%'
MINUS               equ '-'
ERRETVAL            equ 52h
OCTMAX              equ 9
DIGALPHAOFFSET      equ 7
DIGSYMBOFFSET       equ 30h
buffer:             times BUFSIZE db 0
ERRMSG:             db "something wrong with this specifier", 0ah
ERRMSGLEN           equ $ - ERRMSG
INTSIZE             equ 64
intbuf:             times INTSIZE db 0
;mstr:               db "%d"

align 8
specs: 
                        dq bin
                        dq char
                        dq dec
times ('o' - 'd' - 1)   dq error
                        dq oct
times ('s' - 'o' - 1)   dq error
                        dq str       
times ('x' - 's' - 1)   dq error       
                        dq hex