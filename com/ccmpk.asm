; CCMPK.ASM
; last update : 20-Sep-1993

.code
CCMPK_entry:	ASSUME	ds:NOTHING, es:NOTHING
		mov	es,SegData
		ASSUME	es:DGROUP
		mov	ds,RegCS
		ASSUME	ds:NOTHING
		mov	si,0100h
		lodsb
		cmp	al,0BEh			; mov si,XXXX ?
		jne	CCMPK_exit
		lodsw				; get si value
		mov	di,offset CCMPK44s
		mov	si,0114h
		mov	cx,CCMPK44l
		repz	cmpsb
		jne	CCMPK_check45
		add	ax,0142h - 10h		; start value - 10h
		mov	bl,ds:[0106h]
		and	bx,2
		xor	bl,2
		add	bx,44h
CCMPK_go:
		push	ax
		mov	ax,offset CCMPK_iid
		call	cIndexedId
		pop	bx
		mov	si,offset ACT_decomp
		jmp	HandleCom

CCMPK_check45:
		mov	si,0118h		; same sig as V4.4
		mov	di,offset CCMPK44s
		mov	cx,CCMPK44l
		repz	cmpsb
		jne	CCMPK_exit
		add	ax,0137h
		mov	bx,45h
		jmp	CCMPK_go

CCMPK_exit:
		ret

.data
CCMPK44s label
		mov	di,0FF82h
		shr	cx,1
		std
		push	di
		rep	movsw
		lea	si,[di+02]
		cld
		stc
CCMPK44l	equ 	$ - offset CCMPK44s

CCMPK_iid label
dw 44h, COMPACK, _V4_4          , 0
dw 45h, COMPACK, _V4_5          , 0
dw 46h, IMPLODER, _V1_0, _Alpha , 0
dw  0h, LB, COMPACK, RB, 0