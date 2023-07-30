; ECRPT.ASM
; last update : 5-May-1994

.code


ECRPT_entry:	ASSUME	ds:NOTHING, es:NOTHING	; assume nothing on entry
		mov	es,SegData
		ASSUME	es:DGROUP
		mov	ds,RegCS
		ASSUME	ds:NOTHING
		mov	si,RegIP
		lodsb
		cmp	al,0EBh
		jne	ECRPT_exit
		lodsb
		mov	ah,0
		add	si,ax

		mov	di,offset ECRPT_C1
		mov	cx,ECRPT_C1l
		repz	cmpsb
		jne	ECRPT_exit
		mov	si,offset ECRPT_ver
		call	WriteVersion

		mov	bx,0231h
		mov	cx,-1
		mov	dx,0260h
		mov	si,offset ACT_remencrypt
		mov	GetProgSize,offset GS_DSBX
		jmp	SetBreakpoints

ECRPT_exit:
		ret

.data
ECRPT_C1 label
		db	0FAh			; cli
		db	6			; push   es
		db	1Eh			; push   ds
		db	8Ch,0C8h		; mov    ax,cs
		db	2Eh,2Bh,6,8,0		; sub    ax,cs:[0008]
ECRPT_C1l 	equ	$ - offset ECRPT_C1

ECRPT_ver label
dw CRYPT, _V1_0, 0
