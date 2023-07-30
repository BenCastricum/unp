		ASSUME	ds:NOTHING,es:NOTHING

MCBId		equ	+0
MCBOwner	equ	+1
MCBSize		equ	+3


MapMem:
		push	ds
		push	es
		call	GetFreeMem		; allign free blocks
		mov	si,offset MM_text1
		call	WriteLnASCIIZ
		mov	ah,52h
		int	21h			; get list of lists
		ASSUME	es:NOTHING
		mov	ax,es:[bx-2]		; get first MCB
DoMCB:
		mov	ds,ax
		ASSUME	ds:NOTHING
		mov	es,SegData
		ASSUME	es:DGROUP
		call	WriteHexWord
		mov	si,offset MM_text2
		call	WriteASCIIZ
		mov	ax,ds:[MCBSize]
		inc	ax			; count MCB itself too
		call	WriteHexWord
		mov	si,offset MM_text2
		call	WriteASCIIZ
		mov	ax,ds:[MCBOwner]
		push	ds
		mov	si,offset MM_NoOwner
		or	ax,ax
		je	WriteOwner
		mov	si,offset MM_OwnerDos
		cmp	ax,8
		je	WriteOwner

		dec	ax
		mov	ds,ax
		ASSUME	ds:NOTHING
		mov	si,8
		mov	di,offset Filename3
		mov	cx,si
CopyByte:
		lodsb
		cmp	al,0
		je	Fill
		stosb
		loop	CopyByte
Fill:
		mov	al,20h
		repnz	stosb
		stosb
		pop	ds
		push	ds
		mov	ax,ds
		inc	ax
		mov	bx,ds:[MCBOwner]
		mov	si,offset MM_OwnerSelf
		cmp	ax,bx
		je	AddDescription
		mov	ds,bx
		mov	si,offset MM_OwnerEnv
		cmp	ax,ds:[002Ch]
		je	AddDescription
		mov	si,offset MM_OwnerData

AddDescription:
		mov	ds,SegData
		mov	cx,20
		repnz	movsb
		mov	si,offset Filename3
WriteOwner:
		call	WriteLnASCIIZ

		pop	ds
		mov	ax,ds
		add	ax,ds:[3]
		inc	ax
		mov	bl,ds:[0]		; get MCB type
		cmp	bl,'M'
		je	DoMCB
		call	WriteLn
		pop	es
		pop	ds

.data
MM_text1	db	'block size  owner    type',CR,LF
		db	'----------------------------------------',0
;			 0000h 0000h UNP41234 program
MM_text2	db	'h ',0
MM_NoOwner	db	'-------- unused memory block',0
MM_OwnerDos	db	'MS-DOS   special DOS block',0
MM_OwnerSelf	db	'program',0
MM_OwnerEnv	db	'environment',0
MM_OwnerData	db	'data',0
.code