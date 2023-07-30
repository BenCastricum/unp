; CU173.ASM
; last update : 21-Mar-1994

.code
CU173_entry:	ASSUME	ds:NOTHING, es:NOTHING
		mov	es,SegData
		ASSUME	es:DGROUP
		mov	ds,RegCS
		ASSUME	ds:NOTHING
		mov	si,11Dh
		mov	ax,123h
		mov	di,offset CU173s
		mov	cx,CU173l
		call	FindCode
		jne	CU173_check2
		add	si,CU173l
		mov	ax,offset CU173ver
		mov	bx,1
		call	cIndexedId
		mov	bx,si
		mov	si,offset ACT_remencrypt
		jmp	HandleCom

CU173_check2:
		mov	si,120h
		mov	ax,126h
		mov	di,offset CU173s2
		mov	cx,CU173l2
		call	FindCode
		jne	CU173_exit
		cmp	si,0120h
		je	CU173_3
		mov	ax,offset CU173ver
		mov	bx,2
		call	cIndexedId
		mov	bx,014Eh
		call	Break
		mov	ax,RegDI
		mov	ProgFinalOfs,ax
		dec	ProgFinalSeg
		mov	bx,0FEB0h
		mov	si,offset ACT_remencrypt
		jmp	HandleCom

CU173_3:
		mov	ax,offset CU173ver
		mov	bx,3
		call	cIndexedId
		mov	bx,0145h
		call	Break
		mov	ax,RegDI
		mov	ProgFinalOfs,ax
		dec	ProgFinalSeg
		mov	bx,0FEB0h
		mov	si,offset ACT_remencrypt
		jmp	HandleCom

CU173_exit:
		ret

.data
CU173s label
		db	0BFh,0,1		; mov    di,0100
		db	0ACh			; lodsb
		db	3,0D0h			; add    dx,ax
		db	4,0ADh			; add    al,AD
		db	0D0h,0C0h		; rol    al,1
		db	0D0h,0C0h		; rol    al,1
		db	2Ch,0ADh		; sub    al,AD
		db	0AAh			; stosb
		db	0E2h,0F2h		; loop   -14
CU173l		equ	$ - offset CU173s

CU173s2 label
		db	0BFh,0,1		; mov    di,0100
		db	0ACh			; lodsb
		db	3,0D0h			; add    dx,ax
		db	32h,0C3h		; xor    al,bl
		db	4,0ADh			; add    al,AD
		db	0D0h,0C0h		; rol    al,1
		db	0D0h,0C0h		; rol    al,1
		db	2Ch,0ADh		; sub    al,AD
		db	8Ah,0D8h		; mov    bl,al
		db	0AAh			; stosb
		db	0E2h			; loop   ....
CU173l2		equ	$ - offset CU173s2


CU173ver label
dw  1h,	LB, UNIT_173_, SCRAMBLER, _V1_00, RB, 0
dw  2h,	LB, UNIT_173_, SCRAMBLER, _V1_01, RB, 0
dw  3h,	LB, UNIT_173_, SCRAMBLER, _V1_02, RB, 0
dw  0,	LB, UNIT_173_, SCRAMBLER, RB, 0
