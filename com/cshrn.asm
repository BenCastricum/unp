; CSHRN.ASM
; last update : 20-Sep-1993

.code
CSHRN_entry:	ASSUME	ds:NOTHING, es:NOTHING
		mov	es,SegData
		ASSUME	es:DGROUP
		mov	ds,RegCS
		ASSUME	ds:NOTHING

		mov	ax,word ptr ds:[011Ch]
		mov	word ptr [CSHRNs+1Ch],ax
		mov	al,byte ptr ds:[011Eh]
		mov	byte ptr [CSHRNs+1Eh],al
		mov	di,offset CSHRNs
		mov	si,0100h
		mov	cx,CSHRNl
		repz	cmpsb
		jne	CSHRN_exit
		mov	si,offset CSHRN_ver
		call	WriteVersion

		xor     dx,dx			; clear bug flag
		push	ds
		pop	es
		ASSUME	es:NOTHING
		mov	cx,ds:[011Ch]		; copy datablock to end of segment
		push	cx
		xor	di,di
		mov	si,0152h
		sub	di,cx
		push	di
		repnz	movsb
		pop	si
		pop	cx
		mov	di,0100h
		mov	ah,ds:[011Eh]
CSHRN_GetByte:
		lodsb
		cmp	al,ah
		je	CSHRN_GotFlag
		mov	bh,al
		stosb
CSHRN_ToNext:
		loop	CSHRN_GetByte
		jmp	CSHRN_done

CSHRN_GotFlag:
		or	si,si
		je	CSHRN_done
		mov	al,bh
		mov	bl,[si]
		inc	si
		or	bl,bl
		jne	CSHRN_CopyByte
		mov	al,ah
		inc	bl
		inc	dx
CSHRN_CopyByte:
		stosb
		dec	bl
		jne	CSHRN_CopyByte
		loop	CSHRN_ToNext
CSHRN_done:
		or	dx,dx
		je	CSHRN_stop
		mov	si,offset CSHRN_Bug$
		call	Warning
CSHRN_stop:
		mov	es,SegData
		ASSUME	es:DGROUP
		mov	bx,RegIP
		mov	RegDI,di
		mov	si,offset ACT_decomp
		jmp	HandleCom

CSHRN_exit:
		ret
.data
CSHRNs label
	dw	40016,48892,287,191,22398,13497,62208,35748,7182,48641,338
	dw	59583,62336,50084,242,48641,33000,3723,284,9866,286,191,22273
	dw	15020,29892,35344,43736,63202,40283,21336,55691,61835,63883
	dw	44227,49162,60788,34377,43715,52222,64373,58603
CSHRNl		equ	$ - offset CSHRNs

CSHRN_ver label
dw SHRINK, _V1_0, 0

CSHRN_Bug$	db	'Missing last byte, unable to completely restore file.',0
