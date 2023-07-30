; CC2CR.ASM
; last update : 19-Apr-1994
;
; 20-Mar-1994: changed code to take advantage of final size overide code
;  2-Apr-1994: noticed and removed useless instruction
; 19-Apr-1994: skipped first near jump (E9h)

.code
CC2CR_entry:	ASSUME	ds:NOTHING,es:DGROUP
		mov	si,RegIP
		add	si,9011h-9000h
		mov	bx,si
		mov	di,offset CC2CR2s
		mov	cx,CC2CR2l
		repz	cmpsb
		jne	CC2CR_exit

		push	bx
		mov	si,offset CC2CRver
		call	WriteVersion
		pop	bx

		call	Break
		add	bx,901Ah-9011h
		mov	ax,bx
		and	ax,1
		sub	ax,4
		mov	ProgFinalOfs,ax
		mov	si,offset ACT_remencrypt
		jmp	HandleCom

CC2CR_exit:
		ret

.data
CC2CR2s label
		cld
		lodsw
		xor	ax,dx
		stosw
		ror	dx,1
CC2CR2l		equ	$ - offset CC2CR2s

CC2CRver label
dw COM2CRP, _V1_0, 0