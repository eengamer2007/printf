.text

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
