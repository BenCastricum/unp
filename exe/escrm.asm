; Unpacks the program USRPATCH.EXE.
;
; This program contains a large number of only 2 routines. It uses
; self-modifying code causing it to crash on a 486.

.code
ESCRM_entry:	ASSUME	ds:NOTHING, es:NOTHING
		mov	es,SegData
		ASSUME	es:DGROUP
		mov	ds,RegCS
		ASSUME	ds:NOTHING
		mov	si,RegIP
		mov	di,offset EUSRPs
		mov	cx,EUSRPl
		mov	ax,si
		add	ax,20h
		call	FindCode
		jc	ESCRM_Debug
		mov	bx,si
		add	bx,EUSRPl - 2
		call	Break
		sub	bx,3
		call	Break
		add	bx,5
		call	Break
		jmp	ESCRM_entry

ESCRM_Debug:
		mov	si,RegIP
		mov	di,offset EUSRPs2
		mov	cx,EUSRPl2
		mov	ax,si
		call	FindCode
		jc	Halt
		add	si,2Fh
		mov	RegIP,si
		mov	RegAX,01h
		jmp	ESCRM_entry

Halt:
		mov     si,RegIP
		add	si,242Eh-23D0h
		mov	ax,si
		mov	di,offset UsrGSSig
		mov	cx,UsrGSSigSz
		call	FindCode
		jne	ESCRM_exit
		mov	dx,si

		mov     si,RegIP
		add	si,2446h-23D0h
		mov	ax,si
		mov	di,offset UsrGISig
		mov	cx,UsrGISigSz
		call	FindCode
		jne	ESCRM_exit

		mov	bx,di
		mov	di,si
		mov	si,bx
		add	si,2466h-242Eh
		push	si
		mov	si, offset UsrpatchId
		call	WriteVersion
		pop	si
		mov	GetProgSize,offset GS_DSDI

		mov	si,offset ACT_remencrypt
		mov	bx,242Eh
		mov	cx,2446h
		mov	dx,2466h
		jmp	SetBreakpoints

ESCRM_exit:
		ret

.data
UsrpatchId label
dw SCRAMBLER, _V1_00, 0

EUSRPs label
		xor	cs:[si],al
		add	al,0A9h
		inc	si
		db	0E2h,0F8h		; loop	EUSRPs
EUSRPl		equ	$ - offset EUSRPs

EUSRPs2 label
		db	31h,0C0h		; xor	ax,ax
		mov	ds,ax
		mov	bx,ds:[0000h]
		mov	cx,ds:[0002h]
EUSRPl2		equ	$ - offset EUSRPs2

UsrGSSig label
		pop	si
		mov	cx,cs:[si+06]
UsrGSSigSz	equ	$ - UsrGSSig

UsrGISig label
		add	[bx],ax
		add	di,0004h
UsrGISigSz	equ	$ - UsrGISig
