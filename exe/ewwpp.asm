; /**/
; /*
;    filename    : EWWPP.ASM
;    created by  : Ben Castricum
;    created on  : 27-Dec-1994
;    handles     : WWPACK V3.00, V3.01 and V3.02
;    last update : 18-Apr-1995
;    status      : finished
;
;    revision history :
; 26-Feb-1995 : Changed QT to 019D for P routines
; 18-Apr-1995 : added WWPACK V3.02
;									   */
;									 /**/

.code
EWWPP_entry:	ASSUME	ds:NOTHING, es:NOTHING
		mov	es,SegData
		ASSUME	es:DGROUP
		mov	ds,RegCS
		ASSUME	ds:NOTHING
		mov	si,RegIP
		add	si,41h
		lea	ax,[si+1]
		mov	di,offset EWWPPSh
		mov	cx,EWWPPShSz
		call	FindCode
		jne	EWWPP_CheckPR

		lea	bx,[si+1]
		call	Break
		call	Trace
		call	Trace
		mov	ds,RegCS

		mov	si,018Dh
		mov	ax,019Dh
		mov	di,offset EWWPPSh2
		mov	cx,EWWPPShSz2
		call	FindCode
		jne	EWWPP_exit

		mov	bx,si
		mov	cx,-1
		mov	dx,si
		mov	si,offset WWPPid
		call	eIndexedId
		mov	si,offset ACT_decomp
		inc	SwitchAforced
		jmp 	SetBreakpoints


EWWPP_CheckPR:
		mov	si,RegIP
		add	si,1Fh-3
		lea	ax,[si+4]
		mov	di,offset GI_DIDX
		mov	cx,GI_DIDXSz
		call	FindCode		; search GI
		jne	EWWPP_exit
		mov	bp,si
; V3.02 uses a more optimized relocation routine. As a result, the segment
; override used in V3.01 and V3.00 has been elimited.
		mov	al,ds:[si-1]
		cmp	al,26h			; segment override?
		jne	EWWPP_SearchQT
		dec	bp

EWWPP_SearchQT:
		mov	si,RegIP
		add	si,43h-3
		lea	ax,[si+4]
		mov	di,offset EWWPPRS
		mov	cx,EWWPPRSz
		call	FindCode		; search QT
		mov	dx,si
		jne	EWWPP_exit

		mov	si,RegIP
		lea	bx,[si+3]
		mov	cx,bp
		mov	ExeSizeAdjust,si
		dec	ExeSizeAdjust		; for V3.02 : -1
		sub	bx,si
		sub	cx,si
		sub	dx,si
		cmp	cx,1Fh
		jne	EWWP_DoID
		dec	ExeSizeAdjust		; for V3.00 and V3.01 : -2
EWWP_DoID:

		push	si
		mov	si,offset WWPPid
		call	eIndexedId
		pop	si

		add	bx,si
		add	cx,si
		add	dx,si

		mov	GetProgSize,offset GS_CS00

		mov	si,offset ACT_fixups
		jmp	SetBreakpoints

EWWPP_exit:
		ret

.data
WWPPid label word
dw 019Dh, -001h, 019Dh, WWPACK, _V3_0, _or, _V3_01, _P               , 0
dw 0003h, 001Fh, 0044h, WWPACK, _V3_0, _or, _V3_01, _PR              , 0
dw 018Dh, -001h, 018Dh, WWPACK, _V3_02, _or, _V3_02a, _P, __S_       , 0
dw 0196h, -001h, 0196h, WWPACK, _V3_02, _or, _V3_02a, _P, __L_       , 0
dw 0003h, 001Ch, 0040h, WWPACK, _V3_02, _or, _V3_02a, _PR            , 0
dw 0000h, 0000h, 0000h, LB, WWPACK, RB, 0

EWWPPSh label
; first two lines removed to detect WWPACK V3.02
;		db	0B7h,10h		; mov    bh,10
;		db	36h,0C6h,6,2,1,0FFh	; mov    ss:byte ptr [0102],FF
		db	0ADh			; lodsw
		db	95h			; xchg   bp,ax
		db	0CBh			; retf
EWWPPShSz	equ	$ - offset EWWPPSh

EWWPPSh2 label
		db	1Fh			; pop    ds
		db	7			; pop    es
		db	0CBh			; retf
EWWPPShSz2	equ	$ - offset EWWPPSh2


EWWPPRS label
		db	8Eh,0D2h		; mov    ss,dx
		db	0FBh			; sti
EWWPPRSz	equ	$ - EWWPPRS

GI_DIDX label
		db	1,15h			; add    [di],dx
GI_DIDXSz	equ	$ - GI_DIDX

