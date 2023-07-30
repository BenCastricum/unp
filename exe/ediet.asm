; /**/
; /*
;    filename    : EDIET.ASM
;    created by  : Ben Castricum
;    created on  : ?
;    handles     : DIET all versions
;    last update :  8-Apr-1995
;    status      : completed
;    comments    :
;
;    revision history :
; 08-Apr-1995 : Renamed GI signature
;									   */
;									 /**/

.code
EDIET_entry:	ASSUME	ds:NOTHING, es:NOTHING
		mov	es,SegData
		ASSUME	es:DGROUP
		mov	ds,RegCS		; check for code found in all
		mov	si,RegIP
		lea	ax,[si+4Ch]
		add	si,2Dh
		mov	di,offset DietHeadS
		mov	cx,DietHeadSSz
		call	FindCode
		jnc	EDIET_exexp1
		cmp	Command,'T'		; if tracing check part2
		je	EDIET_part2
		ret

EDIET_exexp1:
		mov	bp,RegIP
		lea	bx,[si+DietHeadSSz]
		call	Break                   ; allow memory copy part
		call	Trace			; do far jmp / retf
EDIET_part2:
		mov	ax,RegIP
		push	ax
		mov	cl,4
		shr	ax,cl
		add	ax,RegCS
		mov	ds,ax
		pop	si
		and	si,000Fh		; ds:si next part
		mov	TempDouble,si

		mov	si,1Bh
		mov	ax,79h
		mov	di,offset DietGSS	; search GS
		mov	cx,DietGSSSz
		call	FindCode
		mov	bx,si

		mov	si,1Bh
		mov	di,offset DietGS2S	; search GS2
		mov	cx,DietGS2Sz
		call	FindCode

		cmp	bx,si			; sort dx and si
		jbe	EDIET_checkGS
		xchg	bx,si
EDIET_checkGS:
		cmp	bx,ax			; no GS found?
		ja	EDIET_exit

EDIET_GetGI:
		mov	dx,-1
		mov	si,20h
		mov	ax,9Ch
		mov	di,offset GI_ESBXBP	; search GI
		mov	cx,GI_ESBXBPSz
		call	FindCode
		jc	EDIET_GetQT
		mov	dx,si
EDIET_GetQT:
		mov	si,20h
		mov	ax,0BFh
		mov	di,offset DietQTS	; search QT
		mov	cx,DietQTSSz
		call	FindCode
		jnc	EDIET_GetVals

		mov	si,20h
		mov	ax,0BFh
		mov	di,offset DietQT2S	; search QT2 (1.44 only)
		mov	cx,DietQT2SSz
		call	FindCode
		jnc	EDIET_GetVals

		mov	si,20h
		mov	ax,0BFh
		mov	di,offset DietQT3S	; search QT3 (1.44 com files)
		mov	cx,DietQT3SSz
		call	FindCode
		jc	EDIET_exit

EDIET_GetVals:
						; GS=BX already set
		mov	cx,dx		        ; GI
		mov	dx,si                   ; QT
		cmp	cx,dx			; items before QT ?
		jb	EDIET_GetVer
		mov	cx,-1			; no items
EDIET_GetVer:
		mov	ax,TempDouble
		sub	bx,ax
		sub	dx,ax
		add	bx,bp			; add to recognize 100d/102b
		cmp	cx,-1			; no items?
		je	EDIET_identify
		sub	cx,ax
EDIET_identify:
		mov	si,offset EDIETData
		call	eIndexedId
		cmp	si,offset EDIET_NoFix
		ja	EDIET_IsOk
		inc	SwitchLforced
EDIET_IsOk:
		mov	ax,TempDouble
		add	bx,ax
		sub	bx,bp
		add	dx,ax
		cmp	cx,-1			; no items?
		je	EDIET_go
		add	cx,ax
EDIET_go:
		mov	HeaderBuild,offset HBDIET
		mov	si,offset ACT_decomp
		jmp	SetBreakpoints

EDIET_exit:
		ret


; The DIET compressor stores the EXE header after the image before it starts
; compression. Not the whole header is stored, trailing 00's are removed.
; Also the relocation items are stored in a different format.
;
; Currently the header is not complete restored. The part after the items
; will be filled with 00's. This was done because there seems to be no
; obvious way the determine the space occupied by the fixups in the header.
; Those fixups are stored in a special format. Additional information is
; required to determine the size.


HBDIET:
		ASSUME	ds:NOTHING,es:NOTHING
		mov	es,SegData
		ASSUME	es:DGROUP
		mov	ds,ProgFinalSeg
		ASSUME	ds:NOTHING
		mov	si,ProgFinalOfs
		mov	ax,ProgFinalSeg		; calculate new image size
		sub	ax,SegProgram
		imul	ParSize
		add	ax,ProgFinalOfs
		adc	dx,0
		xor	bp,bp
		mov	cx,ax
		or	dx,dx
		je	HBDIET_next
		mov	cx,-1
HBDIET_next:
		inc	bp
		or	si,si
		jne	HBDIET_test
		mov	ax,ds
		dec	al
		mov	ds,ax
		mov	si,10h
HBDIET_test:
		dec	si
		mov	ax,ds:[si]
		cmp	ax,'MZ'
		je	HBDIET_check
		cmp	ax,'ZM'
		je	HBDIET_check
HBDIET_cont:
		loop	HBDIET_next
		cmp	NrRelocFound,0
		jne	HBDIET_invalid

		call	FreeExeMem		; write back as .COM
		mov	di,ProgFinalOfs
		mov	es,ProgFinalSeg
		jmp	ComWrite

HBDIET_invalid:
		mov	si,offset WAR_header
		call	Warning
		jmp	HBCreate

HBDIET_check:
		call	CheckHeader
		jne	HBDIET_cont

		push	si			; offset Header
		mov	ProgFinalSeg,ds
		mov	ProgFinalOfs,si
		call	FreeExeMem

		mov	bx,2
		mov	si,offset ME_Header
		call	AllocateMem
		pop	si			; offset Header
		push	si
		mov	di,0
		mov	SegEHInfo.A,ax
		mov	cx,01Ch
		mov	SegEHInfo.S,cx
		mov	es,ax
		ASSUME	es:NOTHING
		cmp	bp,cx			; full Info header?
		jae	HBDIET_CopyHeader
		mov	cx,bp
		repnz	movsb
		mov	cx,1Ch
		sub	cx,bp
		mov	al,0
		repnz	stosb
		mov	bp,0			; next code will be useless

HBDIET_CopyHeader:
		sub	bp,cx
		repnz	movsb
		mov	es,SegData
		ASSUME	es:DGROUP

		mov	ax,NrRelocFound
		or	ax,ax
		je	HBDIET_noitem
		pop	si			; offset Header
		push	si
		mov	ax,ds:[si+RelocOffs]
		sub	ax,1Ch
		mov	cx,ax
		mov	SegEHToItems.S,ax
		mov	dx,ax
		mov	bx,dx
		shr	bx,4
		and	dx,0Fh
		cmp	dh,dl
		adc	bx,0
		mov	si,offset ME_Header
		call	AllocateMem
		mov	SegEHToItems.A,ax
		mov	es,ax
		ASSUME	es:NOTHING
		pop	si			; offset Header
		push	si
		add	si,1Ch
		xor	di,di
		repnz	movsb
		jmp	HBDIET_fill

HBDIET_noitem:	ASSUME	es:DGROUP
		mov	SegEHToItems.S,bp
		mov	dx,bp
		mov	bx,dx
		shr	bx,4
		and	dx,0Fh
		cmp	dh,dl
		adc	bx,0
		mov	si,offset ME_Header
		call	AllocateMem
		mov	SegEHToItems.A,ax
		mov	es,ax
		ASSUME	es:NOTHING
		pop	si
		add	si,1Ch
		xor	di,di
		mov	cx,bp
		repnz	movsb

HBDIET_fill:
		mov	ds,SegData
		ASSUME	ds:DGROUP
		mov	es,SegEHInfo.A
		ASSUME	es:NOTHING
		mov	ax,es:[HeaderSz]
		mov	cl,4
		shl	ax,cl
		sub	ax,1Ch
		sub	ax,SegEHToItems.S
		mov	bx,NrRelocFound
		shl	bx,2
		sub	ax,bx
		mov	SegEHAfter.S,ax
		mov	bx,ax
		mov	cl,4
		shr	bx,cl
		mov	cx,ax
		and	ax,0Fh
		cmp	ah,al
		adc	bx,0
		mov	si,offset ME_Header
		call	AllocateMem
		mov	SegEHAfter.A,ax
		mov	es,ax
		ASSUME	es:NOTHING
		xor	di,di
		mov	al,0
		repnz	stosb
		inc	HeaderStored
		jmp	UpdateHeader


.data
EDIETData label word
dw 004Ah, -001h, 0059h, DIET, _V1_00, _or, _V1_00d, __LN_ 		,0
dw 004Ah, 0064h, 007Ah, DIET, _V1_00, _or, _V1_00d, __LI_		,0
EDIET_NoFix label
dw 001Eh, -001h, 002Dh, DIET, _V1_00, _or, _V1_00d, __SN_ 		,0
dw 001Eh, 0038h, 004Eh, DIET, _V1_00, _or, _V1_00d, __SI_ 		,0
dw 001Bh, -001h, 002Dh, DIET, _V1_02b, C, _V1_10a, _or, _V1_20, __SN_	,0
dw 001Bh, 0038h, 004Eh, DIET, _V1_02b, C, _V1_10a, _or, _V1_20, __SI_ 	,0
dw 0047h, -001h, 0059h, DIET, _V1_02b, C, _V1_10a, _or, _V1_20, __LN_	,0
dw 0047h, 0064h, 007Ah, DIET, _V1_02b, C, _V1_10a, _or, _V1_20, __LI_	,0
dw 001Bh, 003Ah, 005Ch, DIET, _V1_44, __S_				,0
dw 0047h, 0066h, 0088h, DIET, _V1_44, __L_				,0
dw 0036h, 0055h, 0077h, DIET, _V1_44, __G, __S_				,0
dw 006Ah, 0089h, 00ABh, DIET, _V1_44, __G, __L_				,0
dw 001Bh, 0044h, 005Eh, DIET, _V1_45f, __S_				,0
dw 0047h, 0070h, 008Ah, DIET, _V1_45f, __L_				,0
dw 0036h, 005Fh, 0079h, DIET, _V1_45f, __G, __S_			,0
dw 006Ah, 0093h, 00ADh, DIET, _V1_45f, __G, __L_			,0
dw 001Bh, 0038h, 0045h, LB, DIET, RB					,0
dw 0    , 0    , 0    , LB, DIET, RB					,0


DietHeadS label
		lodsw
		mov	bp,ax
		mov	dl,10h
DietHeadSSz	equ	$ - DietHeadS
;---
DietGSS label
		pop	bp
		push	cs
		pop	ds
DietGSSSz	equ	$ - DietGSS
;---
DietGS2S label
		pop	bp
		pop	es
		pop	ds
DietGS2Sz	equ	$ - DietGS2S
;---
GI_ESBXBP label
		add	es:[bx],bp
GI_ESBXBPSz	equ	$ - GI_ESBXBP
;---
DietQTS label
		xor	dx,dx
		xor	bx,bx
		xor	ax,ax
		db	0EAh
DietQTSSz	equ	$ - DietQTS
;---
DietQT2S label
		sti
		xor	bp,bp
		nop
		db	0EAh
DietQT2SSz	equ	$ - DietQT2S
;---
DietQT3S label
		sti
		xor	bp,bp
		push	bp
		db	0EAh
DietQT3SSz	equ	$ - DietQT3S