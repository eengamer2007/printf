.text

# inputs
# rdi: int
# rsi: output location of string
int_to_str:
	push %rbp
	mov %rsp, %rbp
	
_df_loop:
	dec %rdi
	jz _df_end
	
	
	incb (%rsi)
	_df_inner_loop:


	jmp _df_loop
_df_end:

	mov %rbp, %rsp
	pop %rbp
