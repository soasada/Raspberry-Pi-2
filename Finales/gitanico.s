.include "inter.inc"
.text

	ADDEXC 0x18, irq_handler
	mov R0, #0b11010010 @IRQ
    msr cpsr_c, R0
    mov sp, #0x8000
    mov R0, #0b11010011 @SVC
    msr cpsr_c, R0
    mov sp, #0x8000000
    
    ldr r0, =GPBASE
    ldr r1, =0b00001000000000000000000000000000
    str r1, [r0, #GPFSEL0]
    
    ldr r0, =STBASE
    ldr r1, [r0, #STCLO]
    add r1, #2 			@Encender los leds en 2 microsegundos :)
    str r1, [r0, #STC1]		@Activamos C1
    
    mov r5, #0b00000000000000000000000000000100 @ Mascara de GPIO 2
    mov r7, #0b00000000000000000000000000001000 @ Mascara de GPIO 3
	    
      ldr r0, =INTBASE
    mov r1, #0b0010
    str r1, [r0, #INTENIRQ1]
    
    mov r0, #0b00010011 @SVC + IRQ enabled
    msr cpsr_c, r0

    ldr r0, =GPBASE
    
    
    bucle: 
	ldr r3, [r0, #GPLEV0]
	tst r3, r5
	beq encenderDo
	ldr r6, [r0, #GPLEV0]
	tst r6, r7
	beq encenderSol
	b bucle
	
encenderDo:

	ldr r1, =duracion
	ldr r2, [r1]
	lsr r2, r2, #1 @ Divide entre 2
	ldr r2, =250000
	str r2, [r1]
	b bucle

encenderSol:

	ldr r1, =duracion
	ldr r2, [r1]
	lsl r2, r2, #1 @ Multi entre 2
	ldr r2, =1000000
	str r2, [r1]
	b bucle
    
irq_handler:
	push   {r0, r1, r2, r3}
	ldr    r0, =GPBASE
	
	ldr    r1, =onoff
	ldr    r2, [r1]			@ Load variable
	eors   r2, #1			@ Xor with 1 to test if it is on or off
	str    r2, [r1]
	
	mov    r1, #0b00000000000000000000001000000000
	strne  r1, [r0, #GPSET0]	@ Turn on if variable is distinct 0
	streq  r1, [r0, #GPCLR0]	@ Turn off if variable is equal 0
	
	ldr    r0, =STBASE
        mov    r1, #0b0010
        str    r1, [r0, #STCS]		@ Clear timer interrupt
	
	ldr    r1, =duracion
	ldr 	r2, [r1]
	ldr    r1, [r0, #STCLO]
	add 	r1, r2
	str    r1, [r0, #STC1]		
	
	pop    {r0, r1, r2, r3}
	subs   pc, lr, #4
	
onoff:	 .word  0		
duracion: 	.word 500000
