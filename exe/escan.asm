; ESCAN.ASM
; last update : 18-Sep-1994

.code
ESCAN_entry:	ASSUME	ds:NOTHING, es:NOTHING
		mov	es,SegData
		ASSUME	es:DGROUP

		mov	ax,ExeImageSz
		mov	dx,ExeImageSz+2
		sub	ax,10
		sbb	dx,0
		div	ParSize
		add	ax,SegProgram
		mov	ds,ax
		mov	si,dx

		mov	di,offset CSCANAV
		mov	cx,CSCANAVl
		mov	bp,si
		repz	cmpsb
		jne	ESCAN_ag
		mov	si,offset CSCAN_AVver
ESCAN_id:
		call	WriteVersion
		mov	si,offset ACT_remvirdat
		call	Action
		mov	ProgFinalSeg,ds
		mov	ProgFinalOfs,bp
		mov	si,offset ACT_done
		call	WriteLnASCIIZ
		jmp	UpdateHeader

ESCAN_ag:
		mov	ax,ExeImageSz
		mov	dx,ExeImageSz+2
		sub	ax,52
		sbb	dx,0
		div	ParSize
		add	ax,SegProgram
		mov	ds,ax
		mov	si,dx

		mov	di,offset CSCANAV
		mov	cx,CSCANAVl
		mov	bp,si
		repz	cmpsb
		mov	si,offset CSCAN_AGver
		je	ESCAN_id

ESCAN_exit:
		ret
