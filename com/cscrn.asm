; CSCRN.ASM
; last update : 21-Sep-1993

.code
CSCRN_entry:	ASSUME	ds:NOTHING, es:NOTHING
		mov	es,SegData
		ASSUME	es:DGROUP
		mov	ds,RegCS
		ASSUME	ds:NOTHING

		mov	di,offset CSCRNs
		mov	si,0260h
		mov	ax,0291h
		mov	cx,CSCRNl
		call	FindCode
		jne	CSCRN_exit
		mov	bx,si
		mov	ax,offset CSCRN_iid
		call	cIndexedId
		mov	ExpectedInts,offset CSCRN_ints
		mov	si,offset ACT_decomp
		push	ds
		mov	ds,SegProgPSP
		mov	byte ptr ds:[0080h],1	; to avoid helpscreen
		pop	ds
		jmp	HandleCom
CSCRN_exit:
		ret

.data
CSCRNs label
		db	0B4h,0			; mov    ah,00
		db	0ACh			; lodsb
		db	3,0D0h			; add    dx,ax
		db	0E2h,0FBh		; loop   0209
		db	81h,0EAh		; sub    dx,
CSCRNl    	equ	$ - offset CSCRNs

CSCRN_ints	db	4Ah, 0

CSCRN_iid label
dw 0260h, SCRNCH, _V1_00, 0
dw 0291h, SCRNCH, _V1_02, 0
dw    0h, LB, SCRNCH, RB, 0
