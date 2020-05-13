	.text
	.globl	main
main:
	addiu	$sp,$sp,-20
	li		$a0,10
	sw		$ra,0($sp)
	jal		f
	lw		$ra,0($sp)
	move	$a0,$v0
	li		$v0,1
	syscall
	addiu	$sp,$sp,20
	jr		$ra
f:
	addiu	$sp,$sp,-12
	ble		$a0,0,end
	sw		$a0,8($sp)
	addiu	$a0,$a0,-1
	sw		$ra,4($sp)
	jal		f
	lw		$ra,4($sp)
	lw		$a0,8($sp)
	addu	$v0,$v0,$a0
	addiu	$sp,$sp,12
	jr		$ra
end:
	li		$v0,0
	addiu	$sp,$sp,12
	jr		$ra
