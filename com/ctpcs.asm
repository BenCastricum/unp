; CTPCS.ASM
;
; last update : 19-Apr-1994
; 21-Mar-1994: changed code to take advantage of final size overide code
;
; 19-Apr-1994: skipped first near jump (E9h)

.code
CTPCS_entry:
		ASSUME	ds:NOTHING,es:DGROUP
		mov	bx,RegIP
		cmp	word ptr [bx+3],0100h	; check 2 constants
		jne	CTPCS_exit
		cmp	byte ptr [bx+34],0C3h
		jne	CTPCS_exit
		mov	ax,[bx+8]
		inc	ah
		mov	RegDI,ax
		add	bx,29
		mov	si,offset CTPCSver
		call	WriteVersion
		mov	si,offset ACT_remencrypt
		jmp	HandleCom

CTPCS_exit:
		ret

.data

CTPCSver label
dw LB, TPC_, SCRAMBLER, RB     , 0
