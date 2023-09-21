.text
	.global _start
	string: .asciz "test %% %d %u %s %g %u %u %u %u %u %u %u %u\n"
	test_string: .asciz "test works"
.include "print_number.s"
.include "print_nul_string.s"


_start:
	mov $0xFFFFFFFFFFFFFFF0, %rsi
	mov %rsi, %rdx
	mov $string, %rdi
	mov $test_string, %rcx
	mov $3, %r8
	mov $4, %r9
	push $10
	push $9
	push $8
	push $7
	push $6
	push $5
	call not_my_printf

	movq $60, %rax				# exit syscall
	xorq %rdi, %rdi
	syscall

# rdi: format string
# rsi...: arugmets to be formated
not_my_printf:
	popq %r11
	movq %rbp, %r10
	movq %rsp, %rbp

	pushq %r9
	push %r8
	push %rcx
	push %rdx
	push %rsi
	
	movq %rdi, %r8				# save string start at r8 because rdi will be used

	xorq %rcx, %rcx				# zero rcx to use as char counter
	_printloop:
		
		cmpb $37, (%r8, %rcx)		# test for %
		je _format 

		cmpb $0, (%r8, %rcx)		# check if character is 0
		jz _printf_end				# if character is 0 jump to end

		leaq (%r8, %rcx), %rdi
		push %r11
		push %r10
		push %rcx
		call print_char
		pop %rcx
		pop %r10
		pop %r11
		
		incq %rcx			# increment char counter and jump to loop start
		jmp _printloop
	_format:
		incq %rcx
		
		movb (%r8, %rcx), %r9b	# move next character into a reg for quick access
		
		cmpb $'%', %r9b		# check if %
		je _percent_percent
		
		cmpb $'d', %r9b		# check if %
		je _percent_d

		cmpb $'u', %r9b		# check if %
		je _percent_u

		cmpb $'s', %r9b		# check if %
		je _percent_s
		
		jmp _printf_else
	_percent_percent:
	leaq (%r8, %rcx), %rdi
	mov $print_char, %r9
	jmp _call_printer
	_percent_d:
	pop %rdi
	mov $print_decimal, %r9
	jmp _call_printer
	_percent_u:
	pop %rdi
	mov $print_unsigned, %r9
	jmp _call_printer
	_percent_s:
	pop %rdi
	mov $print_nul_string, %r9
	jmp _call_printer
		
	_printf_else:
			
		movq $1, %rax			# print % and next character
		leaq -1(%r8, %rcx), %rsi	# loade percent and following character to be printed
		movq $1, %rdi
		movq $2, %rdx
		push %r11
		push %r10
		push %rcx
		syscall
		pop %rcx
		pop %r10
		pop %r11

		incq %rcx
		jmp _printloop

	_call_printer:
		push %r10
		push %r11
		push %rcx
		call *%r9
		pop %rcx
		pop %r11
		pop %r10

		incq %rcx
		jmp _printloop

	_printf_end:	
	popq %r8

	mov %rbp, %rsp
	mov %r10, %rbp
	jmp *%r11

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
