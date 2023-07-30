; /**/
; /*
;    filename    : EPKLT.ASM
;    created by  : Ben Castricum
;    created on  : ?
;    handles     : all know versions of PKLITE except V1.50 and AVPACK
;    last update :  8-Apr-1995
;    status      : completed
;    comments    : The registered versions of PKLITE V1.14 and up encrypt
;		     the decompression routine and also add a signature
;		     into the PSP.
;
;    revision history :
; 27-Jun-1994 : Changed QT signature and corresponding indentify values.
; 20-Aug-1994 : Added AVPACK.
; 21-Aug-1994 : Removed check for 'PK' or 'pk' signature. This is now
;                 automaticly resolved.
; 25-Aug-1994 : Reorganised id-strings to be able to turn off header
;		  check for -e compress files.
; 29-Aug-1994 : Simplified PKLITE header rebuild code, now uses
;		  ForceAlign to achieve full header size.
;	        More id-string organizing to distinguish AVPACKed files.
; 30-AUG-1994 : Added rebuilding of AVPACKed files.
;		Changed QT search to fix AVPACK decompression bug.
; 08-Apr-1995 : Renamed GI signature
;									   */
;									 /**/

.code
EPKLT_entry:	ASSUME	ds:NOTHING, es:NOTHING
		mov	es,SegData
		ASSUME	es:DGROUP
		mov	ds,RegCS
		ASSUME	ds:NOTHING

; /*  remove pklite encryption header when available                     */ ;

		mov	si,013Fh
		mov	ax,0149h
		mov	di,offset PkDcdr
		mov	cx,PkDcdrSz
		call	FindCode
		jnc	EPKLT_RemEncr

		mov	si,0141h
		mov	di,offset PkDcdr2
		mov	cx,PkDcdr2Sz
		push	si
		repz	cmpsb
		pop	si
		jne	EPKLT_SearchGS

EPKLT_RemEncr:
		xchg	ax,si
		add	si,PkDcdrSz+1
		xchg	si,ax
		mov	ax,(PkDcdrSz-1)*256+74h	; 74h JE
EPKLT_ScanJE:
		cmp	ax,[si]
		je	EPKLT_GotJE
		inc	ah
		dec	si
		cmp	si,013Ch
		jne	EPKLT_ScanJE
		jmp	EPKLT_SearchGS

EPKLT_GotJE:
		mov	al,[si+1]
		mov	ah,0
		add	ax,si
		add	ax,2
		push	ax
		mov	bx,00FEh 		; adress to jump to
		lea	ax,[bx-2]		; adjust for JE
		sub	ax,si
		mov	ah,al
		mov	al,74h
		mov	[si],ax
		call	Break
		pop	si
		mov	RegIP,si

; /*  search for breakpoints				                 */ ;

EPKLT_SearchGS:
		mov	si,0165h
		mov	ax,032Fh
		mov	di,offset PkGSSig
		mov	cx,PkGSSz
		call	FindCode		; search GS
		mov	bp,si
		jnc	EPKLT_chck0005

		mov	si,0249h
		mov	ax,0259h
		mov	di,offset PkGS2Sig
		mov	cx,PkGS2Sz
		call	FindCode		; search GS2
		mov	bp,si
		je	EPKLT_SearchGI

		mov	si,036Ah
		mov	ax,036Ah
		mov	di,offset PkGS3Sig
		mov	cx,PkGS3Sz
		call	FindCode		; search GS3
		mov	bp,si
		je	EPKLT_SearchGI
EPKLT_exit:
		ret

EPKLT_chck0005:
		cmp	si,0311h		; V1.00 (2) or V1.05 (2) ?
		jne	EPKLT_chck1315
		cmp	byte ptr ds:[0151h],0BEh; V1.00 ?
		jne	EPKLT_SearchGI
		add     bp,2
		jmp	EPKLT_SearchGI

EPKLT_chck1315:
		cmp	si,0267h		; V1.13 (1) or V1.15 (1) ?
		jne	EPKLT_chck0305
		mov	ax,ds:[0111h]
		and	ax,02			; add 2 to V1.15 (1) GS
		add	bp,ax
		jmp	EPKLT_SearchGI

EPKLT_chck0305:
		cmp	si,026Ah		; V1.03 (0) or V1.05 (0) ?
		je	EPKLT_chck35
		cmp	si,026Dh		; V1.03 (1) or V1.05 (1) ?
		jne	EPKLT_SearchGI

EPKLT_chck35:
		cmp	byte ptr ds:[0151h],08Ch; V1.05 ?
		jne	EPKLT_SearchGI
		add	bp,2			; add 2 to V1.05's (0,1) GS

EPKLT_SearchGI:
		mov	si,0178h
		mov	ax,0380h
		mov	di,offset GI_ESDIBX
		mov	cx,GI_ESDIBXSz
		call	FindCode		; search GI
		mov	dx,si
		jc	EPKLT_exit

		mov	si,017Fh
		mov	ax,038Dh
		mov	di,offset PkQTSig
		mov	cx,G1QTSz
		call	FindCode		; search QT
		jc	EPKLT_exit
		push	dx
EPKLT_ReSearch:
		mov	dx,si
		inc	si
		call	FindCode
		jnc	EPKLT_ReSearch

		mov	bx,bp
		pop	cx
		mov	si,offset PkIDData
		call	eIndexedId

		cmp	si,offset EPKLT_NoFix	; pklite V1.00á page bugs?
		ja	EPKLT_CheckHdr
		inc	SwitchLforced		; fix memory bug
		cmp	ExeOverlaySz+2,0
		jne	EPKLT_CheckHdr
		cmp	ExeOverlaySz,512
		jne	EPKLT_CheckHdr
		inc	SwitchGforced		; fix overlay bug
EPKLT_CheckHdr:
		cmp	si,offset EPKLT_HaveHdr
		jb	EPKLT_go
		mov	HeaderBuild,offset HBPKLT
		cmp	si,offset EPKLT_AVPACK
		ja	EPKLT_go
		mov	HeaderBuild,offset HBAVPK
EPKLT_go:
		mov	si,offset ACT_decomp
		jmp	SetBreakpoints


HBPKLT:		ASSUME	ds:NOTHING,es:NOTHING
		mov	es,SegData
		ASSUME	es:DGROUP
		mov	ds,SegEHInfo.A
		ASSUME	ds:NOTHING
		mov	ax,ds:[RelocOffs]
		sub	ax,1Ch
		sub	ax,SegEHToItems.S
		mov	si,ax
		mov	dx,SegEHAfter.S
		cmp	dx,1Ah
		jl	HBPKLT_NoHeader
		mov	ds,SegEHAfter.A
		sub	si,2			; missing 'MZ' signature
		call	CheckHeader
		jne	HBPKLT_Invalid
		inc	HeaderStored
		mov	es,SegEHInfo.A
		ASSUME	es:NOTHING
		push	si			; offset header
		add	si,2
		mov	di,2
		mov	cx,1Ah /2
		repnz	movsw
		pop	si
		mov	ax,ds:[si+HeaderSz]
		mov	cl,4
		shl	ax,cl
		call	ForceAllign
		mov	cx,ds:[si+RelocOffs]
		sub	cx,2
		cmp	ds:[si+RelocItemsCnt],0
		jne	MoveRest
		xchg	cx,dx
MoveRest:
		push	ds
		push	si
		mov	ds,SegData
		ASSUME	ds:DGROUP
		sub	cx,1Ah
		mov	es,SegEHToItems.A
		ASSUME	es:NOTHING
		call	FreeMem
		mov	bx,cx
		shr	bx,4
		inc	bx
		mov	si,offset ME_Header
		call	AllocateMem
		mov	SegEHToItems.A,ax
		mov	SegEHToItems.S,cx
		mov	SegEHAfter.S,0		; will be automaticly freed
		mov	es,ax
		ASSUME	es:NOTHING
		xor	di,di
		pop	si
		add	si,1Ch
		pop	ds
		ASSUME	ds:NOTHING
		repnz	movsb
		push	ds
		pop	es
		call	FreeMem
		jmp	UpdateHeader

HBPKLT_Invalid:
		mov	si,offset WAR_header
		call	Warning
HBPKLT_NoHeader:
		jmp	HBCreate

HBAVPK:		ASSUME	ds:NOTHING,es:NOTHING
		mov	es,SegData
		ASSUME	es:DGROUP
		mov	ds,SegEHAfter.A
		ASSUME	ds:NOTHING
		mov	si,20h-1Ch
		call	CheckHeader
		jne	HBPKLT_Invalid
		push	es
		mov	es,SegEHInfo.A
		ASSUME	es:NOTHING
		xor	di,di
		mov	cx,1Ch/2
		repnz	movsw
		mov	ax,es:[HeaderSz]
		mov	cl,4
		shl	ax,cl
		call	ForceAllign
		pop	es
		ASSUME	es:DGROUP
		cmp	NrRelocFound,0
		je	HBAVPK_NoItem
		mov	bx,ds:[20h-1Ch+RelocOffs]
		sub	bx,1Ch
		push	bx
		mov	cl,4
		shr	bx,cl
		inc	bx
		mov	si,offset ME_Header
		call	AllocateMem
		pop	cx
		mov	SegEHToItems.A,ax
		mov	SegEHToItems.S,cx
		mov	SegEHAfter.S,0
		mov	ds,SegEHAfter.A
		ASSUME	ds:NOTHING
		mov	es,ax
		ASSUME	es:NOTHING
		mov	ax,4
		xor	di,di
		mov	si,20h
HBAVPK_copy:
		jcxz	HBAVPCK_fill
		movsb
		dec	ax
		jnz	HBAVPK_copy
HBAVPCK_fill:
		mov	al,0
		repnz	stosb
		jmp	HBAVPK_done


HBAVPK_NoItem:	ASSUME	es:DGROUP
		mov	SegEHAfter.S,4
		mov	ds,SegEHAfter.A
		ASSUME	ds:NOTHING
		push	ds
		pop	es
		ASSUME	es:NOTHING
		mov	si,20h
		xor	di,di
		movsw
		movsw

HBAVPK_done:
		jmp	UpdateHeader

.data
PkSig label
		mov	ds:word ptr [005Ch],4B50h
PkSigSz		EQU	$ - offset PkSig - 2


PkIDData label word
dw 026Dh, 027Fh, 0286h, PKLITE, _V1_00B, __S_       		, 0
dw 030Bh, 031Dh, 0324h, PKLITE, _V1_00B, __L_       		, 0
EPKLT_NoHdr label
dw 0270h, 0285h, 0290h, PKLITE, _V1_00B, __e, __L_ 		, 0
EPKLT_NoFix label
dw 026Dh, 0280h, 028Bh, PKLITE, _V1_00, _or, _V1_03, __e, __S_  , 0
dw 0316h, 032Ah, 0335h, PKLITE, _V1_03, __e, __L_  		, 0
dw 026Fh, 0280h, 028Bh, PKLITE, _V1_05, __e, __S_   		, 0
dw 0303h, 0316h, 0321h, PKLITE, _V1_10, __e, __L_   		, 0
dw 0269h, 027Ch, 0287h, PKLITE, _V1_12, __e, __S_   		, 0
dw 0310h, 0324h, 032Fh, PKLITE, _V1_12, __e, __L_   		, 0
dw 026Ah, 027Eh, 0289h, PKLITE, _V1_13, __e, __S_   		, 0
dw 0311h, 0324h, 032Fh, PKLITE, _V1_13, __e, __L_		, 0
dw 0286h, 029Ah, 02A5h, PKLITE, _V1_15, __e, __S_   		, 0
dw 032Dh, 0340h, 034Bh, PKLITE, _V1_15, __e, __L_   		, 0
dw 0249h, 025Ah, 0266h, PKLITE, _V1_20, __e, __S_   		, 0
dw 0259h, 026Ch, 0278h, PKLITE, _V1_20, __e, __S_   		, 0
dw 0328h, 033Eh, 0349h, PKLITE, _V1_20, __e, __L_   		, 0
dw 036Ah, 0380h, 038Dh, PKLITE, _V1_50, __e, __L_		, 0

dw 0167h, 017Ah, 0181h, MEGALITE, _V1_18a			, 0
dw 0165h, 0178h, 017Fh, MEGALITE, _V1_20a			, 0

EPKLT_HaveHdr label
dw 017Fh, 01AAh, 01BAh, AVPACK, _V1_20				, 0
EPKLT_AVPACK label				; 1 file with AVPACK header

dw 01DFh, 020Ah, 021Ah, AVPACK, _V1_20, __E			, 0
dw 01EEh, 0219h, 0229h, AVPACK, _V1_20, __R			, 0

dw 026Ah, 027Ch, 0283h, PKLITE, _V1_00, _or, _V1_03,  __S_	, 0
dw 0313h, 0324h, 032Bh, PKLITE, _V1_00, __L_        		, 0
dw 0313h, 0326h, 032Dh, PKLITE, _V1_03, __L_        		, 0
dw 026Ch, 027Ch, 0283h, PKLITE, _V1_05, __S_        		, 0
dw 0311h, 0324h, 032Bh, PKLITE, _V1_05, __L_        		, 0
dw 0266h, 0278h, 027Fh, PKLITE, _V1_12, __S_        		, 0
dw 030Dh, 0320h, 0327h, PKLITE, _V1_12, __L_        		, 0
dw 0267h, 027Ah, 0281h, PKLITE, _V1_13, __S_        		, 0
dw 030Eh, 0320h, 0327h, PKLITE, _V1_13, __L_        		, 0
dw 0265h, 0278h, 027Fh, PKLITE, _V1_14, __S_        		, 0
dw 030Ch, 031Eh, 0325h, PKLITE, _V1_14, __L_        		, 0
dw 0269h, 027Ah, 0281h, PKLITE, _V1_15, __S_        		, 0
dw 0310h, 0322h, 0329h, PKLITE, _V1_15, __L_        		, 0
dw 0277h, 028Ah, 0292h, PKLITE, _V1_50, __S_        		, 0
dw 02ADh, 02C0h, 02C8h, PKLITE, _V1_50, __c, __S_      		, 0
dw 0320h, 0332h, 033Ah, PKLITE, _V1_50, __L_        		, 0
dw 0    , 0    , 0    , LB, PKLITE, RB				, 0 ; B

PkDcdr label
		lodsw
		xchg	dx,ax
		add	ax,dx
		stosw
		db	0EBh
PkDcdrSz		equ	$ - PkDcdr

PkDcdr2 label
		lodsw
		xchg	dx,ax
		xor	ax,dx
		stosw
		db	0EBh
PkDcdr2Sz		equ	$ - PkDcdr2

PkGSSig label
		mov	bp,bx
		add	bx,0010h
PkGSSz		equ	$ - PkGSSig

PkGS2Sig label
		mov	bx,ss
		push	es
		mov	dx,bx
PkGS2Sz		equ	$ - PkGS2Sig

PkGS3Sig label					; found on PKLITE V1.50 -e
		db	8Bh,0DDh		; mov    bx,bp
		db	90h			; nop
		db	83h,0C3h,10h		; add    bx,0010
PkGS3Sz		equ	$ - PkGS3Sig

;signature below is moved to GI.ASM
;GI_ESDIBX label
;		add	es:[di],bx
;GI_ESDIBXSz	equ	$ - GI_ESDIBX

PkQTSig label
		lodsw
		add	ax,bx
;		mov	si,ax
;		mov	di,ax
;		retf
PkQTSz		equ	$ - PkQTSig
