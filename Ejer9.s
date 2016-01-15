	.include "inter.inc"
.text
	mov    r0, #0
	ADDEXC 0x18, irq_handler
	
	ldr    r0, =GPBASE
	ldr    r1, =0b00001000000000000000000000000000
	str    r1, [r0, #GPFSEL0]   @ Configure GPIO9
	
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
	
	mov    r1, #0b00000000000000000000001000000000
	strne  r1, [r0, #GPSET0]	@ Turn on if variable is 1
	streq  r1, [r0, #GPCLR0]	@ Turn off if variable is 1
	
	ldr    r0, =STBASE
        mov    r1, #0b0010
        str    r1, [r0, #STCS]		@ Clear timer interrupt
	
	ldr    r1, [r0, #STCLO]
	add    r1, #0x40000
	str    r1, [r0, #STC1]		@ 0.4 seconds
	
	pop    {r0, r1}
	subs   pc, lr, #4
	
onoff:	 .word  0				@ Variable stored after the program code
