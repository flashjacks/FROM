;*** FlashROM para FLASHJACKS V1.4
;

;*** Cargador de instrucciones de carga automatica al arranque en FLASHJACKS.
;

; Ensamblado con sjASM v0.42c
; http://www.xl2s.tk/
;
; Ejecutar: sjasm.exe FROM.ASM FROM.COM
;
;


; Código ASCII
LF	equ	0ah
CR	equ	0dh
ESC	equ	1bh
; Standard BIOS and work area entries
CLS	equ	000C3h
CHSNS	equ	0009Ch
KILBUF	equ	00156h

; Varios
CALSLT  equ     0001Ch
BDOS	equ	00005h
WRSLT	equ	00014h
ENASLT	equ	00024h
FCB	equ	0005ch
DMA	equ	00080h
RSLREG	equ	00138h
RAMAD1	equ	0f342h
RAMAD2	equ	0f343h
BUFTOP	equ	08000h
CHGET	equ	0009fh
POSIT	equ	000C6h
MNROM	equ	0FCC1h	; Main-ROM Slot number & Secondary slot flags table
DRVINV	equ	0FB22H	; Installed Disk-ROM

	org	0100h

START:
	jp	Main

MESVER:
	db	"Cargador FlashROM v1.40",CR,LF
	db	"2018 FlashJacks by Aquijacks"
MESend:
	db	CR,LF,CR,LF,"$"
MESend1:
	db	CR,LF,"$"

CursorOFF:
	db	ESC,"x5","$"
CursorON:
	db	ESC,"y5","$"

HlpMes:
	db	"Teclear: FROM NOMBRE1.ROM NOMBRE2.ROM",CR,LF
	db	"         FROM /R /Sxx /My NOMBRE.ROM",CR,LF
	db	CR,LF
	db	" * donde 'Xx' es Slot y 'xX' es Subslot",CR,LF
	db	"(xx: Slot FlashROM de FlashJacks)",CR,LF
	db	CR,LF
	db	" * donde 'y' es Numero de Mapper:",CR,LF
	db	"0: AUTO      1:KONAMI5	 2:ASCII8K",CR,LF
	db	"3: KONAMI4   4:ASCII16K  5:SUNRISE",CR,LF
	db	"6: SINFOX    7:ROM16K	 8:ROM32K",CR,LF
	db	"9: ROM64K    A:RTYPE	 B:ZEMINA6480",CR,LF
	db	"C: ZEMINA126 D:FMPAC	 E:CROSSBLAIM",CR,LF
	db	"F: SLODERUN",CR,LF,"$"
	
DosErr:
	db	"Archivo no encontrado!",CR,LF,"$"
Text_FlashOK:
	db	"FlashROM de FlashJacks en el Slot $"
NO_FLSH:
	db	"FlashROM de FlashJacks no encontrado!",CR,LF,"$"
NO_FLSH2:
	db	"No encontrada unidad 2 FlashROM!",CR,LF,"$"
Priclus:
	db	"Primer cluster del archivo: $"
Cargada:
	db	" cargado en el Slot $"
Recuerde:
	db	"Recuerde: HardReset para confirmar,",CR,LF
	db	"          PowerOff para borrar y",CR,LF
	db	"          /R para forzar SoftReset.",CR,LF,"$"
MapperSel:
	db	"Mapper seleccionado: $"
MapAuto:
	db	"AUTO",CR,LF,"$"
MapKONAMI5:
	db	"KONAMI5",CR,LF,"$"
MapASCII8K:
	db	"ASCII8K",CR,LF,"$"
MapKONAMI4:
	db	"KONAMI4",CR,LF,"$"
MapASCII16K:
	db	"ASCII16K",CR,LF,"$"
MapSUNRISE:
	db	"SUNRISE",CR,LF,"$"
MapSINFOX:
	db	"SINFOX",CR,LF,"$"
MapROM16K:
	db	"ROM16K",CR,LF,"$"
MapROM32K:
	db	"ROM32K",CR,LF,"$"
MapROM64K:
	db	"ROM64K",CR,LF,"$"
MapRTYPE:
	db	"RTYPE",CR,LF,"$"
MapZEMINA6480:
	db	"ZEMINA6480",CR,LF,"$"
MapZEMINA126:
	db	"ZEMINA126",CR,LF,"$"
MapFMPAC:
	db	"FMPAC",CR,LF,"$"
MapCROSS:
	db	"CROSS BLAIM",CR,LF,"$"
MapSLODE:
	db	"SLODE RUNNER",CR,LF,"$"

Main:
	; Hace un clear Screen o CLS.
	xor    a		; Pone a cero el flag Z.
	ld     ix, CLS          ; Petición de la rutina BIOS. En este caso CLS (Clear Screen).
	ld     iy,(MNROM)       ; BIOS slot
        call   CALSLT           ; Llamada al interslot. Es necesario hacerlo así en MSXDOS para llamadas a BIOS.
	; Imprime en pantalla en texto inicial.
	ld	de,MESVER
	ld	c,9
	call	BDOS		; Print MESVER message (FL info)

; *** Auto-detection routine
	ld	b,1		; B=Primary Slot
BCLM:
	ld	c,0		; C=Secondary Slot
BCLMI:
	push	bc		; Guarda en la Pila el Slot/Subslot.
	call	AutoSeek	; Hace búsqueda de FlashJacks en la propuesta Slot/Subslot
	pop	bc		; Recupera la pila Slot/Slubslot.
	ld	a,(ERMSlt)	; Recupera formato FxxxSSPP último.
	bit	7,a		; Verifica el bit de Slot expandido.
	jp	z, BCLMA	; Si no está expandido, salta al siguinte Slot ignorando los Subslots.
	inc	c		; Incrementa Subslot.
	ld	a,c		; Lo pasa al acumulador.
	cp	4		; Compara que no supere 4 (No existe el subslot 4).
	jr	nz,BCLMI	; Jump if Secondary Slot < 4
BCLMA:	inc	b		; Incrementa Slot Primario.
	ld	a,b		; Lo pasa al acumulador.
	cp	04h		; Compara que no supere 4 (No existe el slot 4).
	jp	nz,BCLM		; Jump if Primary Slot < 4


BCLM2:	ld	a,(SubslotA)	; Una vez barrido todos los Slots/Subslots, mira si hay algo en SubslotA. (Hace falta 1 como mínimo para cargar una ROM)
	cp	00h
	jp	z, NO_FND
	
	ld	de,MESend1
	ld	c,9
	call	BDOS		; Print 2x CR & LF character

	ld	a,(SubslotA)
	ld	(ERMSlt), a	; Carga el primer Subslot encontrado.
	jp	Parameters	; Continua con el programa.
	
NO_FND:
	ld	de,NO_FLSH	; Si no hay nada en ningún Subslot, fin del programa.
	jp	Done

AutoSeek:
	ld	a,b		; Pasa el acumulador el Slot Primario.
	ld	hl,MNROM	; Bios Slot 0FCC1h. Lo pasa a hl.
	ld	d,0		; Pone a cero d.
	ld	e,b		; Pasa a b el Slot Primario.
	add	hl,de		; Suma al BIOS Slot el Slot Primario. Esto fija en HL las banderas del Slot que se está tratando.
	bit	7,(hl)		; Mira si ese Slot está expandido o no.
	ld	a,b		; Pasa el acumulador el Slot Primario.
	jr	z,SalSlt	; Lee el FCC1h + NºSlot cada bit(7) si es expandido o no. Salta si no está expandido. a vale el NºSlot.
	; Si tiene subslot ejecuta lo siguiente.
	ld	a,c		; Reordena bc y lo transfiere en a con el formato FxxxSSPP
	sla	a
	sla	a
	or	b
	or	10000000b	; Le dice a EMRSlt que es un sublot. Bit 7 a 1.

SalSlt: ld	(ERMSlt),a	; format FxxxSSPP
	; Secuencia búsqueda si se trata de un DiskROM.
	ld	b,a		; Keep actual slot value
	bit	7,a
	jr	nz,SecSlt	; Jump if Secondary Slot
	and	3		; Keep primary slot bits
SecSlt:
	ld	c,a
	ld	a,(DRVINV)	; A = slot value of main Rom-disk
	bit	7,a
	jr	nz,SecSlt1	; Jump if Secondary Slot
	and	3		; Keep primary slot bits
SecSlt1:
	cp	c
	ld	a,b
	ret	z		; Return if Disk-Rom Slot
	ld	a,(DRVINV+2)	; A = slot value of second Rom-disk
	bit	7,a
	jr	nz,SecSlt2	; Jump if Secondary Slot
	and	3		; Keep primary slot bits
SecSlt2:
	cp	c
	ld	a,b
	ret	z		; Return if Disk-Rom Slot
	ld	a,(DRVINV+4)	; A = slot value of third Rom-disk
	bit	7,a
	jr	nz,SecSlt3	; Jump if Secondary Slot
	and	3		; Keep primary slot bits
SecSlt3:
	cp	c
	ld	a,b
	ret	z		; Return if Disk-Rom Slot
	ld	a,(DRVINV+6)	; A = slot value of fourth Rom-disk
	bit	7,a
	jr	nz,SecSlt4	; Jump if Secondary Slot
	and	3		; Keep primary slot bits
SecSlt4:
	cp	c
	ld	a,b		; Restore actual slot value
	ret	z		; Return if Disk-Rom Slot
	; Fin secuencia búsqueda si se trata de un DiskR
		
	di			; Desactiva interrupciones.
	ld	hl,4000h
	call	ENASLT		; Select a Slot in Bank 1 (4000h ~ 7FFFh)

	
	ld	a,019h		; Carga en un posible FMPAC el modo recepción instrucciones EPROM.
	ld	(5FFEh),a
	ld	a,076h
	ld	(5FFFh),a

	ld	a,(4000h)	; Hace una lectura para tirar cualquier intento pasado de petición.
	
	ld	a,0aah
	ld	(4340h),a	; Petición acceso comandos FlashJacks. 
	ld	a,055h
	ld	(43FFh),a	; Autoselect acceso comandos FlashJacks. 
	ld	a,020h
	ld	(4340h),a	; Petición código de verificación de FlashJacks

	ld	b,16
	ld	hl,4100h	; Se ubica en la dirección 4100h (Es donde se encuentra la marca de 4bytes de FlashJacks)
RDID_BCL:
	ld	a,(hl)		; (HL) = Primer byte info FlashJacks
	cp	057h		; El primer byte debe ser 57h.
	jr	z,ID_2
	ld	a,000h		; Descarga en un posible FMPAC el modo recepción instrucciones EPROM.
	ld	(5FFEh),a
	ld	a,000h
	ld	(5FFFh),a
	ei			; Activa interrupciones.
	ret

ID_2:	inc	hl
	ld	a,(hl)		; (HL) = Segundo byte info FlashJacks
	cp	071h		; El segundo byte debe ser 71h.
	jr	z,ID_3
	ld	a,000h		; Descarga en un posible FMPAC el modo recepción instrucciones EPROM.
	ld	(5FFEh),a
	ld	a,000h
	ld	(5FFFh),a
	ei			; Activa interrupciones.
	ret

ID_3:	inc	hl
	ld	a,(hl)		; (HL) = Tercer byte info FlashJacks
	cp	098h		; El tercer byte debe ser 98h.
	jr	z,ID_4
	ld	a,000h		; Descarga en un posible FMPAC el modo recepción instrucciones EPROM.
	ld	(5FFEh),a
	ld	a,000h
	ld	(5FFFh),a
	ei			; Activa interrupciones.
	ret

ID_4:	inc	hl
	ld	a,(hl)		; (HL) = Cuarto byte info FlashJacks
	cp	022h		; El cuarto byte debe ser 22h.
	jr	z,ID_OK		; Salta si da todo OK.
	ld	a,000h		; Descarga en un posible FMPAC el modo recepción instrucciones EPROM.
	ld	(5FFEh),a
	ld	a,000h
	ld	(5FFFh),a
	ei			; Activa interrupciones.
	ret

ID_OK:	inc	hl
	ld	a,(hl)		; Al incrementar a 104h sale del modo info FlashJacks
	ld	a,000h		; Descarga en un posible FMPAC el modo recepción instrucciones EPROM.
	ld	(5FFEh),a
	ld	a,000h
	ld	(5FFFh),a
	
FLH_FND:
	ld	a,(RAMAD1)
	ld	hl,4000h
	call	ENASLT		; Select Main-RAM in MSX"s Bank 1
	ld	a,(RAMAD2)
	ld	hl,8000h
	call	ENASLT		; Select Main-RAM at bank 8000h~BFFFh
	ei			; Activa interrupciones.

	ld	de,Text_FlashOK ; Puntero del texto de FLASHJACKS encontrado
	ld	c,9
	call	BDOS		; Imprime el texto de FLASHJACKS encontrado
	
	ld	a,(ERMSlt)	; Recupera EMRSlt. Formato FxxxSSPP
	and	3		; Se queda solo con el número del Slot principal.
	add	a,30h		; Lo convierte a carácter.
	ld	e,a		; Lo transfiere a BDOS
	ld	c,2
	call	BDOS		; Imprime el número del Slot primario.
	ld	a,(ERMSlt)	; Recupera EMRSlt. Formato FxxxSSPP
	bit	7,a		; Compara si el subslot está activo.
	jr	z,FinSlt2	; Salta si no hay subslot. 
	ld	e,02Dh		; Vuelca el carácter guión.
	ld	c,2
	call	BDOS		; Imprime un guión por pantalla.
	ld	a,(ERMSlt)	; Recupera EMRSlt. Formato FxxxSSPP
	and	0Ch		; Se queda solo con el número del Subslot.
	srl	a		; Lo mueve a unidades.
	srl	a
	add	a,30h		; Lo convierte a carácter.
	ld	e,a		; Lo transfiere a BDOS
	ld	c,2
	call	BDOS		; Imprime el número del Subslot.	
FinSlt2:ld	de,MESend1	; Vuelca carácter enter.
	ld	c,9
	call	BDOS		; Imprime un enter.

; Guarda en SubslotA el primer valor, en SubslotB el segundo valor, etc.... hasta 8 valores (2 Cartuchos de FlashJacks con todos sus Subslots con FlashRoms)
	ld	a, (Pasopor0)
	cp	00h
	jp	nz, Paso1
	inc	a
	ld	(Pasopor0), a
	ld	a,(ERMSlt)
	ld	(SubslotA), a
	ret
Paso1:	
	ld	a, (Pasopor0)
	cp	01h
	jp	nz, Paso2
	inc	a
	ld	(Pasopor0), a
	ld	a,(ERMSlt)
	ld	(SubslotB), a
	ret
Paso2:	
	ld	a, (Pasopor0)
	cp	02h
	jp	nz, Paso3
	inc	a
	ld	(Pasopor0), a
	ld	a,(ERMSlt)
	ld	(SubslotC), a
	ret
Paso3:	
	ld	a, (Pasopor0)
	cp	03h
	jp	nz, Paso4
	inc	a
	ld	(Pasopor0), a
	ld	a,(ERMSlt)
	ld	(SubslotD), a
	ret
Paso4:	
	ld	a, (Pasopor0)
	cp	04h
	jp	nz, Paso5
	inc	a
	ld	(Pasopor0), a
	ld	a,(ERMSlt)
	ld	(SubslotE), a
	ret
Paso5:	
	ld	a, (Pasopor0)
	cp	05h
	jp	nz, Paso6
	inc	a
	ld	(Pasopor0), a
	ld	a,(ERMSlt)
	ld	(SubslotF), a
	ret
Paso6:	
	ld	a, (Pasopor0)
	cp	06h
	jp	nz, Paso7
	inc	a
	ld	(Pasopor0), a
	ld	a,(ERMSlt)
	ld	(SubslotG), a
	ret
Paso7:	
	ld	a, (Pasopor0)
	cp	07h
	jp	nz, Paso8
	inc	a
	ld	(Pasopor0), a
	ld	a,(ERMSlt)
	ld	(SubslotH), a
	ret
Paso8:	
	ret

; *** End of Auto-detection routine

Parameters:
	ld	hl,(DMA)	; Esto pone un 255 al final de la entrada de parámetros. Necesario para los MSX1.
	ld	h,0
	ld	bc,DMA +1
	add	hl,bc
	ld	(hl),255
	
	ld	hl,DMA
Espaci:	inc	hl		; Esto ignora todos los espacios que hay en medio.
	ld	a,(hl)
	cp	020h
	jr	z,Espaci	; Bucle ignorar espacios.
	cp	255
	ld	de,HlpMes	; Si hay error en la síntasis, expulsa la ayuda. Esto es cuando no hay ningún parámetro ni nombre de archivo.
	jp	z,Done		; Jump if no parameter

	ld	a,07Eh		; Fuerza el Mapper en modo AUTO
	ld	(NumMapper),a
	
	call	ResPar1		; Borra la marca del reset si la hubiera.

; Check parameter /S /M /R . En esta primera parte difiere de la segunda al hacer un tratamiento diferente si no encuentra parámetros. (Búsqueda del doble archivo)
	ld	c,"S"		; 'S' character
	call	SeekPar		; Busqueda con avance de letra.
	cp	254		; Si no ha encontrado parámetros, procede a la carga automática del archivo.
	jp	z,No_S		; Salta a la ejecución automática si el parámetro S no se ha encontrado.
	cp	253
	jp	z,SecGet	; Salta si es el parámetro S.
	ld	c,"M"		; 'M' character
	call	SeekPar2	; Búsqueda si es el parámetro M sin avance de letra.
	cp	253
	jp	z,SecMap	; Salta si es el parámetro M.
	ld	c,"R"		; 'R' character
	call	SeekPar2	; Búsqueda si es el parámetro R sin avance de letra.
	cp	253
	call	z,ResPar2	; Si es R hace una marca de reset posterior.
	cp	255
	ld	de,HlpMes	; Si hay error en la síntasis, expulsa la ayuda.
	jp	z,Done		; Jump if syntax error

; Check parameter /S /M /R . En esta segunda parte el bucle es infinito hasta agotar todos los comandos.
SecCon:	ld	c,"S"		; 'S' character
	call	SeekPar		; Busqueda con avance de letra.
	cp	254		; Si no ha encontrado parámetros, procede a la ejecución del parámetro anterior.
	jp	z,ContSe	; Salta a la ejecución de los parámetros si no hay mas.
	cp	253
	jp	z,SecGet2	; Salta si es el parámetro S.
	ld	c,"M"		; 'M' character
	call	SeekPar2	; Búsqueda si es el parámetro M sin avance de letra.
	cp	253
	jp	z,SecMap2	; Búsqueda si es el parámetro M.
	ld	c,"R"		; 'R' character
	call	SeekPar2	; Búsqueda si es el parámetro R sin avance de letra.
	cp	253
	call	z,ResPar2	; Si es R hace una marca de reset posterior.
	cp	255
	ld	de,HlpMes	; Si hay error en la síntasis, expulsa la ayuda.
	jp	z,Done		; Jump if syntax error
	jp	SecCon		; Salta a la ejecución de los parámetros si no hay error.

; Subsecuencias de búsqueda de parámetros
SecMap: call	GetMap		; Get the slot number from parameter
	cp	255
	ld	de,HlpMes	; Si hay error en la síntasis, expulsa la ayuda.
	jp	z,Done		; Jump if syntax error
	jp	SecCon

SecGet:	call	GetNum		; Get the slot number from parameter
	cp	255
	ld	de,HlpMes	; Si hay error en la síntasis, expulsa la ayuda.
	jp	z,Done		; Jump if syntax error
	jp	SecCon

SecMap2: call	GetMap		; Get the slot number from parameter
	cp	255
	ld	de,HlpMes	; Si hay error en la síntasis, expulsa la ayuda.
	jp	z,Done		; Jump if syntax error
	jp	SecCon

SecGet2:call	GetNum		; Get the slot number from parameter
	cp	255
	ld	de,HlpMes	; Si hay error en la síntasis, expulsa la ayuda.
	jp	z,Done		; Jump if syntax error
	jp	SecCon
; Fin subsecuencias de búsqueda de parámetros

; Ejecución de los parámetros dados.
ContSe:	ld	a,(ForzaSlot)	; Recupera ForzaSlot para saber si hay Forzado de Slot principal.
	cp	01h		; Si hay Forzado de Slot
	jp	z,Slot_Pr	; Salta a la gestión de Slot Principal.

	call	CheckSLT	; check if Megaflash is inserted in /Sxx Slot
	ld	a,00h
	cp	e
	jp	nz,Done		; Comprueba si ha habido un error. Salta a fallo de carga si lo ha habido.

	call	TR_Name		; Solicita la carga del nombre de archivo en FCB desde el puntero HL orientado a DMA.
	call	PreFCB
	ld	a,00h
	cp	e
	jp	nz,Done		; Comprueba si ha habido un error. Salta a fallo de carga si lo ha habido.
	jp	Fin_OK


Slot_Pr:call	CheckS2		; check if Megaflash is inserted in /Sxx Slot
	ld	(ERMSlt),a	; 
	ld	a,00h
	cp	e
	jp	nz,Done		; Comprueba si ha habido un error. Salta a fallo de carga si lo ha habido.
	call	TR_Name		; Solicita la carga del nombre de archivo en FCB desde el puntero HL orientado a DMA.
	call	PreFCB		; Carga el FCB en la FlashROM de FlashJacks.
	ld	a,00h
	cp	e
	jp	nz,Done		; Comprueba si ha habido un error. Salta a fallo de carga si lo ha habido.
	jp	Fin_OK

No_S:
	ld	a,(SubslotA)	; Si no hay tampoco FlashRom salta el mensaje de FlashROM no encontrado.
	ld	(ERMSlt),a	; Vuelca el contenido de SubslotA por si tiene valor de carga.
	or	a
	ld	de,NO_FLSH	; Pointer to NO_FLSH message
	jp	z,Done		; Jump if Flash Rom not found
	call	TR_Name		; Solicita la carga del nombre de archivo en FCB desde el puntero HL orientado a DMA.
	call	PreFCB		; Carga el FCB en la FlashROM de FlashJacks.
	ld	a,00h
	cp	e
	jp	nz,Done		; Comprueba si ha habido un error. Salta a fallo de carga si lo ha habido.
	ld	a,(hl)		; Carga hl de DMA nuevo.
	cp	255
	jp	z,Fin_OK	; Si detecta fin de peticiones (no hay mas texto en los parámetros) abandona el programa.
	ld	a,(SubslotB)	; Si no hay un segundo FlashRom salta el mensaje de FlashROM no encontrado.
	ld	(ERMSlt),a	; Vuelca el contenido de SubslotA por si tiene valor de carga.
	or	a
	ld	de,NO_FLSH2	; Pointer to NO_FLSH message
	jp	z,No_S2		; Salta a un fin OK pero sin flash si no encuentra la segunda unidad.
	call	TR_Name		; Solicita la carga del nombre de archivo en FCB desde el puntero HL orientado a DMA.
	call	PreFCB
	ld	a,00h
	cp	e
	jp	z,Fin_OK	; Comprueba si no ha habido un error.
No_S2:	ld	c,9
	call	BDOS		; Imprime el mensaje de error pero continua ya que el primer archivo ha sido OK.
	ld	de,MESend1	; Return para espaciado.
	ld	c,9
	call	BDOS		; Imprime return
	jp	Fin_OK

;--- Fin del programa principal.
;------------------------------------------------------------------------------------------------------
;------------------------------------------------------------------------------------------------------


; Borra o coloca la marca de reset posterior
ResPar1:ld	a,00h
	ld	(ResetOK),a	; Borra la marca de reset.
	ret
ResPar2:push	af		; Guarda el acumulador.
	ld	a,01h
	ld	(ResetOK),a	; Coloca la marca de reset.
	pop	af		; Devuelve el acumulador.
	jp	GetEsp		; Salta a ignorar espacios.
	ret

; Seek Parameter Routine
; In: B = Length of parameters zone, C = Character, HL = Pointer address
; Out: A = 0 if Parameter not found or 255 if syntax error, DE = HlpMes if syntax error
; Modify AF, BC, HL

SeekPar:
	ld	a,(hl)
	cp	"/"		; Seek '/' character
	ld	a, 254		; Devuelve valor "Sin parámetros encontrados"
	ret	nz
	inc	hl		; Va a leer la letra del parámetro encontrado.
SeekPar2:
	ld	a,(hl)		; Carga la letra leida en el acumulador
	cp	c		; Compare found character with the input character
	ld	a, 253		; Devuelve error si no encuentra una letra correcta.
	ret	z		; Devuelve la letra del parámetro encontrado.
	ld	a,(hl)		; Carga la letra leida en el acumulador
	sub	020h		; Pasa de Mayúsculas a Minúsculas.
	cp	c		; Compare found character with the input character
	ld	a, 253		; Devuelve error si no encuentra una letra correcta.
	ret	z		; Devuelve la letra del parámetro encontrado.
	ld	a, 255		; Devuelve error si no encuentra una letra correcta.
	ret	

; Esto sirve para coger los dos números que van despues de la Sxx
; Los transfiere en formato EMRSlt. Si detecta un solo número, dispara a 01h la variable ForzaSlot.Fuerza Slot principal.
GetNum:	ld	a, 00h		; Pone a cero la variable ForzaSlot.
	ld	(ForzaSlot), a	
	inc	hl		; Incrementa el puntero del DMA
	ld	a,(hl)		; Transfiere su contenido a a.
	sub	030h		; Resta 30 para tener el número real en a.
	cp	04h		; Compara si supera el valor 3 o es un caracter.
	jp	c, GetNum1	; Si es menor de 4 continua.
	ld	a, 255		; Devuelve error si el número está por encima de 3 o es un caracter.
	ret			; Fin de la subrutina.
GetNum1:cp	00h		; Compara si el primer valor es cero.
	jp	nz, GetNum2	; Si no es cero, continua.
	ld	a, 255		; Devuelve error si el número es un cero.
	ret			; Fin de la subrutina.
GetNum2:ld	b,a		; Transfiere el resultado a b para posterior gestión.
	inc	hl		; Incrementa el puntero del DMA
	ld	(ERMSlt),a	; Graba en formato FxxxSSPP
	ld	a,(hl)		; Transfiere su contenido a a.
	cp	020h		; Busca si hay un espacio.
	jp	z,GetPri	; Salta para tratamiento como Slot primario único.
	sub	030h		; Resta 30 para tener el número real en a.
	cp	04h		; Compara si supera el valor 3 o es un caracter.
	jp	c,GetNum3  
	ld	a,255		; Devuelve error si el número está por encima de 3 o es un caracter.
	ret			; Fin de la subrutina.
GetNum3:sla	a		; Desplaza resultado de subslot a la posición SS
	sla	a
	or	b		; Añade resultado del slot a la posición PP
	add	080h		; Le dice a EMRSlt que es un sublot. Bit 7 a 1.
	ld	(ERMSlt),a	; Graba en formato FxxxSSPP
GetEsp:	inc	hl		; Esto ignora todos los espacios que hay en medio.
	ld	a,(hl)
	cp	020h
	jr	z,GetEsp	; Bucle ignorar espacios.
	ret
GetPri:	ld	a, 01h		; Marca a 1 que se desea un forzado a un Slot primario.
	ld	(ForzaSlot), a	
	jp	GetEsp		; Fin del tratamiento, va al ignorar espacios.

; Esto sirve para coger el número que va despues de la Mx
; Los transfiere a la variable NumMapper.
GetMap:	inc	hl		; Incrementa el puntero del DMA
	ld	a,(hl)		; Transfiere su contenido a a.
	sub	030h		; Resta 30 para tener el número real en a.
	cp	0Ah		; Compara si supera el valor A o se sale de un valor válido
	jp	c, GetMap1	; Si es menor de A continua.(Números enteros)
	sub	7		; Le resta 7 para llegar a los carácteres mayúsculas.
	cp	10h		; Compara si supera el valor 10h o se sale de un valor válido
	jp	c, GetMap1	; Si es menor de 10h continua
	sub	020h		; Le resta 20h para llegar a los carácteres minúsculas.
	cp	10h		; Compara si supera el valor 10h o se sale de un valor válido
	jp	c, GetMap1	; Si es menor de 10h continua
	ld	a, 255		; Devuelve error si el número está por encima de 3 o es un caracter.
	ret			; Fin de la subrutina.
GetMap1:cp	00h		; Compara si el primer valor es cero.
	jp	nz, GetMap2	; Si no es cero, continua. Si es cero, no toca el NumMapper dejándolo en automático.
	jp	GetEsp
	ret			; Fin de la subrutina. Si es cero, es auto por lo que no toca la variable NumMapper
GetMap2:ld	(NumMapper),a	; Graba en NumMapper el valor del Mapper.
	jp	GetEsp
	ret			; Fin de la subrutina.

; Rutina para transferir un nombre con inicio en el puntero HL orientado a DMA (Acceso parámetros adicionales al archivo).
; Transfiere de HL--DMA al FCB el nombre del archivo ya corregido en tamaño y extensión.
; Incrementa el puntero HL--DMA hasta la posición final del nombre de archivo.(Por si hubiera un segundo archivo u otra cosa)
	
TR_Name:push	de		; Guarda variables a la pila, excepto HL que si interesa saber por donde ha dejado el puntero de los parámetros.
	push	af
	push	bc
	; Borrado de Namefile y FCB(Solo nombre archivo) con espacios. 
	push	hl		; Guarda en la pila el puntero DMA para borrado a espacios FCB y Namefile.
	ld	hl,Namefile+1	; Transfiere el nombre del archivo a hl
	ld	a,8+3		; Nombre+ext a borrar con espacios.
B_Name:	ld	(hl),020h	; Carga el caracter espacio en la ubicación del puntero de HL.
	inc	hl		; Incrementa el puntero de Namefile.
	dec	a		; Decrementa posiciones restantes.
	jp	nz,B_Name	; Bucle borrado Nombre archivo.
	ld	hl,FCB+1	; Transfiere el FCB a hl.
	ld	a,8+3		; Nombre+ext a borrar con espacios.
B_Name2:ld	(hl),020h	; Carga el caracter espacio en la ubicación del puntero de HL.
	inc	hl		; Incrementa el puntero de FCB.
	dec	a		; Decrementa posiciones restantes.
	jp	nz,B_Name2	; Bucle borrado Nombre archivo en FCB.
	pop	hl		; Retorna de la pila el puntero DMA.	
	; Gestión del nombre del archivo y volcado en FCB
	ld	de,Namefile+1	; Ubica el puntero de la variable Namefile
	ld	b, 8+3		; Ubica el tamaño total de Namefile.
C_Name:	ld	a,(hl)		; Carga el puntero de HL-DMA
	cp	02Eh		; Mira si hay un punto para tratarlo como extensión.
	jp	z,E_Name	; Salto por punto.
	cp	255		; Mira si hay un enter como final de parámetros.
	jp	z,Z_Name	; Salta para transferir hasta aquí el nombre de los archivos.
	ld	a,b		; Carga el contador decreciente
	cp	03h		; Compara si le quedan solo 3 carácteres (extensión)
	jp	z,X_Name	; Salta por llegada a la extensión.
	ld	a,(hl)		; Transfiere de DMA a FCB
	ld	(de),a
	inc	de		; Incrementa punteros DMA y FCB	
	inc	hl
	dec	b		; Decrementa posiciones restantes.
	jp	C_Name		; Bucle Nombre archivo.
E_Name: ld	a,b		; Carga el contador decreciente 
	cp	03h		; Compara si le quedan solo 3 carácteres (extensión)
	jp	z,X_Name	; Salta por llegada a la extensión. 
	ld	a,020h		; Carga el caracter espacio.
	ld	(de),a		; Lo vuelca al FCB
	inc	de		; Incrementa puntero FCB	
	dec	b		; Decrementa posiciones restantes.
	jp	E_Name		; Bucle hasta llegada a extensión por punto.
X_Name:	ld	a,(hl)		; Carga el puntero de HL-DMA 
	cp	02Eh		; Mira si hay un punto para tratarlo como extensión.
	jp	z,Y_Name	; Si encuentra el punto, salta para tratar la extensión.
	cp	255		; Mira que no sea fin de parámetros.
	jp	z,Z_Name	; Salta por fin de parámetros. El resto queda con espacios.
	inc	hl		; Incrementa el puntero hasta encontrar un punto.
	jp	X_Name		; Bucle hasta encontrar un punto o fin de parámetros.
Y_Name: inc	hl		; Incrementa el puntero para ler extensión.
Y2_Name:ld	a,(hl)		; Transfiere de DMA a FCB 
	cp	255		; Mira que no sea fin de parámetros.
	jp	z,Z_Name	; Si la extensión se acaba antes de tiempo, pasa al volcado.(El resto está con espacios)
	cp	020h
	inc	hl		; Esto lo hace para incrementar el puntero en caso de encontrar el espacio.
	jp	z,Z_Name	; Si la extensión tiene un espacio, pasa al volcado.(El resto está con espacios)
	dec	hl		; Si no encuentra el espacio, vuelve a dejar el puntero donde estaba.
	ld	(de),a 
	inc	de		; Incrementa punteros DMA y FCB	
	inc	hl
	djnz	Y2_Name		; Bucle de copia de extensión hasta acabar B=0	
W_Name:	ld	a,(hl)		; Transfiere de DMA a FCB 
	cp	020h
	inc	hl		; Esto lo hace para incrementar el puntero en caso de encontrar el espacio.
	jp	z,W_Name	; Una vez que no hay mas espacios detrás del nombre de archivo + ext. continua.
	dec	hl		; Decrementa hl para dejarlo en el paso anterior.
Z_Name:	ld	a,(hl)		; Transfiere de DMA a FCB 
	cp	020h		; Compara hl con el espacio.
	inc	hl		; Esto lo hace para incrementar el puntero en caso de encontrar el espacio.
	jp	z,Z_Name	; Obliga a hacer un purgado de espacios para dejar preparado el puntero del DMA para próximas instrucciones.
	dec	hl		; Si el siguiente no es espacio, recupera el puntero anterior.
	push	hl		; Guarda en la pila el puntero DMA.
	ld	hl,Namefile	; Transfiere el nombre del archivo a FCB.
	ld	de,FCB
	ld	bc,1+8+3
	ldir			; Bucle hasta completar los 1+8+3
	pop	hl		; Retorna de la pila el puntero DMA.
	pop	bc		; Retorna las variables iniciales de la pila.
	pop	af
	pop	de
	ret			; Devuelve la subrutina.

; ~~~ Rutina para chequear si la FlashROM está insertada en el parámetro /Sxx

CheckSLT:
	ld	a,(ERMSlt)	; Carga el valor cogido del parámetro /Sxx
	ld	e,a		; Lo transfiere a e
	ld	a,(SubslotA)	; Carga el posible valor del buffer.
	cp	e		; Compara.
	jp	nz, Check2	; Si no son iguales, salta al siguiente buffer.
	ld	de, 00h		; Si son iguales da resultado OK.	
	ret			; Devuelve la llamada
Check2:	ld	a,(SubslotB)	; Carga el posible valor del buffer
	cp	e		; Compara.
	jp	nz, Check3	; Si no son iguales, salta al siguiente buffer.
	ld	de, 00h		; Si son iguales da resultado OK.
	ret			; Devuelve la llamada
Check3:	ld	a,(SubslotC)	; Carga el posible valor del buffer
	cp	e		; Compara.
	jp	nz, Check4	; Si no son iguales, salta al siguiente buffer.
	ld	de, 00h		; Si son iguales da resultado OK.
	ret			; Devuelve la llamada
Check4:	ld	a,(SubslotD)	; Carga el posible valor del buffer
	cp	e		; Compara.
	jp	nz, Check5	; Si no son iguales, salta al siguiente buffer.
	ld	de, 00h		; Si son iguales da resultado OK.
	ret			; Devuelve la llamada
Check5:	ld	a,(SubslotE)	; Carga el posible valor del buffer
	cp	e		; Compara.
	jp	nz, Check6	; Si no son iguales, salta al siguiente buffer.
	ld	de, 00h		; Si son iguales da resultado OK.
	ret			; Devuelve la llamada
Check6:	ld	a,(SubslotF)	; Carga el posible valor del buffer
	cp	e		; Compara.
	jp	nz, Check7	; Si no son iguales, salta al siguiente buffer.
	ld	de, 00h		; Si son iguales da resultado OK.
	ret			; Devuelve la llamada
Check7: ld	a,(SubslotG)	; Carga el posible valor del buffer
	cp	e		; Compara.
	jp	nz, Check8	; Si no son iguales, salta al siguiente buffer.
	ld	de, 00h		; Si son iguales da resultado OK.
	ret			; Devuelve la llamada
Check8:	ld	a,(SubslotH)	; Carga el posible valor del buffer
	cp	e		; Compara.
	jp	nz, NO_FLH2	; Si no son iguales, salta a fallo ya que no hay mas.
	ld	de, 00h		; Si son iguales da resultado OK.
	ret			; Devuelve la llamada
NO_FLH2: ; No encuentra el Slot solicitado.
	ld	de,NO_FLSH	; Pointer to NO_FLSH message
	ret			; Devuelve la llamada con error

; ~~~ Fin de la rutina para chequear si la FlashROM está insertada en el parámetro /Sxx

; ~~~ Rutina para chequear si la FlashROM está insertada en el parámetro /Sx

CheckS2:ld	a,(SubslotA)	; Si no hay tampoco FlashRom salta el mensaje de FlashROM no encontrado.
	and	03h		; Solo coge el valor PP de FxxxSSPP
	ld	de,(ERMSlt)	; Vuelca el contenido del valor leido
	cp	e		; Compara con "a"
	ld	a,(SubslotA)	; Vuelca el contenido encontrado del subslot completo.
	ld	de, 00h		; Si son iguales da resultado OK.
	ret	z		; Devuelve la función si lo ha encontrado.
	ld	a,(SubslotB)	; Si no hay tampoco FlashRom salta el mensaje de FlashROM no encontrado.
	and	03h		; Solo coge el valor PP de FxxxSSPP
	ld	de,(ERMSlt)	; Vuelca el contenido del valor leido
	cp	e		; Compara con "a"
	ld	a,(SubslotB)	; Vuelca el contenido encontrado del subslot completo.
	ld	de, 00h		; Si son iguales da resultado OK.
	ret	z		; Devuelve la función si lo ha encontrado.
	ld	a,(SubslotC)	; Si no hay tampoco FlashRom salta el mensaje de FlashROM no encontrado.
	and	03h		; Solo coge el valor PP de FxxxSSPP
	ld	de,(ERMSlt)	; Vuelca el contenido del valor leido
	cp	e		; Compara con "a"
	ld	a,(SubslotC)	; Vuelca el contenido encontrado del subslot completo.
	ld	de, 00h		; Si son iguales da resultado OK.
	ret	z		; Devuelve la función si lo ha encontrado.
	ld	a,(SubslotD)	; Si no hay tampoco FlashRom salta el mensaje de FlashROM no encontrado.
	and	03h		; Solo coge el valor PP de FxxxSSPP
	ld	de,(ERMSlt)	; Vuelca el contenido del valor leido
	cp	e		; Compara con "a"
	ld	a,(SubslotD)	; Vuelca el contenido encontrado del subslot completo.	
	ld	de, 00h		; Si son iguales da resultado OK.
	ret	z		; Devuelve la función si lo ha encontrado.
	ld	a,(SubslotE)	; Si no hay tampoco FlashRom salta el mensaje de FlashROM no encontrado.
	and	03h		; Solo coge el valor PP de FxxxSSPP
	ld	de,(ERMSlt)	; Vuelca el contenido del valor leido
	cp	e		; Compara con "a"
	ld	a,(SubslotE)	; Vuelca el contenido encontrado del subslot completo.
	ld	de, 00h		; Si son iguales da resultado OK.
	ret	z		; Devuelve la función si lo ha encontrado.
	ld	a,(SubslotF)	; Si no hay tampoco FlashRom salta el mensaje de FlashROM no encontrado.
	and	03h		; Solo coge el valor PP de FxxxSSPP
	ld	de,(ERMSlt)	; Vuelca el contenido del valor leido
	cp	e		; Compara con "a"
	ld	a,(SubslotF)	; Vuelca el contenido encontrado del subslot completo.
	ld	de, 00h		; Si son iguales da resultado OK.
	ret	z		; Devuelve la función si lo ha encontrado.	
	ld	a,(SubslotG)	; Si no hay tampoco FlashRom salta el mensaje de FlashROM no encontrado.
	and	03h		; Solo coge el valor PP de FxxxSSPP
	ld	de,(ERMSlt)	; Vuelca el contenido del valor leido
	cp	e		; Compara con "a"
	ld	a,(SubslotG)	; Vuelca el contenido encontrado del subslot completo.
	ld	de, 00h		; Si son iguales da resultado OK.
	ret	z		; Devuelve la función si lo ha encontrado.
	ld	a,(SubslotH)	; Si no hay tampoco FlashRom salta el mensaje de FlashROM no encontrado.
	and	03h		; Solo coge el valor PP de FxxxSSPP
	ld	de,(ERMSlt)	; Vuelca el contenido del valor leido
	cp	e		; Compara con "a"
	ld	a,(SubslotH)	; Vuelca el contenido encontrado del subslot completo.
	ld	de, 00h		; Si son iguales da resultado OK.
	ret	z		; Devuelve la función si lo ha encontrado.
	ld	de,NO_FLSH	; Pointer to NO_FLSH message
	ret			; Jump Flash Rom not found

; ~~~ Fin de la rutina para chequear si la FlashROM está insertada en el parámetro /Sx



; --- Rutina para cargar la ROM de la FCB en el EMRSlt seleccionado.
PreFCB:	push	hl		; Guarda el puntero DMA de hl
	ld	bc,24		; Prepare the FCB
	ld	de,FCB+13
	ld	hl,FCB+12
	ld	(hl),b
	ldir			; Initialize the second half with zero

	ld	c,0fh
	ld	de,FCB
	call	BDOS		; Open file
	ld	hl,1
	ld	(FCB+14),hl	; Record size = 1 byte
	or	a
	ld	de,DosErr
	pop	hl
	ret	nz
	push	hl	

	ld	c,1ah
	ld	de,BUFTOP
	call	BDOS		; Set disk transfer address (buffer start at 8000H)

CargaROM:	
	di			; Desactiva interrupciones.
	; Esto solicita la petición de carga de archivo externo a la Flashjacks
	ld	a,(ERMSlt)
	ld	hl,04000h
	call	ENASLT		; Select Flashrom at bank 4000h~7FFFh

	ld	a,019h		; Carga en un posible FMPAC el modo recepción instrucciones EPROM.
	ld	(5FFEh),a
	ld	a,076h
	ld	(5FFFh),a
	
	ld	a,(4000h)	; Hace una lectura para tirar cualquier intento pasado de petición.

	ld	a,0aah
	ld	(4340h),a	; Petición acceso comandos FlashJacks. 
	ld	a,055h
	ld	(43FFh),a	; Autoselect acceso comandos FlashJacks. 
	ld	a,010h
	ld	(4340h),a	; Petición de carga externo de archivos.
	; Tipo mappers disponibles:
	; 00h y 7Fh  --  Instrucción ignorar carga externa.
	; 7Eh	     --  Carga externa con mapper AUTO (Lo selecciona FlashJacks con su autoanalisis)
	; 01h	     --  Carga externa con mapper KONAMI5
	; 02h	     --  Carga externa con mapper ASCII8K
	; 03h	     --  Carga externa con mapper KONAMI4
	; 04h	     --  Carga externa con mapper ASCII16K
	; 05h	     --  Carga externa con mapper SUNRISE IDE
	; 06h	     --  Carga externa con mapper SINFOX
	; 07h	     --  Carga externa con mapper ROM16K
	; 08h	     --  Carga externa con mapper ROM32K
	; 09h	     --  Carga externa con mapper ROM64K
	; 0Ah	     --  Carga externa con mapper RTYPE
	; 0Bh	     --  Carga externa con mapper ZEMINA6480
	; 0Ch	     --  Carga externa con mapper ZEMINA126
	; 0Dh	     --  Carga externa con mapper FMPAC
	;
	; Bit 7 del mapper:
	; 0	     --  Auto Expansor de Slots
	; 1	     --  Forzado Slot primario
	;
	;
	ld	a,(ForzaSlot)	; Comprueba la variable de forzado de Slot primario.
	cp	00h	
	jp	z, No_ForS	; Si es cero salta a no forzado.
	ld	a,(NumMapper)
	add	a,080h		; Si es 1, añade a "a" el bit 7 a 1
	jp	No_For2		; Salta continua carga.
No_ForS:ld	a,(NumMapper)
No_For2:ld	(4341h),a	; Inserto Mapper y petición de carga si no es 0.
	ld	hl,FCB+26	; Primer cluster (FCB26..27)
	ld	a, (hl)
	ld	(4342h),a	; Inserto parte alta Cluster.
	ld	hl,FCB+27	; Primer cluster (FCB26..27)
	ld	a, (hl)
	ld	(4343h),a	; Inserto parte baja Cluster.
	ld	hl,FCB+16	; Tamaño archivo (FCB16..19)
	ld	a, (hl)
	ld	(4344h),a	; Inserto parte alta 3 tamaño archivo.
	ld	hl,FCB+17	; Tamaño archivo (FCB16..19)
	ld	a, (hl)
	ld	(4345h),a	; Inserto parte alta 2 tamaño archivo.
	ld	hl,FCB+18	; Tamaño archivo (FCB16..19)
	ld	a, (hl)
	ld	(4346h),a	; Inserto parte alta 1 tamaño archivo.
	ld	hl,FCB+19	; Tamaño archivo (FCB16..19)
	ld	a, (hl)
	ld	(4347h),a	; Inserto parte baja tamaño archivo.
	ld	a,0ffh
	ld	(4348h),a	; Petición salida Autoselect.

	ld	a,000h		; Descarga en un posible FMPAC el modo recepción instrucciones EPROM.
	ld	(5FFEh),a
	ld	a,000h
	ld	(5FFFh),a
	
	; Fin de la petición de carga externa.
	; Recupera el mapeado de origen.
	ld	a,(RAMAD1)
	ld	hl,4000h
	call	ENASLT		; Select Main-RAM in MSX"s Bank 1
	ld	a,(RAMAD2)
	ld	hl,8000h
	call	ENASLT		; Select Main-RAM at bank 8000h~BFFFh
	ei			; Activa interrupciones.

	; Esto imprime la ROM subida y el Slot de carga.	
	ld	hl,FCB+1	; Puntero del texto de nombre de archivo
	ld	e,(hl)		; Lo carga en e (BDOS carácter)
	ld	c,2		; Solicita BDOS carácter.
	push	af		; Guarda registros. BDOS los modifica.
	push	hl
	call	BDOS		; Imprime el primer caracter Nombre de Archivo.
	pop	hl
	pop	af		; Recupera registros. BDOS los modifica.
	ld	a,0Ch		; Tamaño de archivo + extensión en acumulador.
	dec	a		; Resta 1 caracter en acumulador.
	inc	hl		; Incrementa en uno la dirección del texto a leer.
BText:	push	af		; Guarda acumulador.
	ld	e,(hl)		; Vuelca el contenido de la dirección FCB + x
	ld	a,e		; Lo transfiere al acumulador.
	cp	020h		; Lo compara con el espacio.
	jp	z,BPoint	; Si encuentra espacio, finaliza el volcado del resto de texto.
	pop	af		; Recupera acumulador.
	ld	e,(hl)		; Vuelca el contenido de la dirección FCB + x 
	ld	c,2		; Solicita BDOS carácter.
	push	af		; Guarda registros. BDOS los modifica.
	push	hl
	call	BDOS		; Imprime el primer caracter Nombre de Archivo.
	pop	hl		
	pop	af		; Recupera registros. BDOS los modifica.
	inc	hl		; Incrementa en uno la dirección del texto a leer.
	dec	a		; Resta 1 caracter en acumulador.
	cp	04h		; Compara si ha llegado al final del nombre.
	jp	nz, BText	; Si no ha llegado, ejecuta bucle.
	jp	BPointA		; Si ha llegado, ejecuta extensión.
BPoint: pop	af		; Retorno por espacio encontrado. Recupera acumulador.
BPointA:ld	a, 04h		; Fuerza puntero a extensión.
	ld	hl,FCB+8 	; Puntero del texto de ROM, extensión.
	ld	e, 02Eh		; Asigna el caracter "."
	ld	c,2		; Solicita BDOS carácter.
	push	af		; Guarda registros. BDOS los modifica.
	push	hl
	call	BDOS		; Imprime el primer caracter Nombre de Archivo.
	pop	hl
	pop	af		; Recupera registros. BDOS los modifica.
BText2:	dec	a		; Resta 1 caracter en acumulador.
	inc	hl		; Incrementa en uno la dirección del texto a leer.
	push	af		; Guarda acumulador.
	ld	e,(hl)		; Vuelca el contenido de la dirección FCB + x
	ld	a,e		; Lo transfiere al acumulador.
	cp	020h		; Lo compara con el espacio.
	jp	z,BPoint2	; Si encuentra espacio, finaliza el volcado del resto de texto.
	pop	af		; Recupera acumulador.
	ld	e,(hl)		; Vuelca el contenido de la dirección FCB + x 
	ld	c,2		; Solicita BDOS carácter.
	push	af		; Guarda registros. BDOS los modifica.
	push	hl
	call	BDOS		; Imprime el primer caracter Extensión de Archivo.
	pop	hl
	pop	af		; Recupera registros. BDOS los modifica.
	cp	00h		; Compara si ha llegado al final de la extensión.
	jp	nz, BText2	; Si no ha llegado, ejecuta bucle.
	jp	BPointB		; Si ha llegado, ejecuta comentario.
BPoint2:pop	af		; Retorno por espacio encontrado. Recupera acumulador.
BPointB:ld	de,Cargada	; Puntero del texto de comentario ROM cargada.
	ld	c,9
	call	BDOS		; Imprime el texto de comentario ROM cargada.

	ld	a,(ERMSlt)	; Recupera EMRSlt. Formato FxxxSSPP
	and	3		; Se queda solo con el número del Slot principal.
	add	a,30h		; Lo convierte a carácter.
	ld	e,a		; Lo transfiere a BDOS
	ld	c,2
	call	BDOS		; Imprime el número del Slot primario.
	
	ld	a,(ERMSlt)	; Recupera EMRSlt. Formato FxxxSSPP
	bit	7,a		; Compara si el subslot está activo.
	jr	z,FinSlot	; Salta si no hay subslot. 

	ld	a,(ForzaSlot)	; Recupera el forzado de Slot.
	cp	01h		; Mira si está activo.
	jp	z,FinSlot	; Si lo está, no imprime el subslot.

	ld	e,02Dh		; Vuelca el carácter guión.
	ld	c,2
	call	BDOS		; Imprime un guión por pantalla.

	ld	a,(ERMSlt)	; Recupera EMRSlt. Formato FxxxSSPP
	and	0Ch		; Se queda solo con el número del Subslot.
	srl	a		; Lo mueve a unidades.
	srl	a
	add	a,30h		; Lo convierte a carácter.
	ld	e,a		; Lo transfiere a BDOS
	ld	c,2
	call	BDOS		; Imprime el número del Subslot.	

FinSlot:ld	de,MESend1	; Vuelca carácter enter.
	ld	c,9
	call	BDOS		; Imprime un enter.

	; Esto imprime por pantalla el mapper seleccionado.
	ld	de,MapperSel	; Imprime texto Mapper seleccionado
	ld	c,9
	call	BDOS
	ld	a,(NumMapper)	; Vuelca el Nº de mapper seleccionado.
	cp	07Eh
	jp	nz,Map2
	ld	de,MapAuto	; Imprime texto Mapper seleccionado
	ld	c,9
	call	BDOS
	jp	FinMap
Map2:	ld	a,(NumMapper)	; Vuelca el Nº de mapper seleccionado.
	cp	01h
	jp	nz,Map3
	ld	de,MapKONAMI5	; Imprime texto Mapper seleccionado
	ld	c,9
	call	BDOS
	jp	FinMap
Map3:	ld	a,(NumMapper)	; Vuelca el Nº de mapper seleccionado.
	cp	02h
	jp	nz,Map4
	ld	de,MapASCII8K	; Imprime texto Mapper seleccionado
	ld	c,9
	call	BDOS
	jp	FinMap	
Map4:	ld	a,(NumMapper)	; Vuelca el Nº de mapper seleccionado.
	cp	03h
	jp	nz,Map5
	ld	de,MapKONAMI4	; Imprime texto Mapper seleccionado
	ld	c,9
	call	BDOS
	jp	FinMap
Map5:	ld	a,(NumMapper)	; Vuelca el Nº de mapper seleccionado.
	cp	04h
	jp	nz,Map6
	ld	de,MapASCII16K	; Imprime texto Mapper seleccionado
	ld	c,9
	call	BDOS
	jp	FinMap
Map6:	ld	a,(NumMapper)	; Vuelca el Nº de mapper seleccionado.
	cp	05h
	jp	nz,Map7
	ld	de,MapSUNRISE	; Imprime texto Mapper seleccionado
	ld	c,9
	call	BDOS
	jp	FinMap
Map7:	ld	a,(NumMapper)	; Vuelca el Nº de mapper seleccionado.
	cp	06h
	jp	nz,Map8
	ld	de,MapSINFOX	; Imprime texto Mapper seleccionado
	ld	c,9
	call	BDOS
	jp	FinMap
Map8:	ld	a,(NumMapper)	; Vuelca el Nº de mapper seleccionado.
	cp	07h
	jp	nz,Map9
	ld	de,MapROM16K	; Imprime texto Mapper seleccionado
	ld	c,9
	call	BDOS
	jp	FinMap
Map9:	ld	a,(NumMapper)	; Vuelca el Nº de mapper seleccionado.
	cp	08h
	jp	nz,Map10
	ld	de,MapROM32K	; Imprime texto Mapper seleccionado
	ld	c,9
	call	BDOS
	jp	FinMap
Map10:	ld	a,(NumMapper)	; Vuelca el Nº de mapper seleccionado.
	cp	09h
	jp	nz,Map11
	ld	de,MapROM64K	; Imprime texto Mapper seleccionado
	ld	c,9
	call	BDOS
	jp	FinMap
Map11:	ld	a,(NumMapper)	; Vuelca el Nº de mapper seleccionado.
	cp	0Ah
	jp	nz,Map12
	ld	de,MapRTYPE	; Imprime texto Mapper seleccionado
	ld	c,9
	call	BDOS
	jp	FinMap
Map12:	ld	a,(NumMapper)	; Vuelca el Nº de mapper seleccionado.
	cp	0Bh
	jp	nz,Map13
	ld	de,MapZEMINA6480; Imprime texto Mapper seleccionado
	ld	c,9
	call	BDOS
	jp	FinMap
Map13:	ld	a,(NumMapper)	; Vuelca el Nº de mapper seleccionado.
	cp	0Ch
	jp	nz,Map14
	ld	de,MapZEMINA126	; Imprime texto Mapper seleccionado
	ld	c,9
	call	BDOS
	jp	FinMap
Map14:	ld	a,(NumMapper)	; Vuelca el Nº de mapper seleccionado.
	cp	0Dh
	jp	nz,Map15
	ld	de,MapFMPAC	; Imprime texto Mapper seleccionado
	ld	c,9
	call	BDOS
	jp	FinMap
Map15:	ld	a,(NumMapper)	; Vuelca el Nº de mapper seleccionado.
	cp	0Eh
	jp	nz,Map16
	ld	de,MapCROSS	; Imprime texto Mapper seleccionado
	ld	c,9
	call	BDOS
	jp	FinMap
Map16:	ld	a,(NumMapper)	; Vuelca el Nº de mapper seleccionado.
	cp	0Fh
	jp	nz,FinMap
	ld	de,MapSLODE	; Imprime texto Mapper seleccionado
	ld	c,9
	call	BDOS
	jp	FinMap
FinMap:	
	; Fin imprime por pantalla el mapper seleccionado.

	jp	Ignora		; Con esto obviamos la rutina de imprimir el primer cluster encontrado por pantalla.
	; Esto imprime por pantalla el valor del primer cluster encontrado.
	push	hl
	push	de
	push	bc			; Guarda en la pila las variables.
	; Esto extrae el cluster del archivo encontrado.
	push	hl
	ld	hl,FCB+26		; Primer cluster (FCB26..27)
	ld	a, (hl)
	ld	(FirstCluster1),a	; Coge la dirección del primer cluster del archivo.Byte alto.
	inc	hl
	ld	a, (hl)
	ld	(FirstCluster2),a	; Coge la dirección del primer cluster del archivo.Byte bajo.
	pop	hl
	; Nos hace falta también el tamaño del archivo en bytes. Esto se obtiene del FCB+16..17..18..19
	ld	de,Priclus		; Imprime texto primer cluster del archivo.
	ld	c,9
	call	BDOS

	ld	a,(FirstCluster1)	; Enmascaramiento de las decenas
	and	0f0h	
	srl	a			; Rota a la derecha los 4 bits de la izquierda
	srl	a
	srl	a
	srl	a
	cp	0ah			; Compara si son números o letras.
	jp	NC, Num_salto1
	add	a,30h			; numeros decenas
	jp	Num_salto2
Num_salto1:	
	add	a,37h			; letras decenas
Num_salto2:
	ld	e,a			; Imprime las decenas
	ld	c,2
	call	BDOS
	ld	a,(FirstCluster1)	; Recarga el numero de nuevo.
	and	0fh			; Ahora enmascara las unidades.
	cp	0ah			; Compara si son números o letras.
	jp	NC, Num_salto3
	add	a,30h			; numeros unidades
	jp	Num_salto4
Num_salto3:	
	add	a,37h			; letras unidades
Num_salto4:
	ld	e,a			; Imprime las unidades
	ld	c,2
	call	BDOS	

	ld	e, 2Dh			; Imprime el Guion de separacion.
	ld	c,2
	call	BDOS	
	
	ld	a,(FirstCluster2)	; Enmascaramiento de las decenas
	and	0f0h
	srl	a			; Rota a la derecha los 4 bits de la izquierda
	srl	a
	srl	a
	srl	a 
	cp	0ah			; Compara si son números o letras.
	jp	NC, Num_salto5
	add	a,30h			; numeros decenas
	jp	Num_salto6
Num_salto5:	
	add	a,37h			; letras decenas
Num_salto6:
	ld	e,a			; Imprime las decenas
	ld	c,2
	call	BDOS
	ld	a,(FirstCluster2)	; Recarga el numero de nuevo.
	and	0fh			; Ahora enmascara las unidades.
	cp	0ah			; Compara si son números o letras.
	jp	NC, Num_salto7
	add	a,30h			; numeros unidades
	jp	Num_salto8
Num_salto7:	
	add	a,37h			; letras unidades
Num_salto8:
	ld	e,a			; Imprime las unidades
	ld	c,2
	call	BDOS	

	ld	e,CR			; Imprime un return
	ld	c,2
	call	BDOS			; Print CR character
	ld	e,LF
	ld	c,2
	call	BDOS			; Print LF character
	pop	bc
	pop	de
	pop	hl			; Devuelve las variables de la pila.
	; Fin imprime por pantalla el valor del primer cluster encontrado.
Ignora:
	ld	de,MESend1		; Return para espaciado.
	ld	c,9
	call	BDOS			; Print final message
	pop	hl			; devuelve hl DMA a su valor.
	ld	de,00h			; Marca que no ha habido fallos
	ret
; --- Fin de la subrutina para cargar la ROM de la FCB en el EMRSlt seleccionado.


; --- Subrutina de final correcto.

Fin_OK:	ei				; Activa interrupciones. Por si acaso se han quedado desactivadas.	
	ld	a,(RAMAD1)		; Esto devuelve los mappers del MSX en un estado lógico y estable.
	ld	hl,4000h
	call	ENASLT			; Select Main-RAM at bank 4000h~7FFFh
	ld	a,(RAMAD2)
	ld	hl,8000h
	call	ENASLT			; Select Main-RAM at bank 8000h~BFFFh
	ld	de,Recuerde		; Saca en pantalla el recordatorio de Reset y Power
	ld	c,9
	call	BDOS			; Print final message
	
ETecla:	xor	a			; Pone a cero el flag Z.
	ld	ix, CHSNS		; Petición de la rutina BIOS. En este caso CHSNS (Mirar buffer teclado).
	ld	iy,(MNROM)		; BIOS slot
        call	CALSLT			; Llamada al interslot. Es necesario hacerlo así en MSXDOS para llamadas a BIOS.
	jp	z, ETecla
	ld	a,(ResetOK)		; Recupera la marca de si soft reset o no.
	cp	01h			; Si hay petición de reset salta a la rutina de reset y sincronización con Flashjacks para su hardreset.
	jp	z,Reset			; Salto a reset si encuentra 01h.
	xor	a			; Pone a cero el flag Z.
	ld	ix, KILBUF		; Petición de la rutina BIOS. En este caso KILBUF (Borra el buffer del teclado).
	ld	iy,(MNROM)		; BIOS slot
        call	CALSLT			; Llamada al interslot. Es necesario hacerlo así en MSXDOS para llamadas a BIOS.
	rst	0			; Acaba el programa.

; --- Devolución al sistema operativo con error.
Done:	ei				; Activa interrupciones. Por si acaso se han quedado desactivadas.	
	push	de			; Guarda el error a imprimir.
	ld	a,(RAMAD1)		; Esto devuelve los mappers del MSX en un estado lógico y estable.
	ld	hl,4000h
	call	ENASLT			; Select Main-RAM at bank 4000h~7FFFh
	ld	a,(RAMAD2)
	ld	hl,8000h
	call	ENASLT			; Select Main-RAM at bank 8000h~BFFFh
	
	pop	de			; Recupera el error a imprimir
	ld	c,9
	call	BDOS			; Imprime el mensaje de error.
	rst	0
; Fin de la devolución del programa.

; --- Reset por soft de la Flashjacks sincronizado con el reset del z80.
Reset:	di			; Desactiva interrupciones.
	ld	a,(ERMSlt)	; Última petición a un subslot con FlashROM.
	ld	hl,04000h
	call	ENASLT		; Select Flashrom at bank 4000h~7FFFh
	
	ld	a,019h		; Carga en un posible FMPAC el modo recepción instrucciones EPROM.
	ld	(5FFEh),a
	ld	a,076h
	ld	(5FFFh),a

	ld	a,(4000h)	; Hace una lectura para tirar cualquier intento pasado de petición.
	
	ld	a,0aah
	ld	(4340h),a	; Petición acceso comandos FlashJacks. 
	ld	a,055h
	ld	(43FFh),a	; Autoselect acceso comandos FlashJacks. 
	ld	a,030h
	ld	(4340h),a	; Petición código de reset de FlashJacks

	ld	b,16
	ld	hl,4666h	; Al leer en este momento la dirección x666h fuerza el reset por hardware de la flashjacks.
	ld	a,(hl)		; Despues de aquí, el msx tiene exactamente 0,1Segundos hasta que la Flashjacks deje de responder y haga el cambio de hardware.
	;Reset MSX ultrarápido
	rst	030h
	db	0
	dw	0000h
; Fin del Reset por soft de la Flashjacks sincronizado con el reset del z80.

; Variables del programa.
ResetOK:
	db	0
Pasopor0:
	db	0
ForzaSlot:
	db	0
SubslotA:
	db	0
SubslotB:
	db	0
SubslotC:
	db	0
SubslotD:
	db	0
SubslotE:
	db	0
SubslotF:
	db	0
SubslotG:
	db	0
SubslotH:
	db	0
ERMSlt:
	db	0
RAMtyp:
	db	0
PreBnk:
	db	0
MAN_ID:
	db	0
DEV_ID:
	db	0
FileSize:
	db	0
FirstCluster1:
	db	0
FirstCluster2:
	db	0
ParameterR:
	db	0
NumMapper:
	db	0
Namefile:
	db	0,"           "
	;db	0,"NAMEFILEEXT"

; Fin del programa
end