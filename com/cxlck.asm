; CXLCK.ASM
; last update : 30-Sep-1993

.code
CXLCK_entry:	ASSUME	ds:NOTHING, es:NOTHING
		mov	es,SegData
		ASSUME	es:DGROUP
		mov	ds,RegCS
		ASSUME	ds:NOTHING
		mov	si,0100h

		lodsb
		cmp	al,0E8h			; call XXXX ?
		jne	CXLCK_exit
		lodsw
		add	si,ax
		mov	dx,si			; save possible COM length
		mov	bx,si

		mov	di,offset CXLCKs
		mov	cx,CXLCKl
		repz	cmpsb
		jne	CXLCK_exit

		mov	si,offset CXLCK_ver
		call	WriteVersion

		mov	al,[bx+9069h-9000h]	; restore file
		mov	ds:[0100h],al
		mov	ax,[bx+906Dh-9000h]
		mov	ds:[0101h],ax

		mov	bx,RegIP
		mov	RegDI,dx
		mov	si,offset ACT_remavirus
		call	HandleCom
CXLCK_exit:
		ret

.data
CXLCKs label
		push	ax
		push	bx
		push	cx
		push	dx
		push	ds
		mov	ds,ds:[002Ch]
		xor	bx,bx
		mov	ax,[bx]
		inc	bx
		cmp	ax,0
CXLCKl		equ	$ - offset CXLCKs

CXLCK_ver label
dw F_XLOCK, _V1_16, 0