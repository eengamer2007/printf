.text
	.global _start
	string: .asciz "test test test or not \n test %"

.include "decimal_format.s"
.include "print_nul_string.s"


_start:
	movq $string, %rdi
	call printf

	movq $60, %rax
	xorq %rdi, %rdi
	syscall

# rdi: format string
# rsi...: arugmets to be formated
printf:
	pushq %rbp				# prologue
	movq %rsp, %rbp
	
	pushq %r15

	movq %rdi, %r15				# save string start at r15 because rdi will be used

	xorq %rbx, %rbx				# zero rbx to use as char counter
	printloop:
		
		cmpb $37, (%r15, %rbx)		# test for %
		je format 
		
		movq $1, %rax			# print current character
		movq $1, %rdi
		leaq (%r15, %rbx), %rsi
		movq $1, %rdx
		syscall
		
		movq %rbx, %r10			# check if the current char is 0 and if it is exit
		incq %rbx			# else increment the char counter
		cmpb $0, (%r15, %r10)
		je printloop
	
	format:
		incq %rbx
		jmp printloop

	popq %r15

	mov %rbp, %rsp
	popq %rbp
	ret

