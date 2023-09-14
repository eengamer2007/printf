.text
	.global _start
	string: .asciz "test %% %r %s %d %u\n"

.include "print_number.s"
.include "print_nul_string.s"


_start:
	movq $string, %rdi
	call printf

	movq $60, %rax				# exit syscall
	xorq %rdi, %rdi
	syscall

# rdi: format string
# rsi...: arugmets to be formated
printf:
	pushq %rbp				# prologue
	movq %rsp, %rbp
	
	pushq %r14
	pushq %r15

	movq %rdi, %r15				# save string start at r15 because rdi will be used

	xorq %rbx, %rbx				# zero rbx to use as char counter
	_printloop:
		
		cmpb $37, (%r15, %rbx)		# test for %
		je _format 

		cmpb $0, (%r15, %rbx)		# check if character is 0
		jz _printf_end				# if character is 0 jump to end

		leaq (%r15, %rbx), %rdi
		call print_char
		
		incq %rbx			# increment char counter and jump to loop start
		jmp _printloop
	_format:
		incq %rbx
		
		movb (%r15, %rbx), %r14b	# move next character into a reg for quick access
		
		cmpb $'%', %r14b		# check if %
		je _percent_percent
		
		cmpb $'d', %r14b		# check if %
		je _percent_d

		cmpb $'u', %r14b		# check if %
		je _percent_u

		cmpb $'s', %r14b		# check if %
		je _percent_s
		
		jmp _printf_else
	_percent_percent:
	leaq (%r15, %rbx), %rdi
	mov $print_char, %r10
	jmp _call_printer
	_percent_d:
	_percent_u:
	_percent_s:
		
	_printf_else:
			
		movq $1, %rax			# print % and next character
		leaq -1(%r15, %rbx), %rsi	# loade percent and following character to be printed
		movq $1, %rdi
		movq $2, %rdx
		syscall

		incq %rbx
		jmp _printloop

	_call_printer:
		call *%r10

		incq %rbx
		jmp _printloop

	_printf_end:	
	popq %r15

	mov %rbp, %rsp
	popq %rbp
	ret

# rdi: address
print_char:
	pushq %rbp				# prologue
	movq %rsp, %rbp
		
	movq $1, %rax			# print current character
	movq %rdi, %rsi
	movq $1, %rdi
	movq $1, %rdx
	syscall

	mov %rbp, %rsp
	popq %rbp
	ret
