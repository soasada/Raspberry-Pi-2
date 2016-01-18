	.include "inter.inc"
.text
	mov    r0, #0
	ADDEXC 0x18, irq_handler
	
	ldr    r0, =GPBASE
	/* guia bits   xx999888777666555444333222111000 */
	ldr    r1, =0b00001000000000000000000000000000
	str    r1, [r0, #GPFSEL0]   @ Configure GPIO9
	/* guia bits   xx999888777666555444333222111000 */
	ldr    r1, =0b00000000001000000000000000000001
	str    r1, [r0, #GPFSEL1]   @ Configure GPIO10
	
	mov 	r1, #0b00000000000000000000011000000000
	str	r1, [r0, #GPSET0]
	
	mov 	r1, #0b00000000000000000000000000001100
	str	r1, [r0, #GPFEN0]
	ldr	r0, =INTBASE
	
	mov	r1, #0b00000000000100000000000000000000
	
	str    r1, [r0, #INTENIRQ2]
	mov    r0, #0b01010011      @ SVC mode, IRQ enabled
	msr    cpsr_c, r0
	
buc:	b      buc

irq_handler:
	push   {r0, r1}
	ldr    r0, =GPBASE
	
	ldr    r1, =0b00000000000000000000011000000000 @ Hay que usar ldr en vez de mov cuando hay muchos unos
	str	r1, [r0, #GPCLR0] @ Apagamos todos los leds
	
	ldr	r1, [r0, #GPEDS0]
	ands	r1, #0b00000000000000000000000000000100
	
	movne	r1, #0b00000000000000000000001000000000
	moveq	r1, #0b00000000000000000000010000000000
	str	r1, [r0, #GPSET0]
	
	mov	r1, #0b00000000000000000000000000001100
	str	r1, [r0, #GPEDS0]
	
	pop    {r0, r1}
	subs   pc, lr, #4
	
