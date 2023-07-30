; EZIVP.ASM ; currently NOT used!
; last update : 28-AUG-1994

.code
EZIVP_entry:	ASSUME	ds:NOTHING, es:NOTHING
		mov	es,SegData
		ASSUME	es:DGROUP
		mov	ds,RegCS
		ASSUME	ds:NOTHING
		mov	si,RegIP
		lodsb
		cmp	al,0EBh
		jne	EZIVP_exit
		lodsb
		mov	ah,0
		add	si,ax
		mov	di,offset EZIVP1s
		mov	cx,EZIVP1l
		repz	cmpsb
		jne	EZIVP_exit

		mov	si,offset EZIVPver
		call	WriteVersion

		mov	bx,032Ah
		mov	cx,0350h
		mov	dx,03E1h

		mov	si,offset ACT_remencrypt
		mov	ExpectedInts,offset EZIVP_ints
		inc	SwitchLforced
		jmp	SetBreakpoints

EZIVP_exit:
		ret

.data
EZIVP_ints	db	2Fh			; Get DTA
		db	0

EZIVP1s label
		db	0BCh,7Eh,0		; mov    sp,007E
		db	0Eh			; push   cs
		db	1Fh			; pop    ds
		db	0BEh,0ECh,3		; mov    si,03EC
		db	0B0h,4Dh		; mov    al,4D
		db	0B4h,5Ah		; mov    ah,5A
		db	46h			; inc    si
		db	39h,4			; cmp    [si],ax
		db	75h,0FBh		; jne    012F
EZIVP1l		equ	$ - offset EZIVP1s


EZIVPver label
dw ZIVPACK, 0