.global codegen
codegen:
	addi sp, sp, -136
	sd sp, 96(sp)
	sd s0, 88(sp)
	sd s1, 80(sp)
	sd s2, 72(sp)
	sd s3, 64(sp)
	sd s4, 56(sp)
	sd s5, 48(sp)
	sd s5, 48(sp)
	sd s6, 40(sp)
	sd s7, 32(sp)
	sd s8, 24(sp)
	sd s9, 16(sp)
	sd s10, 8(sp)
	sd s11, 0(sp)
	addi s0, sp, 136


	li t0, 0
	addi sp, sp, -8
	sd t0, 0(sp)

	li t0, 42
	addi sp, sp, -8
	sd t0, 0(sp)

	li t0, 53
	addi sp, sp, -8
	sd t0, 0(sp)

	li t0, 2
	addi sp, sp, -8
	sd t0, 0(sp)

	ld t1, 0(sp)
	addi sp, sp, 8

	ld t0, 0(sp)
	addi sp, sp, 8

	mul t0, t0, t1

	addi sp, sp, -8
	sd t0, 0(sp)

	ld t1, 0(sp)
	addi sp, sp, 8

	ld t0, 0(sp)
	addi sp, sp, 8

	sub t0, t0, t1

	addi sp, sp, -8
	sd t0, 0(sp)

	ld t1, 0(sp)
	addi sp, sp, 8
	sd t1, -144(s0)
	addi sp, sp, -8
	sd t1, 0(sp)

	ld t3, 0(sp)
	addi sp, sp, 8

	li t0, 0
	addi sp, sp, -8
	sd t0, 0(sp)

	ld t0, -144(s0)
	addi sp, sp, -8
	sd t0, 0(sp)

	ld t0, 0(sp)
	addi sp, sp, 8
	li t1, 144
	addi sp, sp, -8
	sd t1, 0(sp)

	ld t1, 0(sp)
	addi sp, sp, 8
	sd t1, -152(s0)
	addi sp, sp, -8
	sd t1, 0(sp)

	ld t3, 0(sp)
	addi sp, sp, 8

	ld t0, -152(s0)
	addi sp, sp, -8
	sd t0, 0(sp)

	ld t0, 0(sp)
	addi sp, sp, 8
	ld t1, -144(s0)
	addi sp, sp, -8
	sd t1, 0(sp)

	ld t0, -144(s0)
	addi sp, sp, -8
	sd t0, 0(sp)

	ld t0, 0(sp)
	addi sp, sp, 8
	li t1, -1
	mul t0, t0, t1
	addi sp, sp, -8
	sd t0, 0(sp)

	li t0, 8
	addi sp, sp, -8
	sd t0, 0(sp)

	ld t1, 0(sp)
	addi sp, sp, 8

	ld t0, 0(sp)
	addi sp, sp, 8

	div t0, t0, t1

	addi sp, sp, -8
	sd t0, 0(sp)

	ld t1, 0(sp)
	addi sp, sp, 8

	ld t0, 0(sp)
	addi sp, sp, 8

	sd t1, -144(s0)
	addi sp, sp, -8
	sd t1, 0(sp)

	ld t3, 0(sp)
	addi sp, sp, 8

	ld t0, -144(s0)
	addi sp, sp, -8
	sd t0, 0(sp)

	ld t0, -152(s0)
	addi sp, sp, -8
	sd t0, 0(sp)

	ld t0, 0(sp)
	addi sp, sp, 8
	ld t1, -144(s0)
	addi sp, sp, -8
	sd t1, 0(sp)

	li t0, 4
	addi sp, sp, -8
	sd t0, 0(sp)

	ld t1, 0(sp)
	addi sp, sp, 8

	ld t0, 0(sp)
	addi sp, sp, 8

	sub t0, t0, t1

	addi sp, sp, -8
	sd t0, 0(sp)

	ld t1, 0(sp)
	addi sp, sp, 8

	ld t0, 0(sp)
	addi sp, sp, 8

	sd t1, -144(s0)
	addi sp, sp, -8
	sd t1, 0(sp)

	ld t3, 0(sp)
	addi sp, sp, 8

	li t0, 28
	addi sp, sp, -8
	sd t0, 0(sp)

	li t0, 1
	addi sp, sp, -8
	sd t0, 0(sp)

	ld t0, 0(sp)
	addi sp, sp, 8
	mv a1, t0

	ld t0, 0(sp)
	addi sp, sp, 8
	mv a0, t0

	addi sp, sp, -8
	sd ra, 0(sp)
	jal ra, digitalWrite
	ld ra, 0(sp)
	addi sp, sp, 8

	addi sp, sp, -8
	sd a0, 0(sp)

	ld t3, 0(sp)
	addi sp, sp, 8

	ld t0, -144(s0)
	addi sp, sp, -8
	sd t0, 0(sp)

	li t0, 1000
	addi sp, sp, -8
	sd t0, 0(sp)

	ld t1, 0(sp)
	addi sp, sp, 8

	ld t0, 0(sp)
	addi sp, sp, 8

	mul t0, t0, t1

	addi sp, sp, -8
	sd t0, 0(sp)

	ld t0, 0(sp)
	addi sp, sp, 8
	mv a0, t0

	addi sp, sp, -8
	sd ra, 0(sp)
	jal ra, delay
	ld ra, 0(sp)
	addi sp, sp, 8

	addi sp, sp, -8
	sd a0, 0(sp)

	ld t3, 0(sp)
	addi sp, sp, 8

	li t0, 28
	addi sp, sp, -8
	sd t0, 0(sp)

	li t0, 0
	addi sp, sp, -8
	sd t0, 0(sp)

	ld t0, 0(sp)
	addi sp, sp, 8
	mv a1, t0

	ld t0, 0(sp)
	addi sp, sp, 8
	mv a0, t0

	addi sp, sp, -8
	sd ra, 0(sp)
	jal ra, digitalWrite
	ld ra, 0(sp)
	addi sp, sp, 8

	addi sp, sp, -8
	sd a0, 0(sp)

	ld t3, 0(sp)
	addi sp, sp, 8

	ld t0, -152(s0)
	addi sp, sp, -8
	sd t0, 0(sp)

	ld t0, 0(sp)
	addi sp, sp, 8
	ld t1, -144(s0)
	addi sp, sp, -8
	sd t1, 0(sp)

	li t0, 1000
	addi sp, sp, -8
	sd t0, 0(sp)

	ld t1, 0(sp)
	addi sp, sp, 8

	ld t0, 0(sp)
	addi sp, sp, 8

	mul t0, t0, t1

	addi sp, sp, -8
	sd t0, 0(sp)

	ld t0, 0(sp)
	addi sp, sp, 8
	mv a0, t0

	addi sp, sp, -8
	sd ra, 0(sp)
	jal ra, delay
	ld ra, 0(sp)
	addi sp, sp, 8

	addi sp, sp, -8
	sd a0, 0(sp)

	ld t3, 0(sp)
	addi sp, sp, 8

	addi sp, sp, 8
	addi sp, sp, 8

	ld sp, 96(sp)
	ld s0, 88(sp)
	ld s1, 80(sp)
	ld s2, 72(sp)
	ld s3, 64(sp)
	ld s4, 56(sp)
	ld s5, 48(sp)
	ld s5, 48(sp)
	ld s6, 40(sp)
	ld s7, 32(sp)
	ld s8, 24(sp)
	ld s9, 16(sp)
	ld s10, 8(sp)
	ld s11, 0(sp)
	addi sp, sp, 136
	jalr zero, 0(ra)

