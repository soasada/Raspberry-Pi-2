.set GPBASE, 0x3F200000
.set GPFSEL0, 0x00
.set GPFSEL1, 0x04
.set GPSET0, 0x1c
.set GPLEV0, 0x34
.set GPCLR0, 0x28
.text
ldr r0, =GPBASE
/* guia bits  xx999888777666555444333222111000*/
mov r1, #0b00001000000000000000000000000000
str r1, [r0, #GPFSEL0] @ Configura GPIO 9 como salida

mov r1, #0b00000000000000000000000000000001
str r1, [r0, #GPFSEL1] @ Configura GPIO 10 como salida

mov r1, #0b00000000000000000000011000000000
str r1, [r0, #GPSET0] @ Enciende GPIO 9 y GPIO 10

mov r2, #0b00000000000000000000000000000100 @ Configura el boton GPIO 2 como entrada
mov r4, #0b00000000000000000000000000001000 @ Configura el boton GPIO 3 como entrada
apagar: 
	ldr r3, [r0, #GPLEV0]
	tst r3, r2
	beq apagarDer
	ldr r5, [r0, #GPLEV0]
	tst r5, r4
	beq apagarIzq
	b apagar

apagarDer:
	mov r1, #0b000000000000000000000010000000000
	str r1, [r0, #GPCLR0] @ Apaga GPIO 10
	b apagar

apagarIzq:
	mov r1, #0b000000000000000000000001000000000
	str r1, [r0, #GPCLR0] @ Apaga GPIO 9 
	b apagar
	
infi: b infi
