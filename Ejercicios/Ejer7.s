.set GPBASE, 0x3F200000
.set GPFSEL0, 0x00
.set GPSET0, 0x1c
.set GPLEV0, 0x34
.set STBASE, 0x3F003000
.set STCLO, 0x04
.set GPCLR0, 0x28
.text

mov r0, #0b11010011
msr cpsr_c, r0
mov sp, #0x08000000
ldr r4, =GPBASE

/* guia bits  xx999888777666555444333222111000*/
mov r5, #0b00000000000000000001000000000000
str r5, [r4, #GPFSEL0] @ Configura GPIO 4 como salida, GPIO 2 y GPIO 3 como entrada

mov r5, #0b00000000000000000000000000010000
ldr r0, =STBASE
mov r2, #0b00000000000000000000000000000100 @ Mascara de GPIO 2
mov r7, #0b00000000000000000000000000001000 @ Mascara de GPIO 3

bucle: 
	ldr r3, [r4, #GPLEV0]
	tst r3, r2
	beq encenderDo
	ldr r6, [r4, #GPLEV0]
	tst r6, r7
	beq encenderSol
	b bucle

encenderDo:
	ldr r1, =956
	bl espera
	str r5, [r4, #GPSET0]
	bl espera
	str r5, [r4, #GPCLR0]
	b bucle

encenderSol:
	ldr r1, =638
	bl espera
	str r5, [r4, #GPSET0]
	bl espera
	str r5, [r4, #GPCLR0]
	b bucle
	
espera: 	
	push {r4, r5}
	ldr r4, [r0, #STCLO]
	add r4, r1
ret1: 	
	ldr r5, [r0, #STCLO]
	cmp r5, r4
	blo ret1
	pop {r4, r5}
	bx lr
		
