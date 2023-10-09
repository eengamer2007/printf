.data
	old_rbp:          .quad 0
	return_addr:      .quad 0
	old_rbx:          .quad 0

.text
	.global main
	string: .asciz "test %% %d %u '%s' %g %u %u %u %u %u %u %u %u\n"
	test_string: .asciz "test works"

main:
	# printf call
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
	call my_printf

	movq $60, %rax		# exit syscall
	xorq %rdi, %rdi
	syscall

# rdi: format string
# ...: arugmets to be formated
my_printf:
	popq return_addr		# save the return address in return_addr

	movq %rbp, old_rbp		# save the rbp
	movq %rsp, %rbp			# finish the "modified" prologue

	movq %rbx, old_rbx 		# save the value of rbx

	# push all the arguments onto the stack so that we can easily pop them off
	pushq %r9
	push %r8
	push %rcx
	push %rdx
	push %rsi
	
	movq %rdi, %rbx			# rbx is our current charcter

	_printloop:
		
		cmpb $'%', (%rbx)		# test for %
		je _format 

		cmpb $0, (%rbx)			# check if character is 0
		jz _printf_end			# if character is 0 jump to end

		# print the character, making sure we save all the vulnerable caller-saved registers
		movq $1, %rax			# print current character
		movq $1, %rdi
		movq %rbx, %rsi
		movq $1, %rdx
		syscall

		incq %rbx			# increment char counter and jump to loop start
		jmp _printloop
	_format:
		incq %rbx			# increase rcx to be the next character
		
		movb (%rbx), %r9b	# move next character into a reg for quick access
		
		# if we wanted, we could have optimized this further by making it branchless with a lookup table
		cmpb $'%', %r9b		# check if %
		je _percent_percent
		
		cmpb $'d', %r9b		# check if d
		je _percent_d

		cmpb $'u', %r9b		# check if u
		je _percent_u

		cmpb $'s', %r9b		# check if s
		je _percent_s
		
		jmp _printf_else
	_percent_percent:
		# print a percent character
		movq $1, %rax			# print current character
		movq %rbx, %rsi
		movq $1, %rdi
		movq $1, %rdx
		syscall

		# increase r8 to the next character
		incq %rbx
		jmp _printloop

	_percent_d:
		# copy the address of the print_decimal into r9 to call it with the next value
		pop %rdi

		test $8, %rsp
		jz 8f

		# if stack not aligned
		subq $8, %rsp
		call print_decimal
		addq $8, %rsp

		incq %rbx
		jmp _printloop

		# if stack aligned
		8:
		  call print_decimal

		  incq %rbx
		  jmp _printloop
	_percent_u:
		# copy the address of the print_unsigned into r9 to call it with the next value
		pop %rdi
		
		test $8, %rsp
		jz 8f

		# if stack not aligned
		subq $8, %rsp
		call print_unsigned
		addq $8, %rsp

		incq %rbx
		jmp _printloop

		# if stack aligned
		8:
		  call print_unsigned

		  incq %rbx
		  jmp _printloop
	_percent_s:
		# copy the address of the print_nul_string into r9 to call it with the next value
		pop %rdi
		
		test $8, %rsp
		jz 8f

		# if stack not aligned
		subq $8, %rsp
		call print_nul_string
		addq $8, %rsp

		incq %rbx
		jmp _printloop

		# if stack aligned
		8:
		  call print_nul_string

		  incq %rbx
		  jmp _printloop
	_printf_else:
		movq $1, %rax			# print % and next character
		leaq -1(%rbx), %rsi	    # load percent and following character to be printed
		movq $1, %rdi
		movq $2, %rdx
		syscall

		# increase r8 to go to the next character
		incq %rbx
		jmp _printloop

	_printf_end:	

	# modified 'epilogue'
	mov %rbp, %rsp		# restore rsp
	mov old_rbp, %rbp	# restore rbp
	mov old_rbx, %rbx	# restore rbx

	pushq return_addr     # return to the call location
	ret

# void print_unsigned(quad n)
# prints the unsigned number n using syscalls
print_unsigned:
  # prologue
  pushq %rbp
  movq %rsp, %rbp

  movq %rdi, %rax # rax is where the divisions happen
  xor  %rdx, %rdx # make sure it is zero to avoid floating point segfaults
  movq $10, %rcx  # move the divisor into rcx

  _pun_loop:
    div %rcx # divide rax by 10

    # the result of the division is now stored in %rax
    # the remainder of the division is now stored in %rdx

    # add '0' to the digit to transform into the ascii value
    addb  $'0', %dl

    # push the single byte onto the stack (since it is stored backwards)
    # we (ab)use this property in order to generate the string backwards and then print it the right way around
    subq  $1, %rsp
    movb  %dl, (%rsp)

    xor %dl, %dl # zero out %dl to avoid floating point errors 

    # check if we are done with all the divisions
    cmp  $0, %rax

    # if not continue looping
    jnz _pun_loop

  # syscall to write the number
  movq $1, %rax # syscall 1 == sys_write
  
  movq $1, %rdi # fd 1 == stdout

  movq %rsp, %rsi # starting address

  movq %rbp, %rdx
  subq %rsp, %rdx # mov the length (rbp - rsp) into rdx

  syscall

  # epilogue
  mov %rbp, %rsp
  popq %rbp

  ret


# saving the negative sign in memory to print it using syscalls
minus: .byte '-'

# void print_decimal(quad n)
# prints the signed decimal number n using syscalls
print_decimal:
  # prologue
  pushq %rbp
  movq %rsp, %rbp
 
  # check if n is negative
  cmp $0, %rdi
  jg  _pde_end

  _pde_neg:
    # print the negative sign
    push %rdi
    movq $1, %rax # syscall 1 == sys_write
    movq $1, %rdi # fd 1 == stdout
    movq $minus, %rsi # starting address
    movq $1, %rdx # the length is 1
    syscall
    pop %rdi

    # two's complement negate the parameter
    neg %rdi

  _pde_end:
    # prints the number as an unsigned one
    call print_unsigned

  # epilogue
  mov %rbp, %rsp
  popq %rbp

  ret


# void print_nul_string(quad string_address)
print_nul_string:
  push  %rbp
  movq  %rsp, %rbp
	
  push %r8
  push %r9

  movq  %rdi, %r8 # starting location of the string
  movq  $0, %r9   # counter for the length

  _pns_count_length_loop:
    # move the next character into al
    movb (%r8, %r9, 1), %al
    # check if it is a nul character (0x00)
    cmp  $0, %al
    # if nul  stop counting
    jz   _pns_end_length_loop

    # increase the counter
    inc  %r9
    # continue looping
    jmp  _pns_count_length_loop


  _pns_end_length_loop:

  movq $1, %rax # syscall 1 == sys_write
  movq $1, %rdi # fd 1 == stdout
  movq %r8, %rsi # starting address
  movq %r9, %rdx # length
  syscall
 

  pop %r9
  pop %r8

  movq  %rbp, %rsp
  popq  %rbp

  ret
