	.text
	.globl	main
main:
	addiu	$sp,$sp,-20
	li		$a0,5
	sw		$ra,0($sp)
	jal		f
	lw		$ra,0($sp)
	move	$a0,$v0
	li		$v0,1
	syscall
	addiu	$sp,$sp,20
	jr		$ra
f:
	addiu	$sp,$sp,-4
	addiu	$v0,$a0,2
	addiu	$sp,$sp,4
	jr		$ra