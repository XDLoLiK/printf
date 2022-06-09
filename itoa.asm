;----------------------------------------------------------
; Standard c itoa() function
;
; Entry: [rsp + 8]  - number to convert
;		 [rsp + 16] - base
;		 [rsp + 24] - dest string addr
;
; Exit:  resulting string starting at [[rsp + 24]]
;
; Note:  mind the RBP offset
;
; Destr: RAX RDI RDX RCX RBX
;----------------------------------------------------------
section .text

_itoa:		push rbp
			mov rbp, rsp

			mov rax, [rbp + 16]
			mov rbx, [rbp + 24]
			mov rdi, [rbp + 32]
			xor rcx, rcx

.count:		xor rdx, rdx
			cmp rax, 0x0
			je .quit
			inc rcx
			div rbx
			jmp .count

.quit		add rdi, rcx
			push rdi
			mov [rdi], byte 0x0
			dec rdi
			mov rax, [rbp + 16]

.repeat		xor rdx, rdx
			div rbx
			push rbx
			mov bl, byte LexTable[rdx]
			mov byte [rdi], bl
			pop rbx
			dec rdi
			loop .repeat

			pop rdi
			pop rbp
			ret


section .data

LexTable:	db		"0123456789ABCDEF"
