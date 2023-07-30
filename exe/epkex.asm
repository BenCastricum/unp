; EPKEX.ASM
; last update : 5-May-1994

.code


EPKEX_entry:	ASSUME	ds:NOTHING, es:NOTHING	; assume nothing on entry
		mov	es,SegData
		ASSUME	es:DGROUP
		mov	ds,RegCS
		ASSUME	ds:NOTHING

		mov	si,RegIP
		mov	di,offset EPKEX_C1
		mov	cx,EPKEX_C1l
		repz	cmpsb
		jne	EPKEX_exit
		mov	si,offset EPKEX_ver
		call	WriteVersion

		mov	bx,04Ch
		mov	cx,0AEh
		mov	dx,0BFh
		mov	si,offset ACT_remencrypt
		inc	ExeSizeAdjust
		jmp	SetBreakpoints

EPKEX_exit:
		ret

.data
EPKEX_C1 label
		db	9Ch			; pushf
		db	50h			; push   ax
		db	8Ch,0DAh		; mov    dx,ds
		db	52h			; push   dx
		db	52h			; push   dx
		db	0BBh,0F0h,0FFh		; mov    bx,FFF0
		db	8Ch,0C8h		; mov    ax,cs
		db	48h			; dec    ax
		db	8Eh,0D8h		; mov    ds,ax
EPKEX_C1l 	equ	$ - offset EPKEX_C1

EPKEX_ver label
dw PACKEXE, _V1_0, 0
