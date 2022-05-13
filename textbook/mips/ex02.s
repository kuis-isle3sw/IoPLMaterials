  .text
  .globl main
main:
  addiu $sp, $sp, -20
  li $t0, 5
  sw $t0, 4($sp)
  lw $t1, 4($sp)
  li $v0, 1
  move $a0, $t1
  syscall
  addiu $sp, $sp, 20
  jr $ra
