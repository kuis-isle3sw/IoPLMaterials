    .text
    .globl  main
main:                       
    addiu   $sp,$sp,-20
    li		$v0,1
    li      $a0,20
    syscall
    addiu   $sp,$sp,20
    jr		$ra