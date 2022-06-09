%include "./itoa.asm"
%include "./strlen.asm"


global _printf


section .consts

STDOUT:     equ     1


;----------------------------------------------------------
; Standard c printf() function
;
; Entry: [rsp + 8]  - format string addr
;        [rsp + 16] - 1st arg
;        [rsp + 24] - 2nd arg
;        ...
;
; Exit:  RAX - number of successfully printed values
;
; Note:  mind the RBP offset
;        DF = 0
;
; Destr: RAX RSI RDI RCX RDX
;----------------------------------------------------------
section .text

_printf:    pop  r10                ; ret addr
            push r9
            push r8
            push rcx
            push rdx
            push rsi
            push rdi

            push rbp
            mov rbp, rsp
            add rbp, 0x8
            mov rdi, qword buffer
            mov rsi, qword [rbp]
            add rbp, 0x8
            xor rax, rax
            xor rcx, rcx

jmp_table_start:                    ; if a label has jmp_table prefix, it means
            lodsb                   ; that it belongs to the JmpTable

            cmp al, 0x0             ; if '\0' is met - terminate
            je _printf_ret

            cmp al, '%'             ; if '%' is met - handle specifier
            je _printf_specifier

            stosb                   ; else just copy the symbol
            jmp jmp_table_start

_printf_specifier:  
            lodsb                   ; the next symbol right after '%'

            cmp al, '%'             ; double % is a special case
            je _printf_percent

            push rax                ; saving these 4 regs as itoa function may be called which would spoil them
            push rbx                ; (not saving RDI though because it's expected to change)
            push rcx
            push rdx

            sub al, 'b'             ; JmpTable starts with b
            jmp JmpTable[rax * 8]   ; every JmpTable element is 8 bytes

_printf_continue:   
            pop rdx                 ; returning saved registers' values
            pop rcx
            pop rbx
            pop rax
            
            jmp jmp_table_start     ; else just go forwards

_printf_percent:    
            stosb
            jmp jmp_table_start

jmp_table_char: 
            mov al, byte [rbp]      
            stosb
            jmp _printf_next_arg    ; this label is responsible for
                                    ; moving on to the next argument
jmp_table_string:   
            push rsi
            mov rsi, qword [rbp]

.repeat:    lodsb                   ; strcpy
            cmp al, 0x0             ; untill 0x0 is met
            je .quit
            stosb
            jmp .repeat

.quit:      pop rsi
            jmp _printf_next_arg

jmp_table_digit:    
            push rdi                ; destinating string address
            push qword 0xA          ; base = 10
            push qword [rbp]        ; number to convert
            call _itoa
            add rsp, 3 * 8
            jmp _printf_next_arg

jmp_table_octo: 
            push rdi
            push qword 0x8          ; base = 8
            push qword [rbp]
            call _itoa
            add rsp, 3 * 8          ; _printf prefix makes labels in this
            jmp _printf_next_arg    ; function "local"

jmp_table_hex:  
            push rdi
            push qword 0x10         ; base = 16
            push qword [rbp]
            call _itoa
            add rsp, 3 * 8
            jmp _printf_next_arg

jmp_table_bin:      
            push rdi
            push qword 0x2          ; base = 2
            push qword [rbp]
            call _itoa
            add rsp, 3 * 8
            jmp _printf_next_arg

_printf_next_arg:
            add rbp, 0x8            ; next argument is 8 bytes lower in stack
            inc rcx                 ; + 1 successfully printed specifier
            jmp _printf_continue

_printf_ret:
            stosb
            push qword buffer
            push qword 0x0
            call _strlen            ; RAX = strlen buffer
            add rsp, 2 * 8

            mov rdx, rax            ; RDX = strlen (buffer)
            mov rax, 0x1            ; system function #1 - write (RSI RDI RDX)
            mov rdi, STDOUT         ; file handler
            mov rsi, buffer         ; string to write
            syscall

            mov rax, rcx            ; number of successfully printed specifiers
            pop rbp
            add rsp, 6 * 8
            push r10
            ret


section .data

JmpTable:   dq      jmp_table_bin
            dq      jmp_table_char
            dq      jmp_table_digit
times 10    dq      jmp_table_start
            dq      jmp_table_octo
times 3     dq      jmp_table_start
            dq      jmp_table_string
times 4     dq      jmp_table_start
            dq      jmp_table_hex


section .bss

buffer:     resb    512
