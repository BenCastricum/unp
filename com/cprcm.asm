; CPRCM.ASM
; last update : 21-Mar-1994

.code
CPRCM_entry:	ASSUME	ds:NOTHING, es:NOTHING
		mov	es,SegData
		ASSUME	es:DGROUP
		mov	ds,RegCS
		ASSUME	ds:NOTHING
		mov	si,1D8h
		mov	di,offset CPRCMs
		mov	cx,CPRCMl
		repz	cmpsb
		jne	CPRCM_exit
		mov	si,offset CPRCMver
		call	WriteVersion
		mov	bx,01E8h
		mov	si,offset ACT_decomp
		jmp	HandleCom

CPRCM_exit:
		ret

.data
CPRCMs label
		db	8Ah,1Ch			; mov    bl,[si]
		db	46h			; inc    si
		db	8Bh,0D6h		; mov    dx,si
		db	8Bh,0F7h		; mov    si,di
		db	2Bh,0F3h		; sub    si,bx
		db	0F3h,0A4h		; rep movsb
		db	8Bh,0F2h		; mov    si,dx
		db	0E9h,58h,0FFh		; jmp    0140
CPRCMl		equ	$ - offset CPRCMs

CPRCMver label
dw PROCOMP, _V0_82, 0
