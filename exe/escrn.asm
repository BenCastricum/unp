; checks for some unknown .EXE version of CRNCH

.code

ESCRN_entry:	ASSUME	ds:NOTHING, es:NOTHING
		mov	es,SegData
		ASSUME	es:DGROUP
		mov	ds,RegCS
		ASSUME	ds:NOTHING
		mov	si,003Ah
		mov	di,offset ESCRNs
		mov	cx,ESCRNsSz
		repz	cmpsb
		je	ESCRN_go
		ret
ESCRN_go:
		mov	si,offset ESCRNid
		call	WriteVersion

		mov	ExpectedInts,offset ESCRN_ints
		mov	bx,01D8h
		mov	cx,-1
		mov	dx,024Ch
		mov	si,offset ACT_decomp
		jmp	SetBreakpoints

.data

ESCRN_ints label
		db	4Ah			; change memory block size

ESCRNid label
dw SCRNCH ,0

ESCRNs label
	dw	36092,20254,13059,21467,53388,32773,41728,387,49294,11496,3586
	dw	47391,0,58118,20763,63027
ESCRNsSz	equ	$ - offset ESCRNs

