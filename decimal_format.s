.text

# inputs
# rdi: int
# rsi: output location of string
int_to_str:
	push %rbp
	mov %rsp, %rbp
	
_loop:
	dec rdi
	jz end

	

	jmp loop
_end:

	mov %rbp, %rsp
	pop %rbp
