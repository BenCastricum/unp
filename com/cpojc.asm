; CPOJC.ASM
; last update : 19-Apr-1994
;
; 19-Apr-1994: skipped first near jump (E9h)

.code
CPOJC_entry:	ASSUME	ds:NOTHING,es:DGROUP
		mov	si,RegIP
		add	si,9011h-9005h
		mov	ax,si
		mov	di,offset CPOJC2s
		mov	cx,CPOJC2l
		repz	cmpsb
		jne	CPOJC_exit

		mov	bx,ax			; restore code
		sub	bx,0Fh
		sub	ax,11h
		mov	RegDI,ax
		mov	ax,[bx]
		mov	ds:[0100h],ax
		mov	al,[bx+2]
		mov	ds:[0102h],al
		mov	bx,RegIP
		mov	si,offset CPOJCver
		call	WriteVersion
		mov	si,offset ACT_remencrypt
		jmp	HandleCom

CPOJC_exit:
		ret

.data
CPOJC2s label
		mov	si,di
		mov	dx,cx
		cld
		lodsw
		rol	dx,1
		xor	dx,ax
CPOJC2l		equ	$ - offset CPOJC2s

CPOJCver label
dw POJCOM, _V1_0, 0