	.arch armv6
	.eabi_attribute 28, 1
	.eabi_attribute 20, 1
	.eabi_attribute 21, 1
	.eabi_attribute 23, 3
	.eabi_attribute 24, 1
	.eabi_attribute 25, 1
	.eabi_attribute 26, 2
	.eabi_attribute 30, 6
	.eabi_attribute 34, 1
	.eabi_attribute 18, 4
	.file	"timer.c"
	.comm	start_ts,8,4
	.comm	end_ts,8,4
	.text
	.align	2
	.global	start_timer
	.syntax unified
	.arm
	.fpu vfp
	.type	start_timer, %function
start_timer:
	@ args = 0, pretend = 0, frame = 0
	@ frame_needed = 1, uses_anonymous_args = 0
	push	{fp, lr}
	add	fp, sp, #4
	mov	v1, r0
	mov     v2, r1
	ldr	r1, .L2
	mov	r0, #2
	bl	clock_gettime
	mov	r0, v1
	mov     r1, v2
	nop
	pop	{fp, pc}
.L3:
	.align	2
.L2:
	.word	start_ts
	.size	start_timer, .-start_timer
	.section	.rodata
	.align	2
.LC0:
	.ascii	"cpu time: \000"
	.align	2
.LC1:
	.ascii	"%4ld.%09ld\000"
	.align	2
.LC2:
	.ascii	" seconds\000"
	.text
	.align	2
	.global	stop_timer
	.syntax unified
	.arm
	.fpu vfp
	.type	stop_timer, %function
stop_timer:
	@ args = 0, pretend = 0, frame = 0
	@ frame_needed = 1, uses_anonymous_args = 0
	push	{fp, lr}
	add	fp, sp, #4
	mov	v1, r0
	mov     v2, r1
	ldr	r1, .L7
	mov	r0, #2
	bl	clock_gettime
	ldr	r0, .L7+4
	bl	printf
	ldr	r3, .L7
	ldr	r2, [r3, #4]
	ldr	r3, .L7+8
	ldr	r3, [r3, #4]
	cmp	r2, r3
	bge	.L5
	ldr	r3, .L7
	ldr	r2, [r3]
	ldr	r3, .L7+8
	ldr	r3, [r3]
	sub	r3, r2, r3
	sub	r1, r3, #1
	ldr	r3, .L7
	ldr	r2, [r3, #4]
	ldr	r3, .L7+12
	add	r3, r2, r3
	ldr	r2, .L7+8
	ldr	r2, [r2, #4]
	sub	r3, r3, r2
	mov	r2, r3
	ldr	r0, .L7+16
	bl	printf
	b	.L6
.L5:
	ldr	r3, .L7
	ldr	r2, [r3]
	ldr	r3, .L7+8
	ldr	r3, [r3]
	sub	r1, r2, r3
	ldr	r3, .L7
	ldr	r2, [r3, #4]
	ldr	r3, .L7+8
	ldr	r3, [r3, #4]
	sub	r3, r2, r3
	mov	r2, r3
	ldr	r0, .L7+16
	bl	printf
.L6:
	ldr	r0, .L7+20
	bl	puts
	mov	r0, v1
	mov     r1, v2
	nop
	pop	{fp, pc}
.L8:
	.align	2
.L7:
	.word	end_ts
	.word	.LC0
	.word	start_ts
	.word	1000000000
	.word	.LC1
	.word	.LC2
	.size	stop_timer, .-stop_timer
	.ident	"GCC: (Raspbian 6.3.0-18+rpi1) 6.3.0 20170516"
	.section	.note.GNU-stack,"",%progbits
