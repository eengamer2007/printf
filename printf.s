.text
	.global _start
	string: .asciz "test test test or not \n test %"

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

	mov %rdi, %r15				# save string start at r15 because rdi will be used

	xor %rbx, %rbx				# zero rbx to use as char counter
	printloop:
		
		cmpb $0x25, (%r15, %rbx)	# test for %
		je format 
		
		mov $1, %rax			# print current character
		mov $1, %rdi
		lea (%r15, %rbx), %rsi
		mov $1, %rdx
		syscall
		
		mov %rbx, %r10			# check if the current char is 0 and if it is exit
		inc %rbx			# else increment the char counter
		cmpb $0, (%r15, %r10)
		je printloop
	
	format:
		inc %rbx
		jmp printloop

	mov %rbp, %rsp
	pop %rbp
	ret

