; CCRCM.ASM
; last update : 19-Apr-1994
;
; 19-Apr-1994: skipped first near jump (E9h)

.code
CCRCM_entry:	ASSUME	ds:NOTHING,es:DGROUP
		mov	ax,RegIP
		mov	si,ax
		add	si,9015h-9000h
		mov	di,offset CCRCM1s
		mov	cx,CCRCM1l
		repz	cmpsb
		jne	CCRCM_2
		mov	bx,si
		dec	bx
		mov	si,offset CCRCMver
		call	WriteVersion
		mov	si,offset ACT_remencrypt
		jmp	HandleCom

CCRCM_2:
		mov	si,ax
		add	si,9013h-9000h
		mov	di,offset CCRCM2s
		mov	cx,CCRCM2l
		repz	cmpsb
		jne	CCRCM_exit
		mov	RegDI,ax
		lea	bx,[si-1]
		mov	si,offset CCRCMver
		call	WriteVersion
		mov	si,offset ACT_remencrypt
		jmp	HandleCom

CCRCM_exit:
		ret

.data
CCRCM1s label
		ror	ax,1
		stosw
		db	0E2h,0F7h		; loop 9011
		ret
CCRCM1l		equ	$ - offset CCRCM1s

CCRCM2s label
		inc	si
		inc	si
		db	0E2h, 0F8h		; loop 900F
		db	031h, 0F6h		; xor  si,si
		db	031h, 0C9h		; xor  cx,cx
		ret
CCRCM2l		equ	$ - offset CCRCM2s

CCRCMver label
dw CRYPTCOM, 0