; EXLCK.ASM
; last update : 18-Sep-1994

.code
EXLCK_entry:	ASSUME	ds:NOTHING, es:NOTHING
		mov	es,SegData
		ASSUME	es:DGROUP
		mov	ds,RegCS
		ASSUME	ds:NOTHING
		mov	si,RegIP
		mov	di,offset EXLCKS
		mov	cx,EXLCKSz
		repz	cmpsb
		jne	EXLCK_exit

		mov	si,offset CXLCK_ver
		call	WriteVersion

		mov	si,offset ACT_remavirus
		call	Action

		mov	ax,RegCS
		mov	ProgFinalSeg,ax
		mov	ax,RegIP
		mov	ProgFinalOfs,ax

		mov	ax,ds:[000Dh]
		add	ax,SegProgPSP
		mov	RegCS,ax
		mov	ax,ds:[0017h]
		mov	RegIP,ax

		mov	si,offset ACT_done
		call	WriteLnASCIIZ
		jmp	UpdateHeader

EXLCK_exit:
		ret

.data

EXLCKS label
		db	50h			; push   ax
		db	50h			; push   ax
		db	50h			; push   ax
		db	53h			; push   bx
		db	51h			; push   cx
		db	52h			; push   dx
		db	56h			; push   si
		db	1Eh			; push	 ds
		db	8Bh, 0DCh		; mov    bx,sp
		db	8Ch, 0D8h		; mov    ax,ds
		db	05h			; add    ax,....
EXLCKSz		equ 	$ - offset EXLCKS