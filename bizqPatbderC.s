	.include "inter.inc"
	.include "notas.inc"
.text
	mov    r0, #0
	ADDEXC 0x18, irq_handler
	ADDEXC 0x1c, fiq_handler	
	
	mov	r0, #0b11010001
	msr	cpsr_c,  r0
	mov	sp, #0x4000
				@ Inicializo la pila del modo 
	mov	r0, #0b11010010
	msr	cpsr_c,  r0
	mov	sp, #0x8000
				@ Inicializo la pila del modo 
	mov	r0, #0b11010011
	msr	cpsr_c,  r0
	mov	sp, #0x8000000
				@ Inicializo la pila del modo 
	

	ldr    r0, =GPBASE
	/* guia bits   xx999888777666555444333222111000 */
	ldr    r1, =0b00001000000000000001000000000000
	str    r1, [r0, #GPFSEL0]   @ Configure GPIO9 AND GPIO4 (speaker) as outputs and GPIO2 AND GPIO3 as inputs
	/* guia bits   xx999888777666555444333222111000 */
	ldr    r1, =0b00000000001000000000000000001001
	str    r1, [r0, #GPFSEL1]   @ Configure GPIO10, GPIO11 AND GPIO17 as outputs
	/* guia bits   xx999888777666555444333222111000 */
	ldr    r1, =0b00000000001000000000000001000000
	str    r1, [r0, #GPFSEL2]   @ Configure GPIO22 AND GPIO27 as outputs
	
	ldr	r0, =STBASE
	ldr	r1, [r0, #STCLO]
	add	r1, #2
	str	r1, [r0, #STC1]
	str	r1, [r0, #STC3]
	@ Provoco interrupciones en 2 ms
	ldr r0, =GPBASE 
	mov r1, #0b01100
	str r1,[r0,#GPFEN0]
	@ Configuro los botones para producir interrupciones
	
	ldr	r0, =INTBASE
	mov	r1, #0b0010
	str    r1, [r0, #INTENIRQ1]
	mov	r1, #0b00000000000100000000000000000000
	str    r1, [r0, #INTENIRQ2]
	@ Configuro IRQ para admitir interrupciones por C1 y por el boton de la izquierda

	mov	r1, #0b10000011
	str	r1, [r0, #INTFIQCON]
	@ Configuro como interrupcion de tipo IFQ a C3

	mov    r0, #0b00010011      @ SVC mode, IRQ enabled
	msr    cpsr_c, r0
	
	ldr r3, =npirata
	ldr r4, =dpirata

	@ Almaceno en tres registros los punteros de la secuencia de notas, de su duracion y el ledact de patron2

buc:
	b buc @ En este punto esperamos las interrupciones y solo necesitamos preservar r4 y r3






irq_handler:

 @ Con esta interrupcion, controlamos la frecuencia y la lectura del boton 
/* Utiliza: r0, r1, r2 para el reset y r8, r9, r10, r11, r12 para trabajar */
 @ Solo guardo en pila aquellos que toco
/* Utilizo los r8 -> r12 para unificar el tipo con los que uso en FIQ */

	push {r0, r1, r2, r8, r9, r10, r11, r12}
	
	ldr	r0, =STBASE
	ldr  r1, [r0, #STCS]
	subs r1, #0b0010   		@ Comparamos si ha sido el contador el que ejecuta la interrupcion
	beq notas

	ldr r0, =GPBASE
	ldr r1, [r0, #GPEDS0]
	subs r1, #0b00000000000000000000000000000100		@ Comparamos si ha sido el boton izquierdo el que ejecuta la interrupcion
	beq boton1
	
	ldr r0, =GPBASE
	ldr r1, [r0, #GPEDS0]
	subs r1, #0b00000000000000000000000000001000		@ Comparamos si ha sido el boton derecho el que ejecuta la interrupcion
	beq boton2
	
notas:	
 @ Configuramos la nota con la frecuencia almacenada en memoria 

/* Conmuto variable de estado del altavoz */
	ldr	r11, =sonon
	ldr	r12, [r11]
	eors	r12, #1			@ Hace un OR exclusivo de sonon con 1 / si sonon = 1 -> 0 sino -> 1
	str	r12, [r11]
	
/* Enciendo o apago altavoz en funcion del flag Z */
	ldr	r10, =GPBASE
	ldr 	r11, =0b00000000000000000000000000010000
	streq	r11, [r10, #GPSET0]
	strne	r11, [r10, #GPCLR0]

/* Reseteo estado interrupcion de C1 */
	ldr	r10, = STBASE
	mov 	r11, #0b0010 
	str 	r11, [ r10, # STCS ]
	
/* Programo siguiente interrupcion dependiendo de la frecuencia de la nota */
	ldr	r11, [r10, #STCLO]
	ldr r2, [r3]
	add r11, r2
	str r11, [r10, #STC1]
	
	b fin

boton1:
	ldr	r8, =setpat
	ldr	r9, [r8]
	eors r9, #1				@ Hace un OR exclusivo de setpat con 1 / si setpat = 1 -> 0 sino -> 1
	str	r9, [r8]
	b finb
	
boton2:
	ldr	r8, =setcan
	ldr	r9, [r8]
	eors r9, #1	 @ Hace un OR exclusivo de setcan con 1 / si setcan = 1 -> 0 sino -> 1
	str	r9, [r8]
	
	ldreq r3, =ngadget
	ldreq r4, =dgadget
	
	ldrne r3, =npirata
	ldrne r4, =dpirata
	
/* Programo siguiente interrupcion */
finb:	ldr r0, =GPBASE
	mov r1, #0b00000000000000000000000000001100
	str r1, [r0, #GPEDS0]
	

fin:
	pop {r0, r1, r2, r8, r9, r10, r11, r12}
	subs   pc, lr, #4
	
fiq_handler: 

 @ Controlamos el tiempo que se ejecuta la nota y los leds
/* Utiliza: r0, r1, r2 para el reset y r8, r9, r10, r11, r12 para trabajar */
 @ No almaceno en pila estos ultimos ya que el modo FIQ no lo necisa al ser una 
/* interrupcion de tratamiento rapido */

	push {r0, r1, r2}
	
	add r4, #4
	add r3, #4
	@ Incremento los puntero de nota y duracion

	ldr	r8, =setpat
	ldr	r9, [r8]
	cmp r9, #0
	@ Va a memoria y lee el patron 1 o 2

	beq patron1
	ldr	r9, 	=0b00001000010000100000111000000000 @Guardo el 1 para encender o apagar
	ldr    r0, =GPBASE
	str	r9,	[r0,	#GPCLR0]
	bne patron2
	
patron1:

 @ Este patron produce una intermitencia de los 6 leds / una nota los enciende y la siguiente los apaga
/* Utiliza r8 como puntero de memoria y r9 para actualizar el estado */

	/* guia bits      xx999888777666555444333222111000 */
	ldr	r10, 	=0b00001000010000100000111000000000 @Guardo el 1 para encender o apagar
	
	ldr	r8, =ledon
	ldr	r9, [r8]
	eors	r9, #1			@ Hace un OR exclusivo de ledon con 1 / si ledon = 1 -> 0 sino -> 1
	str	r9, [r8]
	
	ldr    r0, =GPBASE
	streq	r10,	[r0,	#GPSET0]
	strne	r10,	[r0,	#GPCLR0]
	@ Apaga o enciende segun la comparacion anterior

	b end
	
patron2:
	
 @ Este patron es una secuencia donde los leds se encienden secuencialmente
/* Utiliza una variable estado en memoria donde almacena el led actual */
		
	ldr	r8, =estado
	ldr	r10, [r8]
	cmp r10, #5
	moveq r10, #0
	addne r10, #1
	str	r10, [r8]
	
	/* guia bits   xx999888777666555444333222111000 */
	cmp r10, #0
	ldreq r9, 	=0b00001000000000000000000000000000 @ Guardo el 1 para apagar el 27 
	ldreq r11, 	=0b00000000000000000000001000000000 @ Guardo el 1 para encender el 09 
	
	cmp r10, #1
	ldreq r9, 	=0b00000000000000000000001000000000 @ Guardo el 1 para apagar el 09
	ldreq r11, 	=0b00000000000000000000010000000000 @ Guardo el 1 para encender el 10
	
	cmp r10, #2
	ldreq r9, 	=0b00000000000000000000010000000000 @ Guardo el 1 para apagar el 10
	ldreq r11, 	=0b00000000000000000000100000000000 @ Guardo el 1 para encender el 11
	
	cmp r10, #3
	ldreq r9, 	=0b00000000000000000000100000000000 @ Guardo el 1 para apagar el 11
	ldreq r11, 	=0b00000000000000100000000000000000 @ Guardo el 1 para encender el 17
	
	cmp r10, #4
	ldreq r9, 	=0b00000000000000100000000000000000 @ Guardo el 1 para apagar el 17
	ldreq r11, 	=0b00000000010000000000000000000000 @ Guardo el 1 para encender el 22
	
	cmp r10, #5
	ldreq r9, 	=0b00000000010000000000000000000000 @ Guardo el 1 para apagar el 22
	ldreq r11, 	=0b00001000000000000000000000000000 @ Guardo el 1 para encender el 27
	
	str	r9,	[r0,	#GPCLR0]
	str	r11,[r0,	#GPSET0]

	
end:	

 @ Programo siguiente interrupcion
	
/* Reseteo estado interrupcion de C3 */
	ldr	r0, = STBASE
	mov 	r1, #0b01100 
	str 	r1, [ r0, # STCS ]
	
/* Programo siguiente interrupcion dependiendo de la duracion */	
	ldr	r1, [r0, #STCLO]
	ldr 	r2, [r4]
	add 	r1, r2
	str r1, [r0, #STC3]
	
	pop {r0, r1, r2}
	subs   pc, lr, #4





sonon: .word 0
ledon: .word 0
setpat: .word 0
estado: .word 0
setcan: .word 0

npirata:

.word SILEN
.word MI
.word MI

.word LA
.word LA
.word LA
.word SI

.word DOH
.word DOH
.word DOH
.word REH

.word SI
.word SI
.word LA
.word SOL

.word LA
.word SILEN
.word MI
.word MI

.word LA
.word LA
.word LA
.word SI

.word DOH
.word DOH
.word DOH
.word REH

@ ENDLINE

.word SI
.word SI
.word LA
.word SOL

.word LA
.word SILEN
.word MI
.word MI

.word LA
.word LA
.word LA
.word DOH

.word REH
.word REH
.word REH
.word MIH

.word FAH
.word FAH
.word MIH
.word REH

.word MIH
.word LA
.word SILEN
.word LA
.word DOH

.word DOH
.word DOH
.word REH

@ ENDLINE

.word MIH
.word LA
.word SILEN
.word LA
.word DOH

.word SI
.word SI
.word DOH
.word LA

.word SI
.word SILEN

.word MIH
.word SILEN

.word FAH
.word SILEN

.word MIH
.word MIH
.word MIH

.word MIH
.word REH
.word SILEN

.word RE
.word SILEN

@ ENDLINE

.word DOH
.word SILEN

.word DOH
.word REH
.word SI

.word LA
.word SILEN
.word LA
.word SI

.word DOH
.word REH
.word MIH

.word REH
.word DOH
.word SI

.word DOH
.word REH
.word MIH

.word REH
.word SILEN
.word DOH
.word REH

.word MIH
.word REH
.word DOH

@ ENDLINE

.word SI
.word DOH
.word SI

.word LA
.word SI
.word SOL 

.word LA
.word SILEN
.word LA
.word SI

.word DOH
.word REH
.word MIH

.word REH
.word DOH
.word SI

.word DOH
.word REH
.word MIH

.word REH
.word SILEN
.word LA
.word LA

.word DOH
.word DOH
.word REH

dpirata:

.word BL
.word COR
.word COR

.word NG
.word NG
.word COR
.word COR

.word NG
.word NG
.word COR
.word COR

.word NG
.word NG
.word COR
.word COR

.word NG
.word NG
.word COR
.word COR

.word NG
.word NG
.word COR
.word COR

.word NG
.word NG
.word COR
.word COR

@ ENDLINE

.word NG
.word NG
.word COR
.word COR

.word NG
.word NG
.word COR
.word COR

.word NG
.word NG
.word COR
.word COR

.word NG
.word NG
.word COR
.word COR

.word NG
.word NG
.word COR
.word COR

.word COR
.word COR
.word NG
.word COR
.word COR

.word NG
.word NG
.word NG

@ ENDLINE

.word COR
.word COR
.word NG
.word COR
.word COR

.word NG
.word NG
.word COR
.word COR

.word NG
.word BL

.word NG
.word BL

.word NG
.word BL

.word NG
.word NG
.word NG

.word COR
.word COR
.word BL

.word NG
.word BL

@ ENDLINE

.word NG
.word BL

.word NG
.word NG
.word NG

.word NG
.word NG
.word COR
.word COR

.word BL
.word COR
.word COR

.word NG
.word NG
.word NG

.word NG
.word NG
.word NG

.word NG
.word NG
.word COR
.word COR

.word BL
.word COR
.word COR

@ ENDLINE

.word NG
.word NG
.word NG

.word NG
.word NG
.word NG

.word NG
.word NG
.word COR
.word COR

.word BL
.word COR
.word COR

.word NG
.word NG
.word NG

.word NG
.word NG
.word NG

.word NG
.word NG
.word COR
.word COR

.word NG
.word NG
.word NG


ngadget:

.word	RE 
.word	MI 
.word	FA 
.word	SOL 
.word	LA 
.word	FA 
.word	SOLs 
.word	MI 
.word	SOL 
.word	FA 
.word	RE 
.word	MI 
.word	FA 
.word	SOL 
.word	LA 
.word	REs 
.word	DOH 
.word	RE 
.word	MI 
.word	FA 
.word	SOL 
.word	LA 
.word	FA 
.word	SOLs 
.word	MI 
.word	SOL 
.word	FA 
.word	REs 
.word	DOHs 
.word	DOH 
.word	SI 
.word	SIb 
.word	SI 
.word	LA 
.word	REs 


dgadget:	
	
.word	CORP
.word	FUS
.word	CORP
.word	FUS
.word	NG
.word	NG
.word	NG
.word	NG
.word	NG
.word	NG
.word	CORP
.word	FUS
.word	CORP
.word	FUS
.word	NG
.word	NG
.word	RED
.word	CORP
.word	FUS
.word	CORP
.word	FUS
.word	NG
.word	NG
.word	NG
.word	NG
.word	NG
.word	NG
.word	CORP
.word	FUS
.word	CORP
.word	FUS
.word	BL
.word	NG
.word	NG
.word	NG	

