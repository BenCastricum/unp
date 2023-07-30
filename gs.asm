; GS.ASM - GrabSize routines
; last update : 25-Apr-1994
;

.code
BreakGS:	ASSUME	ds:NOTHING, es:NOTHING
		push	ds
		mov	ds,SegData
		ASSUME	ds:DGROUP
		pop	RegDS
		mov	RegAX,ax
		mov	RegBX,bx
		mov	RegCX,cx
		mov	RegSI,si
		mov	RegDI,di
		mov	RegES,es
		pop	ax
		sub	ax,2
		mov	RegIP,ax
		pop	RegCS
		pop	Flags

		call	[GetProgSize]

		mov	ax,GSInst
		mov	bx,GSOffs
		mov	es,GSSegm
		cmp	es:[bx],INTGS*100h + 0CDh
		jne	GSMoved
		mov	es:[bx],ax
GSMoved:
		mov	bx,RegIP
		mov	es,RegCS
		cmp	es:[bx],INTGS*100h + 0CDh
		jne	GSRemoved
		mov	es:[bx],ax
GSRemoved:
		mov	es,RegES
		mov	ax,RegAX
		mov	bx,RegBX
		mov	cx,RegCX
		mov	si,RegSI
		mov	di,RegDI
		push	Flags
		push	RegCS
		push	RegIP
		mov	ds,RegDS
		iret

;---------------------------------------------------------------------------;
GS_ESDI:	ASSUME	ds:DGROUP, es:NOTHING
		mov	ax,RegDI
		mov	ProgFinalOfs,ax
		mov	ax,RegES
		mov	ProgFinalSeg,ax
		ret

GS_DSSI:	ASSUME	ds:DGROUP, es:NOTHING
		mov	ax,RegSI
		mov	ProgFinalOfs,ax
		mov	ax,RegDS
		mov	ProgFinalSeg,ax
		ret

GS_DSBX:	ASSUME	ds:DGROUP, es:NOTHING
		mov	ax,RegBX
		mov	ProgFinalOfs,ax
		mov	ax,RegDS
		mov	ProgFinalSeg,ax
		ret

GS_DSDI:	ASSUME	ds:DGROUP, es:NOTHING
		mov	ax,RegDI
		mov	ProgFinalOfs,ax
		mov	ax,RegDS
		mov	ProgFinalSeg,ax
		ret

GS_CS00:	ASSUME	ds:DGROUP, es:NOTHING
		mov	ProgFinalOfs,0
		mov	ax,RegCS
		mov	ProgFinalSeg,ax
		ret

;---------------------------------------------------------------------------;
SetGS:		ASSUME	ds:NOTHING, es:NOTHING
		push	ax
		push	es
		mov	es,SegData
		ASSUME	es:DGROUP
		mov 	ax,INTGS*100h + 0CDh
		xchg	ax,ds:[bx]
		mov	GSSegm,ds
		mov	GSOffs,bx
		mov	GSInst,ax
		pop	es
		pop	ax
		ret

.data
GetProgSize	dw	0

GSOffs		dw	0
GSSegm		dw	0
GSInst		dw	0
