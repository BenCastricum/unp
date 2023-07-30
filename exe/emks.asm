; /**/
; /*
;    filename    : EMKS.ASM
;    created by  : Ben Castricum
;    created on  : ?
;    handles     : Unknown compresser
;    last update : 28-Feb-1994
;    status      : completed
;    comments    : Routine found on a Polish anti-virus program called
;		     Mks_vir, written by Marek Sell.
;                  Complete decompression has been implemented as a 2 step
;		     process. First step is the decompression itself, 2nd
;                    is the rebuilding of the relocation table.
;                  Has successfully been tested on V5.03c, V5.05j, V5.06
;                     and V5.08h
;									   */
;									 /**/
; revision history:
; 28-Feb-95 : Divided decompression of this compressor into 2 steps
;               (decompression and fixup rebuilding)
;             Fixed "unknown GI" bug.

.code
EMKS_entry:	ASSUME	ds:NOTHING, es:NOTHING
		mov	es,SegData
		ASSUME	es:DGROUP
		mov	ds,RegCS
		ASSUME	ds:NOTHING
		mov	si,000Fh
		mov	di,offset EMKSS
		mov	cx,EMKSSz
		repz	cmpsb
		jne	EMKS_Reloc

		mov	bx,049Bh
		mov	cx,-1
		mov	dx,04C0h

		mov	si,offset EMKSid
		call	eIndexedId
		mov	si,offset ACT_decomp
		inc	SwitchAforced
		jmp	SetBreakpoints

EMKS_Reloc:
		mov	si,RegIP
		add	si,002Ch
		mov     di,offset EMKS2S
		mov	cx,EMKS2Sz
		repz	cmpsb
		jne     EMKS_exit
		mov	bx,03h
		mov	cx,37h
		mov	dx,49h
		mov	si,offset EMKSid
		call	eIndexedId
		mov	ax,RegIP
		add	bx,ax
		add	cx,ax
		add	dx,ax
		mov	ExeSizeAdjust,ax
		mov	GetProgSize,offset GS_CS00
		mov	si,offset ACT_fixups
		jmp	SetBreakpoints


EMKS_exit:
		ret

.data
EMKSid label
dw 049Bh,   -1h, 04C0h, MKS, _, COMPRESSOR        , 0
dw 0003h, 0037h, 0049h, MKS, _RelocTxt            , 0
dw    0h,    0h,    0h, LB, MKS, _, COMPRESSOR, RB, 0

EMKSS label
		db	1Eh			; push   ds
		db	17h			; pop    ss
		db	0BCh,0,1		; mov    sp,0100
		db	8Ch,0C8h		; mov    ax,cs
		db	3,6,0Ch,1		; add    ax,[010C]
		db	8Eh,0C0h		; mov    es,ax
		db	33h,0FFh		; xor    di,di
EMKSSz		equ 	$ - offset EMKSS

EMKS2S label
		db	26h,8Bh,6Dh,1		; mov    bp,es:[di+01]
		db	3,0E8h			; add    bp,ax
		db	8Eh,0DDh		; mov    ds,bp
		db	83h,0C7h,3         	; add    di,0003
		db	1,7			; add    [bx],ax
EMKS2Sz		equ 	$ - offset EMKS2S