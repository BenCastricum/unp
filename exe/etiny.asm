; /*
; last update	: 10-May-1994
; compressor(s) : TINYPROG V1.0, V3.0, V3.3, V3.6, V3.8, V3.9
;
;  GS  : pop	dx
;      : db	08Eh, 0DAh 			; mov es,dx
;  GI  : add	es:[di-0202h],bp
;  GI2 : add	es:[bx],cx
;  QT  : mov	ds,bx
;	 xor	bx,bx
;	 sti
;	 jmp	dword ptr cs:[000Ch]
; */

.code
ETINY_entry:	ASSUME	ds:NOTHING, es:NOTHING
		mov	es,SegData
		ASSUME	es:DGROUP
		mov	ds,RegCS
		ASSUME	ds:NOTHING
		mov	si,RegIP
		lodsb
		cmp	al,0E9h			; initial jump?
		jne	ETINY_exit
		lodsw
		add	si,ax
		lodsb
		cmp	al,0EBh
		jne	ETINY_exit
		cmp	[si+009Ch],7300h
		jne	ETINY_2EndInit
		mov	ax,[si+009Ah]
		cmp	ax,96E8h		; check if password protected
		je	ETINY_isPswd
		cmp	ax,95E8h
		jne	ETINY_2EndInit
ETINY_isPswd:
		push	si			; ask for password
		push	ds
		push	es
		call	AskPassword
		mov	ds,SegData
		mov	es,SegProgPSP
		mov	si,offset Password
		mov	di,81h
		mov	cx,7Eh
ETINY_CopyPsw:
		lodsb
		cmp	al,0
		je	ETINY_GotPsw
		stosb
		loop	ETINY_CopyPsw
ETINY_GotPsw:
		mov	al,0Dh
		stosb
		mov	ax,di
		sub	ax,82h
		mov	es:[80h],al

		pop	es
		pop	ds
		pop	si
ETINY_2EndInit:
		mov	ax,si
		add	si,097h
		add	ax,0FFh
		mov	di,offset TinyJumpS
		mov	cx,TinyJumpSSz
		call	FindCode
		jne	ETINY_exit
		mov	bx,si
		call	Break
		call	Trace			; do jmp far [si+X]
		mov	ds,RegCS
		mov	si,00FCh
		mov	ax,018Ch
		mov	di,offset ETinyGSSig
		mov	cx,ETinyGSSz
		call	FindCode
		jne	ETINY_exit
		cmp	byte ptr [si-3],0E8h	; call to reset int vectors?
		jne	ETINY_GetGI		; (V3.9)
		sub	si,3			; GS before call
ETINY_GetGI:
		mov	bp,si

		mov	si,0162h
		mov	ax,0162h
		mov	di,offset ETinyGISig
		mov	cx,ETinyGISSz
		call	FindCode		; V1.0 only
		je	ETINY_GetQT

ETINY_GetGI2:
		mov	si,00EEh
		mov	ax,00F3h
		mov	di,offset GI_ESBXCX
		mov	cx,GI_ESBXCXSz
		call	FindCode
		je	ETINY_GetQT

ETINY_GetGI3:
		mov	si,00FDh
		mov	ax,00FDh
		mov	di,offset GI_ESBXAX
		mov	cx,GI_ESBXAXSz
		call	FindCode
		je	ETINY_GetQT

ETINY_GetGI4:
		mov	si,0100h
		mov	ax,0100h
		mov	di,offset GI_BXCX
		mov	cx,GI_BXCXSz
		call	FindCode
		je	ETINY_GetQT

ETINY_exit:
		ret

ETINY_GetQT:
		mov	dx,si
		mov	si,012Fh
		mov	ax,01C3h
		mov	di,offset ETinyQTSig
		mov	cx,ETinyQTSSz
		call	FindCode
		jne	ETINY_exit

		mov	bx,bp
		mov	cx,dx
		mov	dx,si

		mov	si,offset IDTinyData
		call	eIndexedId
		mov	si,offset ACT_decomp
		jmp	SetBreakpoints


.data

IDTinyData label
dw 018Ch, 0162h, 01C3h, TINYPROG, _V1_0	  ,0
dw 00FCh, 00EEh, 012Fh, TINYPROG, _V3_0	  ,0
dw 00FDh, 00EFh, 0130h, TINYPROG, _V3_3	  ,0
dw 0101h, 00F3h, 0134h, TINYPROG, _V3_6	  ,0
dw 010Bh, 00FDh, 0141h, TINYPROG, _V3_8	  ,0
dw 010Eh, 0100h, 0144h, TINYPROG, _V3_9	  ,0
dw    0h,    0h,    0h, LB, TINYPROG, RB  ,0

TinyJumpS label
		db	0FFh,6Ch		; jmp [si+  ]
TinyJumpSSz	equ	$ - offset TinyJumpS

ETinyGSSig label
		pop	dx
		mov	es,dx
ETinyGSSz	equ	$ - offset ETinyGSSig

ETinyGISig label
		add	es:[di-0202h],bp
ETinyGISSz	equ	$ - offset ETinyGISig

GI_ESBXCX label
		add	es:[bx],cx
GI_ESBXCXSz	equ	$ - offset GI_ESBXCX

GI_ESBXAX label
		add	es:[bx],ax
GI_ESBXAXSz	equ	$ - offset GI_ESBXAX

GI_BXCX  label
		add	[bx],cx
GI_BXCXSz	equ	$ - offset GI_BXCX

ETinyQTSig label
		db	08Eh,0DAh		; mov	ds,bx
		xor	bx,bx
		sti
		jmp	dword ptr cs:[000Ch]
ETinyQTSSz	equ	$ - offset ETinyQTSig
