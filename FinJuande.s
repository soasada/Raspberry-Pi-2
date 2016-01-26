.include "inter.inc"
.include "notas.inc"

.text
    ADDEXC 0x18, irq_handler @Se aÃ±ade el manejador de los IRQ
    ADDEXC 0x1C, fiq_handler @Se aÃ±ade el manejador del FIQ

@Inicializando la pila en el modo IRQ, FIQ y SVC (sin interrupciones)
    mov R0, #0b11010001 @FIQ
    msr cpsr_c, R0
    mov sp, #0x4000
    mov R0, #0b11010010 @IRQ
    msr cpsr_c, R0
    mov sp, #0x8000
    mov R0, #0b11010011 @SVC
    msr cpsr_c, R0
    mov sp, #0x8000000

@Stock en IRQ, FIQ y SVC (sin interrupciones)
    ldr r0, =GPBASE
    ldr r1, =0b00001000000000000001000000000000
    str r1, [r0, #GPFSEL0]
    ldr r1, =0b00000000001000000000000000001001
    str r1, [r0, #GPFSEL1]
    ldr r1, =0b00000000001000000000000001000000
    str r1, [r0, #GPFSEL2]


    @Se programa el contador C1 (leds) y C3 (altavoz)
    ldr r0, =STBASE
    ldr r1, [r0, #STCLO]
    add r1, #2 			@Encender los leds en 2 microsegundos :)
    str r1, [r0, #STC1]		@Activamos C1
    str r1, [r0, #STC3] 	@Activamos C3

    @Se habilitan las interrupciones para C1
    ldr r0, =INTBASE
    mov r1, #0b0010
    str r1, [r0, #INTENIRQ1]

    @Se habilitan las interrupciones para C3
    mov r1, #0b10000011
    str r1, [r0, #INTFIQCON]

    @Se activan las interrupciones globales
    mov r0, #0b00010011 @SVC + IRQ enabled
    msr cpsr_c, r0

    ldr r0, =GPBASE
interruptores:				@Detectamos si hemos pulsado algún boton
    ldr r1, [r0, #GPLEV0]
    tst r1, #0b0100		@si Pulsamos el izquierdo
    beq todos
    tst r1, #0b1000		@ si pulsamos el derecho
    beq secuencias
    b interruptores

/*-----------------------------------------------FIQ activamos altavoz---------------------------*/
fiq_handler:
    ldr r9, =punteroNota
    ldr r9, [r9]
    ldr r10, =notaFS
    ldr r10, [r10, r9, LSL #2] @ R2 <- notaFS[punteroNota]
	ldr r11, =SILEN
	cmp r10, r11		@ Si R10 que es la nota actual es igual R11 entoce un silencio y saltamos a silencio
	beq silencio

@Activamos el altavoz
    ldr r9, =GPBASE
    ldr r12, =altaon
    ldr r11, [r12]
    eors r11, #1
    str r11, [r12]

@Encendemos/ Apagamos el altavoz
    mov r11, #0b10000
    streq r11, [r9, #GPCLR0]
    strne r11, [r9, #GPSET0]

silencio:    

    ldr r8, =STBASE
    mov r9, #0b1000      @Con esto reiniciamos el estado de la interrupcion
    str r9, [r8, #STCS]  
    
    ldr r9, [r8, #STCLO] @Reprogramamos el STC1 para 440Hz
    add r9, r10
    str r9, [r8, #STC3]

    subs pc, lr, #4

/*-------------------------------------------------IRQ controlamos el tiempo y encendemos los led--------------*/
irq_handler:
    push {r0, r1, r2, r3, r4}

    ldr r1, =punteroNota  @Cargamos el puntero punteroNota
    ldr r2, [r1]                 @Cargamos el valor del puntero de punteroNota
    mov r4, #NUMNOTAS   @ Indicamos cuantas notas hay para poder comparar y empezar desde 0
    add r2, #1
    cmp r2, r4
    moveq r2, #0
    str r2, [r1] 		@punteroNota = punteroNota++ % NUMNOTAS

	@Activamos los leds
    ldr r0, =GPBASE   		
    ldr r3, =ledon 		
    ldr r1, [r3]     
    ldr r2, =modoLed			@R2= el modo elegido del led
    ldr r2, [r2]
    cmp r2, #1				@ Si el modo es 1 saltamos al boton izquierdo
    beq todo
    b secuencia				@ Si no saltamos a la opcion 2

fin:
					@Configuramos la duración del altavoz y de los leds
    ldr r1, =punteroNota 			@Cargamos el puntero punteroNota
    ldr r2, [r1]       				 @Cargamos el valor del puntero de punteroNota
    ldr r3, =duratFS		
    ldr r3, [r3, r2, LSL #2] 			@ R4 <- duratFS[punteroNota]

    ldr r0, =STBASE
    mov r1, #0b0010      @Con esto reiniciamos el estado de la interrupcion
    str r1, [r0, #STCS]  @End Of Interrupt from System Timer

    ldr r1, [r0, #STCLO] @Reprogramamos el STC1 para 1000ms
    add r1, r3 @STC1 = ValorActualDelSTClock = duratFS[punteroNota]
    str r1, [r0, #STC1]

    pop {r0, r1, r2, r3, r4}
    subs pc, lr, #4

/*----------------------------------------------Opciones del interruptor---------------------------*/
todos:						@Opción izquierda fuera del IRQ
    ldr r1, =modoLed
    mov r2, #1
    str r2, [r1]
	ldr r1, =ledon
	mov r2, #0
	str r2, [r1]
    b interruptores
    
todo:						@Opción izquierda dentro del IRQ
    eors r1, #1  @ledon = !ledon
    str r1, [r3]
    /* GUIA     10987654321098765432109876543210 */
    ldr r10, =0b00001000010000100000111000000000
    streq r10, [r0, #GPCLR0]
    strne r10, [r0, #GPSET0]
    b fin
/*_____________________________Opcion Derecha__________________*/
secuencias:					@Opción derecha fuera del IRQ
    ldr    r1, =0b00001000010000100000111000000000 @ Hay que usar ldr en vez de mov cuando hay muchos unos
    str	r1, [r0, #GPCLR0] @ Apagamos todos los leds
    ldr r1, =modoLed
	ldr r3, [r1]
	cmp r3, #0
	beq interruptores
    mov r2, #0
    str r2, [r1]
	ldr r1, =ledon
	mov r2, #-1
	str r2, [r1]
    b interruptores
    
secuencia:							@Opción derecha dentro  el IRQ
    ldr r2, =patron      			@Cargamos el puntero de patron
    ldr r4, [r2, r1, LSL #2] 		@ R4 <- patron[ledon]
    str r4, [r0, #GPCLR0]   		@Apagamos el led actual

    add r1, #1
    cmp r1, #6
    moveq r1, #0
    str r1, [r3] 				@ledon = ledon++ % 6

    ldr r4, [r2, r1, LSL #2] 		@ R4 <- patron[ledon]
    str r4, [r0, #GPSET0]		@Encendemos el led que le toca
    b fin
/*--------------------------------------------------Opciones del interruptor------------------------*/


.word SILEN
.include "vader.inc"

punteroNota: .word -1
altaon: .word 0
ledon: .word -1
modoLed: .word 0
patron: .word 0b00000000000000000000001000000000
    .word 0b00000000000000000000010000000000
    .word 0b00000000000000000000100000000000
    .word 0b00000000000000100000000000000000
    .word 0b00000000010000000000000000000000
    .word 0b00001000000000000000000000000000
