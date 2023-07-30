; CPKLT.ASM
; last update : 14-Sep-1993

.code
CPKLT_entry:	ASSUME	ds:NOTHING, es:NOTHING
		mov	es,SegData
		ASSUME	es:DGROUP
		mov	ds,RegCS
		mov	si,0274h
		mov	ax,02BBh
		mov	di,offset CPKLTs
		mov	cx,CPKLTl
		call	FindCode
		jc	CPKLT_exit
		mov	bx,si			; is pklite
		xor	cx,cx
		cmp	bx,0287h
		ja	CPKLT_identify

		mov	cl,ds:[012Ch]		; get version number
		add	bx,cx
CPKLT_identify:
		mov	ax,offset CPKLTiid
		call	cIndexedId
		sub	bx,cx
		mov	si,offset ACT_decomp
		jmp	HandleCom
CPKLT_exit:
		ret

.data
CPKLTs label
		mov	bx,0100h
		push	bx
CPKLTl		equ	$ - offset CPKLTs

CPKLTiid label
dw 02BBh    , PKLITE, _V1_00B , 0
dw 0288h+00h, PKLITE, _V1_00  , 0
dw 0288h+03h, PKLITE, _V1_03  , 0
dw 0287h+05h, PKLITE, _V1_05  , 0
dw 0287h+0Ch, PKLITE, _V1_12  , 0
dw 0287h+0Dh, PKLITE, _V1_13  , 0
dw 0287h+0Eh, PKLITE, _V1_14  , 0
dw 0289h    , PKLITE, _V1_15  , 0
dw 0298h    , PKLITE, _V1_50  , 0
dw 02E3h    , AVPACK, _V1_20  , 0
dw 0000h    , LB, PKLITE, RB  , 0