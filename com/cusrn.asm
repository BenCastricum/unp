; CUSRN.ASM
; last update : 19-Apr-1994

.code
CUSRN_entry:	ASSUME	ds:NOTHING,es:DGROUP
		mov	si,RegIP
		mov	bx,si
		add	si,3
		mov	di,offset CUSRN1s
		mov	cx,CUSRN1l
		repz	cmpsb
		jne	CUSRN_check210
		push	bx
		mov	bx,1
		mov	ax,offset CUSRNver
		call	cIndexedId
		pop	bx
		mov	ProgFinalOfs,bx
		dec	ProgFinalSeg
		mov	RegBP,bx
		add	bx,140h
		mov	RegIP,bx
		add	bx,0Eh
		mov	si,offset ACT_rempassword
		jmp	HandleCom

CUSRN_check210:
		mov	si,RegIP
		mov	bx,si
		lodsb
		cmp	al,0BDh
		jne	CUSRN_check300
		lodsw
		lodsb
		cmp	al,0EBh
		jne	CUSRN_exit
		lodsb
		xor	ah,ah
		add	si,ax
		mov	di,offset CUSRN2s
		mov	cx,CUSRN2l
		repz	cmpsb
		jne	CUSRN_exit
		push	bx
		mov	bx,2
		mov	ax,offset CUSRNver
		call	cIndexedId
		pop	bx
		mov	ProgFinalOfs,bx
		dec	ProgFinalSeg
		add	bx,017Ch
		mov	ax,[bx]
		sub	ax,0103h
		mov	ds:[0101h],ax
		mov	si,offset ACT_rempassword
		mov	bx,RegIP
		jmp	HandleCom

CUSRN_check300:
		mov	si,RegIP
		mov	di,offset CUSRN3s
		mov	cx,CUSRN3l
		repz	cmpsb
		jne	CUSRN_exit
		push	bx
		mov	bx,3
		mov	ax,offset CUSRNver
		call	cIndexedId
		pop	bx
		mov	ProgFinalOfs,bx
		dec	ProgFinalSeg
		mov	RegBP,bx
		add	bx,44h
		mov	RegIP,bx
		add	bx,4Fh-44h
		call	Break
		add	bx,2
		call	Break
		add	bx,14Bh-51h
		mov	RegIP,bx
		add	bx,0159h-014Bh
		mov	si,offset ACT_rempassword
		jmp	HandleCom



CUSRN_exit:
		ret

.data
CUSRN1s label
		db	33h,0C0h		; xor    ax,ax
		db	8Eh,0D8h		; mov    ds,ax
		db	0FCh			; cld
		db	33h,0F6h		; xor    si,si
		db	0BFh,8Eh,1		; mov    di,018E
		db	3,0FDh			; add    di,bp
		db	0B9h,14h,0		; mov    cx,0014
		db	0F3h,0A4h		; rep movsb
		db	0FAh			; cli
		db	0A1h,84h,0		; mov    ax,[0084]
CUSRN1l		equ	$ - offset CUSRN1s

CUSRN2s label
		db	0Eh			; push   cs
		db	1Fh			; pop    ds
		db	0B4h,0Fh           	; mov    ah,0F
		db	0CDh,10h		; int    10
		db	0B4h,0           	; mov    ah,00
		db	0CDh,10h		; int    10
		db	8Dh,6,44h,1		; lea    ax,[0144]
		db	8Dh,1Eh,0,1		; lea    bx,[0100]
CUSRN2l		equ	$ - offset CUSRN2s

CUSRN3s label
		db	0E8h,0,0		; call   9003
		db	5Dh			; pop    bp
		db	83h,0EDh,3        	; sub    bp,0003
		db	0FAh			; cli
		db	0FCh			; cld
		db	33h,0F6h		; xor    si,si
		db	8Eh,0DEh	        ; mov    ds,si
		db	0BFh,99h,1        	; mov    di,0199
		db	3,0FDh          	; add    di,bp
		db      0B9h,14h,0        	; mov    cx,0014
		db	0F3h,0A4h		; rep movsb
		db	8Bh,0FCh          	; mov    di,sp
CUSRN3l		equ	$ - offset CUSRN3s


CUSRNver label
dw 1, USERNAME, _V2_00, 0
dw 2, USERNAME, _V2_10, 0
dw 3, USERNAME, _V3_00, 0