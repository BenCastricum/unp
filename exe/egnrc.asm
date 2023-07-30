; /**/
; /*
;    filename    : EGNRC.ASM
;    created by  : Ben Castricum
;    created on  : ?
;    handles     : LZEXE, KVETCH, PROPACK and PACKWIN
;    last update :  8-Apr-1995
;    status      : completed
;    comments    :
;
;    revision history :
; 17-APR-1993 : added Propack V2.14
; 11-AUG-1994 : added unknown version of propack, had to change GS3 a little.
; 08-Apr-1995 : Renamed GI signature
;									   */
;									 /**/

.code
EGNRC_entry:	ASSUME	ds:NOTHING, es:NOTHING
		mov	es,SegData
		ASSUME	es:DGROUP
		mov	ds,RegCS
		ASSUME	ds:NOTHING

		mov	si,00FCh
		mov	ax,0205h
		mov	di,offset G1GSSig
		mov	cx,G1GSSz
		call	FindCode		; search GS
		mov	bp,si
		jnc	EGNRC_GetGI

		mov	si,0172h
		mov	ax,0249h
		mov	di,offset G1GS2Sig
		mov	cx,G1GS2Sz
		call	FindCode		; search GS2
		mov	bp,si
		jc	EGNRC_CheckGS3
		cmp	byte ptr ds:[si-5],0E8h
		jne	EGNRC_GetGI
		sub	bp,5
		jmp	EGNRC_GetGI

EGNRC_CheckGS3:
		mov	si,012Dh
		mov	ax,01E9h
		mov	di,offset G1GS3Sig
		mov	cx,G1GS3Sz
		call	FindCode		; search GS3
		mov	bp,si
		jc	EGNRC_exit
		cmp	byte ptr ds:[si-3],0E8h
		jne	EGNRC_GetGI
		sub	bp,3

EGNRC_GetGI:
		mov	si,011Fh
		mov	ax,021Eh
		mov	di,offset GI_ESDIBX
		mov	cx,GI_ESDIBXSz
		call	FindCode		; search GI
		mov	dx,si
		jnc	EGNRC_GetGI2

		mov	si,014Ah
		mov	ax,0261h
		mov	di,offset GI_ESDIDX
		mov	cx,GI_ESDIDXSz
		call	FindCode		; search GI2
		mov	dx,si
		jc	EGNRC_exit

EGNRC_GetGI2:
		mov	si,0167h
		mov	ax,si
		call	FindCode		; search LZ90 extra GI
		jc	EGNRC_GetQT
		mov	bx,si
		call	SetGI
		cmp	byte ptr ds:[03Fh],74h	; check for "je label"
		jne	EGNRC_GetQT
		mov	byte ptr ds:[03Fh],0EBh ; fix CRC message

EGNRC_GetQT:
		mov	si,0193h
		mov	ax,025Ch
		mov	di,offset G1QTSig
		mov	cx,G1QTSz
		call	FindCode		; search QT
		jnc	EGNRC_go

		mov	si,0155h
		mov	ax,0287h
		mov	di,offset G1QT2Sig
		mov	cx,G1QT2Sz
		call	FindCode		; search QT2
		jnc	EGNRC_go

EGNRC_exit:
		ret

EGNRC_go:
		mov	bx,bp
		mov	cx,dx
		mov	dx,si

		mov	si,offset IDData
		call	eIndexedId
		mov	ExpectedInts,offset EGNRC_ints
		mov	si,offset ACT_decomp
		jmp	SetBreakpoints


.data
EGNRC_ints label
		db	30h			; get DOS version
		db	3Dh			; open file
		db	3Eh			; close file
		db	3Fh			; read from file
		db	0

IDData label word
dw 013Ch, 0154h, 0193h, KVETCH, _V1_02B			 , 0
dw 0205h, 021Dh, 025Ch, LB, KVETCH, RB 			 , 0

dw 0130h, 014Eh, 018Eh, LZEXE, _V0_90  			 , 0
dw 00FCh, 011Fh, 0155h, LZEXE, _V0_91, _or, _V1_00a	 , 0

dw 01A2h, 01BAh, 01E0h, LB, PRO_PACK, RB	   	 , 0
dw 012Eh, 014Ah, 0172h, PRO_PACK, _V2_08, __m1		 , 0
dw 013Ch, 0158h, 0180h, PRO_PACK, _V2_08, __m1, __k	 , 0
dw 0158h, 0177h, 019Fh, PRO_PACK, _V2_08, __m1, __v	 , 0
dw 0166h, 0185h, 01ADh, PRO_PACK, _V2_08, __m1, __k, __v , 0
dw 0172h, 018Ah, 01B0h, PRO_PACK, _V2_08, __m2		 , 0
dw 019Ah, 01B2h, 01D8h, PRO_PACK, _V2_08, __m2, __k	 , 0
dw 0190h, 01ADh, 01D3h, PRO_PACK, _V2_08, __m2, __v	 , 0
dw 01B8h, 01D5h, 01FBh, PRO_PACK, _V2_08, __m2, __k, __v , 0
dw 0134h, 0150h, 0178h, PRO_PACK, _V2_14, __m1		 , 0
dw 0142h, 015Eh, 0186h, PRO_PACK, _V2_14, __m1, __k	 , 0
dw 01D8h, 01F7h, 021Fh, PRO_PACK, _V2_14, __m1, __v	 , 0
dw 01E6h, 0205h, 022Dh, PRO_PACK, _V2_14, __m1, __k, __v , 0
dw 0178h, 0190h, 01B6h, PRO_PACK, _V2_14, __m2		 , 0
dw 01A0h, 01B8h, 01DEh, PRO_PACK, _V2_14, __m2, __k	 , 0
dw 021Ch, 0239h, 025Fh, PRO_PACK, _V2_14, __m2, __v	 , 0
dw 0244h, 0261h, 0287h, PRO_PACK, _V2_14, __m2, __k, __v , 0

dw 0104h, 012Ch, 016Ch, PACKWIN, _V1_0a                  , 0

dw 0    , 0    , 0    , LB, LZEXE, RB		    	 , 0


G1GSSig label
		push	cs
		pop	ds
		db	0BEh			; mov si,constant
G1GSSz		equ	$ - G1GSSig

G1GS2Sig label
		push	cs
		pop	ds
		xor	ch,ch
		db	0BEh			; mov si,constant
G1GS2Sz 	equ	$ - G1GS2Sig

G1GS3Sig label
		push	ds
		pop	es
		push	cs
		pop	ds
		mov	dx,es
		xor	ch,ch
		db	0BEh			; mov si,constant
G1GS3Sz 	equ	$ - G1GS3Sig

;signature below is moved to GI.ASM
;GI_ESDIBX label
;		add	es:[di],bx
;GI_ESDIBXSz	equ	$ - GI_ESDIBX

GI_ESDIDX label
		add	es:[di],dx
GI_ESDIDXSz 	equ	$ - GI_ESDIDX

G1QTSig label
		db	02Eh,0FFh,02Eh		; jmp far cs:[adress]
G1QTSz		equ	$ - G1QTSig

G1QT2Sig label
		jmp	dword ptr cs:[bx]	; jmp far cs:[bx]
G1QT2Sz 	equ	$ - G1QT2Sig
