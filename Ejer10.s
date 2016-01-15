	.include "inter.inc"
.text
	mov    r0, #0
	ADDEXC 0x18, irq_handler
	
	ldr    r0, =GPBASE
	/* guia bits   xx999888777666555444333222111000 */
	ldr    r1, =0b00001000000000000000000000000000
	str    r1, [r0, #GPFSEL0]   @ Configure GPIO9
	/* guia bits   xx999888777666555444333222111000 */
	ldr    r1, =0b00000000001000000000000000001001
	str    r1, [r0, #GPFSEL1]   @ Configure GPIO10 y 11
	/* guia bits   xx999888777666555444333222111000 */
	ldr    r1, =0b00000000001000000000000001000000
	str    r1, [r0, #GPFSEL2]   @ Configure GPIO22 y 27
	
	ldr    r0, =STBASE
	ldr    r1, [r0, #STCLO]
	add    r1, #0x40000        @ 0.40 seconds
	str    r1, [r0, #STC1]
	
	ldr    r0, =INTBASE         @ Enable interrupt at C1
	mov    r1, #0b0010
	str    r1, [r0, #INTENIRQ1]
	
	mov    r0, #0b01010011      @ SVC mode, IRQ enabled
	msr    cpsr_c, r0
	
buc:	b      buc

irq_handler:
	push   {r0, r1, r2}
	ldr    r0, =GPBASE
	
	ldr    r1, =onoff
	ldr    r2, [r1]			@ Load variable
	eors   r2, #1			@ Xor with 1 to test if it is on or off
	str    r2, [r1]
	
	ldr    r1, =0b00001000010000100000111000000000 @ Hay que usar ldr en vez de mov cuando hay muchos unos
	strne  r1, [r0, #GPSET0]	@ Turn on if variable is 1
	streq  r1, [r0, #GPCLR0]	@ Turn off if variable is 1
	
	ldr    r0, =STBASE
        mov    r1, #0b0010
        str    r1, [r0, #STCS]		@ Clear timer interrupt
	
	ldr    r1, [r0, #STCLO]
	add    r1, #0x40000
	str    r1, [r0, #STC1]		@ 4.19 seconds
	
	pop    {r0, r1,r2}
	subs   pc, lr, #4
	
onoff:	 .word  0				@ Variable stored after the program code
