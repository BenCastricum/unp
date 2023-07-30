; CPPCK.ASM
; last update : 25-Sep-1993

.code
CPPCK_entry:	ASSUME	ds:NOTHING, es:NOTHING
		mov	es,SegData
		ASSUME	es:DGROUP
		mov	ds,RegCS
		ASSUME	ds:NOTHING

		mov	di,offset CPPCKs
		mov	cx,CPPCKl
		mov	si,01EEh
		mov	ax,0275h
		call	FindCode
		jc	CPPCK_exit
		cmp	byte ptr ds:[si-3],0E8h
		jne	CPPCK_go
		sub	si,3
CPPCK_go:
		mov	bx,si
		mov	ax,offset CPPCK_iid
		call	cIndexedId
		mov	si,offset ACT_decomp
		jmp	HandleCom

CPPCK_exit:
		ret

.data
CPPCK_iid label
dw 01EEh, PRO_PACK, _V2_08, _or, _V2_14, __m1            , 0
dw 01FCh, PRO_PACK, _V2_08, _or, _V2_14, __m1, __k       , 0
dw 0206h, PRO_PACK, _V2_08, _or, _V2_14, __m1, __v       , 0
dw 0214h, PRO_PACK, _V2_08, _or, _V2_14, __m1, __k, __v  , 0
dw 0241h, PRO_PACK, _V2_08, _or, _V2_14, __m2            , 0
dw 0265h, PRO_PACK, _V2_08, _or, _V2_14, __m2, __k       , 0
dw 0250h, PRO_PACK, _V2_08, _or, _V2_14, __m2, __v       , 0
dw 0272h, PRO_PACK, _V2_08, _or, _V2_14, __m2, __k, __v  , 0
dw    0h, LB, PRO_PACK, RB              , 0

CPPCKs label
		xor	ax,ax
		jmp	si
CPPCKl		equ	$ - offset CPPCKs
