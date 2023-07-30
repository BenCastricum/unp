; /**/
; /*
;    filename    : ECMPK.ASM
;    created by  : Ben Castricum
;    created on  : ?
;    handles     : COMPACK V4.4 and V4.5
;    last update : 2-Nov-1994
;    status      : completed
;    comments    : COMPACK is a .COM and .EXE compressor
;
;    revision history :
; 02-Nov-1994 : added ExeSizeAdjust of +3
;									   */
;									 /**/

.code
ECMPK_entry:	ASSUME	ds:NOTHING, es:NOTHING
		mov	es,SegData
		ASSUME	es:DGROUP
		mov	ds,RegCS
		ASSUME	ds:NOTHING

		mov	ax,RegCS
		add	ax,ds:[0001h]
		mul	ParSize
		add	ax,ds:[000Fh]
		adc	dx,0
		sub	ax,0044h
		sbb	dx,0
		test	dx,0FFF0h
		jne	ECMPK_exit
		div	ParSize
		mov	ds,ax
		ASSUME	ds:NOTHING
		mov	si,dx
		mov	ax,si
		mov	di,offset Compack44S
		mov	cx,Compack44SSz
		repz	cmpsb
		jne	ECMPK_check45

		mov	bx,dx
		add	bx,2Fh
		mov	cx,dx
		add	cx,29
		add	dx,31h
		mov	si,offset verEMCPK44

ECMPK_go:
		mov	GetProgSize,offset GS_DSSI
		mov	ExeSizeAdjust,3
		call	WriteVersion
		mov	si,offset ACT_decomp
		jmp	SetBreakpoints
ECMPK_check45:
		mov	si,ax
		inc	si
		mov	di,offset Compack45S
		mov	cx,Compack45SSz
		repz	cmpsb
		jne	ECMPK_exit

		mov	bx,dx
		add	bx,2Fh
		mov	cx,dx
		add	cx,35
		add	dx,31h

		mov	si,offset verEMCPK45

		jmp	ECMPK_go


ECMPK_exit:
		ret


.data
verEMCPK44 label
dw COMPACK, _V4_4          , 0

verEMCPK45 label
dw COMPACK, _V4_5          , 0


Compack44S label
	dw	8BFDh,5FF7h,7942,55179,37198,65211,44287,516,4210,55299,1401
	dw	61312,65040,36550,9922,16129,60395
Compack44SSz		equ	$ - Compack44S

Compack45S label
	dw	35837,24567,7942,55179,302,3646,19975,48017,65534,1196,29186
	dw	784,31192,32773,4335,50942,49806,294,60223,20203,5123,18510
	dw	58484
Compack45SSz		equ	$ - Compack45S
