; ECOM2.ASM
; last update	: 15-MAY-1993

.code
ECOM2_entry:	ASSUME	ds:NOTHING, es:NOTHING
		mov	es,SegData
		ASSUME	es:DGROUP
		mov	ds,RegCS
		ASSUME	ds:NOTHING
		mov	si,RegIP
		mov	di,offset ECOM2s
		mov	cx,ECOM2sl
		repz	cmpsb
		jne	ECOM2_exit

		mov	si,offset ECOM2_ver
		call	WriteVersion
		mov	GetProgSize,offset GS_CS00
		mov	bx,RegIP
		mov	cx,0188h
		mov	dx,01ABh
		mov	si,offset ACT_remencrypt
		jmp	SetBreakpoints

ECOM2_exit:
		ret


.data
ECOM2_ver label word
dw COMPRESSOR, _V1_1, 0

ECOM2s label
		db	1Eh			; push   ds
		db	0Eh			; push   cs
		db	0Eh			; push   cs
		db	1Fh			; pop    ds
		db	07h			; pop    es
		db	0E8h,0E1h,0		; call   00E9
		db	58h			; pop    ax
		db	2Eh,89h,86h,0CDh,1	; mov    cs:[bp+01CD],ax
ECOM2sl	        equ	$ - ECOM2s

