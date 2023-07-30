; EDELT.ASM
; last update : 5-May-1994

.code


EDELT_entry:	ASSUME	ds:NOTHING, es:NOTHING	; assume nothing on entry
		mov	es,SegData
		ASSUME	es:DGROUP
		mov	ds,RegCS
		ASSUME	ds:NOTHING

		mov	si,RegIP
		mov	di,offset EDELT_C1
		mov	cx,EDELT_C1l
		repz	cmpsb
		jne	EDELT_exit
		mov	si,offset EDELT_ver
		call	WriteVersion

		mov	bx,034h
		mov	cx,059h
		mov	dx,068h
		mov	si,offset ACT_remencrypt
		mov	GetProgSize,offset GS_DSSI
		jmp	SetBreakpoints

EDELT_exit:
		ret

.data
EDELT_C1 label
		db	0FAh			; cli
		db	8Ch,0D8h		; mov    ax,ds
		db	5,10h,0			; add    ax,0010
		db	8Eh,0D8h		; mov    ds,ax
		db	0B9h			; mov    cx,
EDELT_C1l 	equ	$ - offset EDELT_C1

EDELT_ver label
dw DELTAPACKER, _V0_1, 0
