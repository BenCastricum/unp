; CDIET.ASM
; last update : 12-Okt-1993

.code
CDIET_entry:	ASSUME	ds:NOTHING, es:NOTHING
		mov	es,SegData
		ASSUME	es:DGROUP
		mov	ds,RegCS
		ASSUME	ds:NOTHING
		mov	si,0111h
		mov	di,offset CDIEThs
		mov	cx,CDIEThl
		repz	cmpsb
		jne	CDIET_C14		; diet 1.44 or higher

		mov	al,ds:[0100h]		; get first instruction

		mov	bl,1			; get values for 1.00d
		mov	di,ds:[0101h]
		mov	si,ds:[010Ch]
		mov	cx,ds:[0121h]
		add	cx,0123h
		cmp	al,0BFh
		je	CDIET_GotDiet

		mov	bl,3			; get values for 1.02b
		mov	di,ds:[0104h]
		mov	si,ds:[0101h]
		mov	cx,ds:[0121h]
		add	cx,0123h
		jmp	CDIET_GotDiet
CDIET_C14:
		mov	si,0130h
		mov	di,offset CDIETh2s
		mov	cx,CDIETh2l
		repz	cmpsb
		jne	CDIET_exit

		mov	bl,4			; values for 1.44 or 1.45f
		mov	si,ds:[0128h]
		mov	di,ds:[012Bh]
		mov	cx,ds:[013Fh]
		add	cx,0141h
CDIET_GotDiet:
		mov	ax,di			; where will be jumped too ?
		sub	ax,cx
		sub	si,ax

		cmp	byte ptr [si],0AAh	; bug ?
		jne	CDIET_Ident
		add	word ptr ds:[0121h],3	; fix bug
		dec	bl			; is V1.02b or V1.10a
CDIET_Ident:
		mov	di,offset CDIETs
		mov	cx,CDIETl
		lea	ax,[si+21]
		call	FindCode
		je	CDIET_go

		mov	di,offset CDIET2s	; end sig for 1.44 or 1.45f -G
		mov	cx,CDIET2l
		add	si,19
		lea	ax,[si+5]
		call	FindCode
		jne	CDIET_exit
		add	si,CDIET2l-CDIETl	; fix for add
		mov	bl,5
CDIET_go:
		mov	bh,0
		mov	ax,offset CDIET_iid
		call	cIndexedId
		lea	bx,[si+CDIETl]
		mov	si,offset ACT_decomp
		jmp	HandleCom

CDIET_exit:
		ret

.data
CDIEThs label
		std
		rep	movsw
		cld
		mov	si,di
		mov	di,0100h
		lodsw
		lodsw
		mov	bp,ax
		mov	dl,10h
CDIEThl		equ 	$ - offset CDIEThs

CDIETs label
		db	0E8h, 072h, 0FFh	; call 9400h
		db	072h, 0D6h		; jb   -..
		db	03Ah, 0FBh		; cmp  bh,bl
		db	075h, 0DDh		; jne  -..
CDIETl		equ	$ - offset CDIETs

CDIETh2s label
		std
		rep	movsw
		cld
		mov	si,di
		xor	di,di
		lodsw
		lodsw
		mov	bp,ax
		mov	dl,10h
CDIETh2l	equ 	$ - offset CDIETh2s

CDIET2s label
		db	0ADh			; lodsw
		db	08Bh, 0E8h		; mov	bp,ax
		db	0B2h, 010h		; mov	dl,10h
		db	072h, 0B3h		; jb	-..
		db	03Ah, 0FBh		; cmp   bh,bl
		db      075h, 0C2h		; jne   -..
CDIET2l		equ	$ - offset CDIET2s

CDIET_iid label
dw 01h, DIET, _V1_00, _or, _V1_00d      , 0
dw 02h, DIET, _V1_02b, _or, _V1_10a     , 0
dw 03h, DIET, _V1_20                    , 0
dw 04h, DIET, _V1_44, _or, _V1_45f      , 0
dw 05h, DIET, _V1_44, _or, _V1_45f, __G , 0
dw 00h, LB, DIET, RB,0