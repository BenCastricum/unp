; /**/
; /*
;    filename    : ECMPR.ASM
;    created by  : Ben Castricum
;    created on  : ?
;    handles     : Unknown compresser
;    last update : 21-Sep-1993
;    status      : completed
;    comments    : This routine was found on TCCOLOUR.COM V2.02, a
;		     colour editor for a program named Turbo Copy.
;									   */
;									 /**/

.code
CCMPR_entry:	ASSUME	ds:NOTHING, es:NOTHING
		mov	es,SegData
		ASSUME	es:DGROUP
		mov	ds,RegCS
		ASSUME	ds:NOTHING

		mov	si,0100h
		lodsb
		cmp	al,0EBh
		jne	CCMPR_exit
		lodsb
		mov	ah,0
		add	si,ax
		mov	di,offset CCMPRs
		mov	cx,CCMPRl
		repz	cmpsb
		jne	CCMPR_exit

		mov	si,offset CCMPR_ver
		call	WriteVersion
		mov	bx,01AFh
		mov	si,offset ACT_decomp
		jmp	HandleCom
CCMPR_exit:
		ret

.data
CCMPRs label
		mov	ax,cs
		dec	ax
		mov	es,ax
		db	26h, 81h, 3Eh, 03h, 00h	; cmp es:word ptr [0003],3100
CCMPRl  		equ	$ - offset CCMPRs

CCMPR_ver label
dw LB, COMPRESSOR, _V1_00,  RB, 0