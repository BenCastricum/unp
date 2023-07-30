; CSCAN.ASM
; last update : 20-Sep-1993

.code
CSCAN_entry:	ASSUME	ds:NOTHING, es:NOTHING
		mov	es,SegData
		ASSUME	es:DGROUP
		mov	ds,RegCS
		ASSUME	ds:NOTHING

		mov	si,DTA_FileSize
		add	si,0100h-10
		mov	ax,si
		mov	di,offset CSCANAV
		mov	cx,CSCANAVl
		repz	cmpsb
		jne	CSCAN_ag
		mov	si,offset CSCAN_AVver
CSCAN_id:
		mov	bx,RegIP
		mov	RegDI,ax
		call	WriteVersion
		mov	si,offset ACT_remvirdat
		jmp	HandleCom

CSCAN_ag:
		mov	si,DTA_FileSize
		add	si,0100h-52
		mov	ax,si
		mov	di,offset CSCANAV
		mov	cx,CSCANAVl
		repz	cmpsb
		mov	si,offset CSCAN_AGver
		je	CSCAN_id

CSCAN_exit:
		ret

.data
CSCANAV label
		db	0F0h, 0FDh, 0C5h, 0AAh, 0FFh, 0F0h
CSCANAVl	equ	$ - offset CSCANAV

CSCAN_AVver 	dw SCAN, __AV, 0
CSCAN_AGver 	dw SCAN, __AG, 0