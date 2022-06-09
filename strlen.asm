;----------------------------------------------------------
; Standard c strlen() function
;
; Entry: [rsp + 8]  - terminating symbol
;		 [rsp + 18] - str addr
;
; Exit:  RAX - string length
;
; Note:  mind the RBP offset
;		 DF = 0;
;
; Destr: RCX RAX DI
;----------------------------------------------------------
section .text

_strlen:	push rbp
			mov rbp, rsp

			xor rcx, rcx
			not rcx
			mov al,  byte  [rbp + 16]
			mov rdi, qword [rbp + 24]

			repne scasb
			not rcx
			inc rcx
			mov rax, rcx

			pop rbp
			ret
			