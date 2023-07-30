; EEPW.ASM
; removes     : EPW V1.20
; created on  : 24-Nov-1994
; last update : 19-Apr-1994

.code
EEPW_entry:	ASSUME	ds:NOTHING, es:NOTHING
		mov	es,SegData
		ASSUME	es:DGROUP
		mov	ds,RegCS
		ASSUME	ds:NOTHING

		mov	si,RegIP
		push	si
		mov	di,offset EEPWs
		mov	cx,EEPWl
		repz	cmpsb
		pop	bx
		jne	EEPW_exit
		lodsw
;		cmp	ax,0C083h		; V1.30 ?
;		je	EEPW130
;		cmp	ax,1005h		; V1.2 ?
;		jne	EEPW_exit
		mov	si,offset EEPW_ver12
		call	WriteVersion
		call	AskPassword
		mov	ds:[01B8h],9090h 	; disable int 21
		mov	ds:[01C3h],9090h 	; disable int 10
		mov	ds:[01CAh],9090h 	; disable int 21
		mov	ds:[01D1h],9090h 	; disable int 21
		mov	di,20h
		mov	cl,ds:[di]		; get maximum pwd length
		mov	ch,0
		inc	di
		push	di
		inc	di
		xor	si,si
EEPW_CopyPswd:
		mov	al,Password[si]
		inc	si
		or	al,al			; end of password?
		je	EEPW_SetBuffer
		mov	ds:[di],al
		inc	di
		loop	EEPW_CopyPswd
EEPW_SetBuffer:
		mov	byte ptr ds:[di],0Dh
		mov	al,10h
		sub	al,cl
		pop	di
		mov	ds:[di],al
		mov	ax,offset ACT_rempassword
		mov	bx,0331h
		mov	cx,02CFh
		mov	dx,0345h
		jmp	SetBreakpoints

comment /*
EEPW130:
		mov	si,offset EEPW_ver130
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
*/

EEPW_exit:
		ret

.data
EEPWs label
		push	es
		push	di
		push	ds
		push	si
		push	bp
		push	dx
		push	cx
		push	bx
		push	ax
		db	2Eh,8Ch,6,8,0		; mov    cs:[0008],es
		db	8Ch,0C0h		; mov    ax,es
		db	5,10h,0			; add    ax,0010
		db	2Eh,0A3h,0Ah,0		; mov    cs:[000A],ax
EEPWl		equ	$ - offset EEPWs

EEPW_ver130	dw	EPW, _V1_30, 0
EEPW_ver12	dw	EPW, _V1_2, _or, _V1_21, 0
