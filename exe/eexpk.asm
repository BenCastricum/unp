; /**/
; /*
;    filename    : EEXPK.ASM
;    created by  : Ben Castricum
;    created on  : ?
;    handles     : Exepack all versions
;    last update :  8-Apr-1995
;    status      : completed
;    comments    :
;
;    revision history :
; 08-Apr-1995 : Renamed GI signature
;									   */
;									 /**/

.code
EEXPK_entry:	ASSUME	ds:NOTHING, es:DGROUP
		mov	ds,RegCS
		ASSUME	ds:NOTHING
		mov	es,SegData
		ASSUME	es:DGROUP

		mov	si,0039h
		mov	ax,0055h
		mov	di,offset EPGSSig
		mov	cx,EPGSSz
		call	FindCode		; search DGS
		jc	EEXPK_checkGS2
		inc	si
		call	FindCode		; search GS
		jc	EEXPK_checkGS2
		lea	bp,[si+5]		; get GS after sigcode
		jmp	EEXPK_checkGI

EEXPK_checkGS2:
		mov	si,004Bh		; offset first occurence
		mov	ax,004Fh
		mov	di,offset EPGS2Sig
		mov	cx,EPGS2Sz
		call	FindCode		; search GS2
		jc	EEXPK_exit
		lea	bp,[si+8]		; get GS2 after sigcode

EEXPK_checkGI:
		mov	si,00B2h
		mov	ax,00D9h
		mov	di,offset GI_ESDIBX
		mov	cx,GI_ESDIBXSz
		call	FindCode		; search GI
		mov	dx,si
		jc	EEXPK_exit
		inc	si
		call	FindCode		; search 2ndGI
		jc	EEXPK_checkQT
		mov	bx,si
		call	SetGI	

EEXPK_checkQT:
		mov	si,00DDh
		mov	ax,0103h
		mov	di,offset EPQTSig
		mov	cx,EPQTSz
		call	FindCode		; search QT
		jc	EEXPK_exit

		mov	bx,bp
		mov	cx,dx
		mov	dx,si

		mov	si,offset EPIDData
		call	eIndexedId

		inc	ExeSizeAdjust
		mov	si,offset ACT_decomp
		jmp	SetBreakpoints

EEXPK_exit:
		ret

.data
EPIDData label word
dw 0050h, 00B2h, 00E3h, EXEPACK, _V4_00                          , 0
dw 0050h, 00B7h, 00F8h, EXEPACK, _V4_03                          , 0
dw 0058h, 00BDh, 00FEh, EXEPACK, _V4_05, _or, _V4_06             , 0
dw 0053h, 00B9h, 00DDh, EXEPACK, _patched_with_, EXPAKFIX, _V1_0 , 0
dw 0050h, 00B5h, 00F6h, LINK, _V3_60, C, _V3_64, C, _V3_65
dw			_or, _V5_01_21, _, FwdS, EXEPACK 	 , 0
dw 0052h, 00C0h, 0103h, LINK, _V3_69, _, FwdS, EXEPACK		 , 0
dw 0	, 0    , 0    , LB, EXEPACK, RB                          , 0

EPGSSig label
		mov	es,ax
		mov	di,000Fh
EPGSSz		equ	$ - EPGSSig

EPGS2Sig label
		db	87h,0F7h		; xchg	di,si
		mov	ax,cs
		sub	ax,dx
		mov	es,ax
EPGS2Sz		equ	$ - EPGS2Sig

;signature below is moved to GI.ASM
;GI_ESDIBX label
;		add	es:[di],bx
;GI_ESDIBXSz	equ	$ - GI_ESDIBX

EPQTSig label
		jmp	dword ptr cs:[bx]
EPQTSz		equ	$ - EPQTSig

