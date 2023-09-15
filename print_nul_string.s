.text

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
