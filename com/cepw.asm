; CEPW.ASM
; last update : 19-Apr-1994
;
; 20-Mar-1994: changed code to take advantage of final size overide code
; 19-Apr-1994: skipped first near jump (E9h)

.code
CEPW_entry:	ASSUME	ds:NOTHING, es:DGROUP
		mov	si,RegIP
		push	si
		mov	di,offset CEPWs
		mov	cx,CEPWl
		repz	cmpsb
		pop	bx
		jne	CEPW_exit
		lodsw
		cmp	ax,0C083h		; V1.30 ?
		je	CEPW130
		cmp	ax,1005h		; V1.2 ?
		jne	CEPW_exit
		mov	si,offset CEPW_ver12
		call	WriteVersion
		call	AskPassword
		lea	ax,[bx-123h]
		mov	ProgFinalOfs,ax
		mov	ProgFinalSeg,ds
		mov	ds:[bx+9162h-9123h],9090h ; disable int 21
		mov	ds:[bx+916Dh-9123h],9090h ; disable int 10
		mov	ds:[bx+9174h-9123h],9090h ; disable int 21
		mov	ds:[bx+917Bh-9123h],9090h ; disable int 21
		lea	di,[bx+905Eh-9123h]
		mov	cl,ds:[di]		; get maximum pwd length
		mov	ch,0
		inc	di
		push	di
		inc	di
		xor	si,si
CopyPswd:
		mov	al,Password[si]
		inc	si
		or	al,al			; end of password?
		je	SetupBuffer
		mov	ds:[di],al
		inc	di
		loop	CopyPswd
SetupBuffer:
		mov	byte ptr ds:[di],0Dh
		mov	al,10h
		sub	al,cl
		pop	di
		mov	ds:[di],al
		add	bx,9207h-9123h
		mov	si,offset ACT_rempassword
		jmp	HandleCom

CEPW130:
		mov	si,offset CEPW_ver130
		call	WriteVersion
		call	AskPassword
		mov	ds:[bx+9140h-9101h],9090h ; disable int 21
		mov	ds:[bx+915Eh-9101h],9090h ; disable int 21
		add	bx,914Ah-9101h
		mov	si,offset Password
PassChar:
		call	Break
		add	RegIP,2			; skip int16
		mov	al,es:[si]
		inc	si			; read char from password
		mov	byte ptr RegAX,al
		cmp	al,0			; end of password ?
		jne	PassChar
		mov	byte ptr RegAX,0Dh
		add	bx,91E8h-914Ah
		mov	ax,RegDI
		dec	ProgFinalSeg
		mov	ProgFinalOfs,ax
		mov	si,offset ACT_rempassword
		jmp	HandleCom

CEPW_exit:
		ret

.data
CEPWs label
		push	es
		push	di
		push	ds
		push	si
		push	bp
		push	dx
		push	cx
		push	bx
		push	ax
		mov	bx,0003h
		add	bx,0100h
		mov	ax,cs:[bx]
		mov	bx,cs
		add	ax,bx
CEPWl		equ	$ - offset CEPWs

CEPW_ver130	dw	EPW, _V1_30, 0
CEPW_ver12	dw	EPW, _V1_2, _or, _V1_21, 0
