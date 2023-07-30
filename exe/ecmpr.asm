; /**/
; /*
;    filename    : ECMPR.ASM
;    created by  : Ben Castricum
;    created on  : ?
;    handles     : Unknown compresser
;    last update : 15-May-1993
;    status      : completed
;    comments    : I lost the program compressed with this :( .
;									   */
;									 /**/

.code
ECMPR_entry:	ASSUME	ds:NOTHING, es:NOTHING
		mov	es,SegData
		ASSUME	es:DGROUP
		mov	ds,RegCS
		ASSUME	ds:NOTHING
		mov	si,RegIP
		lodsb
		cmp	al,0E9h
		jne	ECMPR_exit
		lodsw
		add	si,ax
		mov	di,offset ECMPRs
		mov	cx,ECMPRsl
		repz	cmpsb
		jne	ECMPR_exit

		inc	SwitchRforced		; do not copy overlay
		mov	si,offset ECMPR_ver
		call	WriteVersion
		mov	ExpectedInts,offset ECMPR_ints

		mov	GetProgSize,offset ECMPR_GS
		mov	bx,01C7h
		mov	cx,0227h
		mov	dx,0265h

		mov	si,offset ACT_decomp
		jmp	SetBreakpoints

ECMPR_exit:
		ret


ECMPR_GS:	ASSUME	ds:DGROUP, es:NOTHING
		mov	ax,RegDI
		mov	ProgFinalOfs,ax
		push	ds
		mov	ax,RegCS
		mov	ds,ax
		mov	ax,ds:[049Ch]
		pop	ds
		mov	ProgFinalSeg,ax
		ret

.data
ECMPR_ver label word
dw LB, COMPRESSOR, _V1_01, RB, 0


ECMPR_ints label
;		db	1Ah			; Set DTA
		db	30h			; get dos version
		db	3Dh			; open file
		db	42h			; move file pointer
		db	3Eh			; close file
		db	3Fh			; read from file
		db	0

ECMPRs label
		db	0Eh			; push   cs
		db	1Fh			; pop    ds
		db	0A3h,98h,4		; mov    [0498],ax
		db	8Ch,1Eh,9Eh,4		; mov    [049E],ds
		db	8Ch,1Eh,9Ch,4		; mov    [049C],ds
ECMPRsl	        equ	$ - ECMPRs

