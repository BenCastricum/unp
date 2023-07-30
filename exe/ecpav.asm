; /**/
; /*
;    filename    : ECPAV.ASM
;    created by  : Ben Castricum
;    created on  : ?
;    handles     : CENTRAL POINT ANTI-VIRUS V1 and TNT ANTI-VIRUS
;    last update :  8-Apr-1995
;    status      : completed
;    comments    : CPAV appends the original header after the program if it
;                    contains relocation items. If this is not the case, UNP
;                    uses a different approach.
;
;    revision history :
; 08-Apr-1995 : Renamed GI signature
;									   */
;									 /**/


.code
ECPAV_entry:	ASSUME	ds:NOTHING, es:NOTHING
		mov	es,SegData
		ASSUME	es:DGROUP
		mov	ds,RegCS
		ASSUME	ds:NOTHING
		mov	si,RegIP
		lodsb
		cmp	al,0E8h			; first instruction call ?
		jne	ECPAV_exit
		lodsw
		lea	bp,[si-0103h]		; calculate BP
		add	si,ax
		mov	di,offset ECPAVS
		mov	cx,ECPAVSSz
		push	si
		repz	cmpsb
		pop	si
		jne	ECPAV_exit

		push	si			; search end of check
		mov	si,01AFh
		mov	ax,01C1h
		mov	cx,ECPAVS2Sz
		mov	di,offset ECPAVS2
		call	FindCode
		pop	ax
		jne	ECPAV_exit
		lea	bx,[si+ECPAVS2Sz-3Ah]
		xchg	si,ax
		mov	byte ptr [si-24h+37h],0E9h ; no virus check
		mov	word ptr [si-24h+38h],bx

		push	si			; search headercheck
		mov	si,01CDh
		mov	ax,01DDh
		mov	cx,ECPAVS3Sz
		mov	di,offset ECPAVS3
		call	FindCode
		pop	ax
		jne	ECPAV_exit
		mov	bx,[si+ECPAVS3Sz]
		add	bx,bp
		cmp	word ptr ds:[bx],0
		jne	ECPAV_with

		mov	bx,24h
		mov	GetProgSize,offset GS_CS00
		mov	HeaderBuild,offset HBCPAV_NI
		jmp	ECPAV_go

ECPAV_with:
		lea	bx,[si+01EFh-01D8h]
		mov	HeaderBuild,offset HBCPAV_I
		mov	GetProgSize,offset GS_DSSI

ECPAV_go:
		mov	si,01F9h		; GI
		mov	ax,0209h
		mov	cx,GI_ESDIAXSz
		mov	di,offset GI_ESDIAX
		call	FindCode
		jne	ECPAV_exit

		mov	cx,si
		lea	dx,[si+8]

		mov	ax,ds:[034h]
		add	bx,ax
		mov	si,offset CPAVid
		call	eIndexedId
		sub	bx,ax

		mov	ExpectedInts,offset ECPAV_ints
		mov	si,offset ACT_remimmunize
		jmp	SetBreakpoints

ECPAV_exit:
		ret

HBCPAV_I:	ASSUME	ds:NOTHING,es:NOTHING
		mov	es,SegData
		ASSUME	es:DGROUP
		mov	ds,ProgFinalSeg
		mov	si,ProgFinalOfs
		call	CheckHeader
		jne	HBCPAV_Invalid

		call	FreeExeMem

		inc	HeaderStored
		mov	bx,2
		mov	si,offset ME_Header
		call	AllocateMem
		mov	SegEHInfo.A,ax
		mov	SegEHInfo.S,1Ch
		mov	es,ax
		ASSUME	es:NOTHING

		xor	si,si
		xor	di,di
		mov	cx,1Ch /2
		repnz	movsw

		mov	bp,ds:[HeaderSz]
		mov	cl,4
		shl	bp,cl
		sub	bp,1Ch

		cmp	ds:[RelocItemsCnt],0
		je	MoveAfter

		mov	dx,ds:[RelocOffs]
		sub	dx,1Ch
		mov	bx,dx
		mov	cl,4
		shr	bx,cl
		inc	bx
		push	si
		mov	si,offset ME_Header
		call	AllocateMem
		mov	es,SegData
		ASSUME	es:DGROUP
		mov	SegEHToItems.A,ax
		mov	SegEHToItems.S,dx
		pop	si
		mov	es,ax
		ASSUME	es:NOTHING
		mov	cx,dx
		xor	di,di
		repnz	movsb
		sub	bp,dx
		mov	ax,ds:[RelocItemsCnt]
		shl	ax,2
		sub	bp,ax
		add	si,ax

MoveAfter:
		mov	bx,bp
		mov	cl,4
		shr	bx,cl
		inc	bx
		push	si
		mov	si,offset ME_Header
		call	AllocateMem
		mov	es,SegData
		ASSUME	es:DGROUP
		mov	SegEHAfter.A,ax
		mov	SegEHAfter.S,bp
		pop	si
		mov	es,ax
		ASSUME	es:NOTHING
		mov	cx,bp
		xor	di,di
		repnz	movsb

HBCPAV_NI:	ASSUME	ds:NOTHING,es:NOTHING
		mov	ds,SegData
		ASSUME	ds:DGROUP
		inc	HeaderStored
		jmp	UpdateHeader

HBCPAV_Invalid:
		mov	si,offset WAR_header
		call	Warning
		jmp	HBCreate

.data
CPAVid label word
dw 01E4h + 0428h, 01F9h, 0201h, CENTRAL_POINT_, ANTI_VIRUS, _V1         , 0
dw 0024h + 0428h, 01F9h, 0201h, CENTRAL_POINT_, ANTI_VIRUS, _V1, __N_   , 0
dw 01EFh + 0433h, 0204h, 020Ch, CENTRAL_POINT_, ANTI_VIRUS, _V1_1       , 0
dw 0024h + 0433h, 0204h, 020Ch, CENTRAL_POINT_, ANTI_VIRUS, _V1_1, __N_ , 0
dw 01E4h + 0435h, 01F9h, 0201h, TURBO_, ANTI_VIRUS, _V7_02A	        , 0
dw 0024h + 0435h, 01F9h, 0201h, TURBO_, ANTI_VIRUS, _V7_02A, __N_       , 0
dw         0626h, 0209h, 0211h, TURBO_, ANTI_VIRUS, _V9_40		, 0
dw         061Ch, 0204h, 020Ch, LB, TURBO_, ANTI_VIRUS, RB		, 0
dw 0000h        , 0000h, 0000h, LB, CENTRAL_POINT_, ANTI_VIRUS, RB	, 0

ECPAV_ints label
		db	3Dh			; open file
		db	42h			; move file pointer
		db	3Eh			; close file
		db	3Fh			; read from file
		db	0

ECPAVS label
		db	5Bh			; pop    bx
		db	81h,0EBh,3,1		; sub    bx,0103
		db	50h			; push   ax
		db	51h			; push   cx
		db	52h			; push   dx
		db	56h			; push   si
		db	57h			; push   di
		db	8Bh,0EBh		; mov    bp,bx
		db	1Eh			; push   ds
ECPAVSSz	equ	$ - offset ECPAVS

ECPAVS2 label
		db	0CDh,21h		; int    21
		db	0B4h,3Eh		; mov    ah,3E
		db	0CDh,21h		; int    21
ECPAVS2Sz	equ	$ - offset ECPAVS2

ECPAVS3 label
		db	0F3h,0A4h		; rep movsb
		db	50h			; push   ax
		db	6			; push   es
		db	2Eh,83h,0BEh		; cmp    cs:word ptr
ECPAVS3Sz	equ	$ - offset ECPAVS3

GI_ESDIAX label
		db	26h,1,5			; add    es:[di],ax
GI_ESDIAXSz	equ	$ - offset GI_ESDIAX