.text
	.global _start
	string: .asciz "test test test or not \n test"

_start:
	mov $string, %rdi
	call printf


	mov $60, %rax
	xor %rdi, %rdi
	syscall

# rdi: format string
# rsi...: arugmets to be formated
printf:
	push %rbp				# prologue
	mov %rsp, %rbp
	mov %rdi, %r15
	xor %rbx, %rbx
	printloop:
		
		mov $1, %rax
		mov $1, %rdi
		lea (%r15, %rbx), %rsi
		mov $1, %rdx
		syscall

		mov %rbx, %r10
		inc %rbx
		cmpq $0, (%r15, %r10)
		jnz printloop
	
	mov %rbp, %rsp
	pop %rbp
	ret

