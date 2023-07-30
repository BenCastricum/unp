; CSPRT.ASM
; last update : 18-Okt-1993

.code
CSPRT_entry:	ASSUME	ds:NOTHING, es:NOTHING
		mov	es,SegData
		ASSUME	es:DGROUP
		mov	ds,RegCS
		ASSUME	ds:NOTHING
		mov	si,0100h
		lodsb
		cmp	al,0B8h			; check mov ax,...
		jne	CSPRT_exit
		lodsw
		xchg	bx,ax
		lodsw
		cmp	ax,0E0FFh		; check jmp ax

		mov	si,bx
		mov	di,offset CSPRTs
		mov	cx,CSPRTl
		repz	cmpsb
		jne	CSPRT_exit

		mov	si,offset CSPRTver	; identify
		call	WriteVersion

		sub	bx,5			; restore code
		mov	si,bx
		mov	di,0100h
		mov	cx,5
		push	ds
		pop	es
		ASSUME	ds:NOTHING
		repnz	movsb

		mov	ds,SegData
		ASSUME	ds:DGROUP
		mov	RegDI,bx
		mov	ds,RegCS
		ASSUME	ds:NOTHING
		mov	bx,0100h		; execute nothing
		mov	si,offset ACT_rempassword
		jmp	HandleCom

CSPRT_exit:
		ret

.data
CSPRTs label
		add	ax,0Fh
		mov	si,ax
		mov	cx,01F4h
		xor	byte ptr [si],41h
		inc	si
		dec	cx
CSPRTl		equ	$ - offset CSPRTs

CSPRTver label
dw SUN_PROT, _V1_01, 0