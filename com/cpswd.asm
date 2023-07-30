; CPSWD.ASM
; last update : 23-Sep-1993

.code
CPSWD_entry:	ASSUME	ds:NOTHING, es:NOTHING
		mov	es,SegData
		ASSUME	es:DGROUP
		mov	ds,RegCS
		ASSUME	ds:NOTHING
		mov	si,0100h

		mov	di,offset CPSWDs
		mov	si,107h
		mov	cx,CPSWDl
		repz	cmpsb
		jne	CPSWD_exit
		mov	si,offset CPSWD_ver
		call	WriteVersion
		mov	byte ptr ds:[0115h],77h
		mov	bx,ds:[0103h]
		add	bx,0Dh
		mov	si,offset ACT_rempassword
		jmp	HandleCom

CPSWD_exit:
		ret

.data
CPSWD_ver label
dw PAAI___PASSWORD,0

CPSWDs label
	dw	33471,48640,323,1721,62208,33702,249,2164
CPSWDl	equ	$ - offset CPSWDs

