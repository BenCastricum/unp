; /**/
; /*
;    filename    : EUCEX.ASM
;    created by  : Ben Castricum
;    created on  : 27-Apr-1995
;    last update : 27-Apr-1995
;    status      : under development
;    comment     : this routine unpacks UCEXE V2.3
;
; revision history :
; 02-02-97 - Changed removal of integrity check, now skips it entirely
;               in small and larde files.
;									   */
;									 /**/

.code
EUCEX_entry:	ASSUME	ds:NOTHING, es:NOTHING
		mov	es,SegData
		ASSUME	es:DGROUP
		mov	ds,RegCS
		ASSUME	ds:NOTHING

		mov	ax,00A1h
		mov	si,ax
		mov	cx,EUCEXGSSz
		mov	di,offset EUCEXGSs
		call	FindCode
		jne	EUCEX_exit

		mov	ax,00C2h
		mov	si,ax
		mov	cx,GI_ESDICXSz
		mov	di,offset GI_ESDICX
		call	FindCode
		jne	EUCEX_exit

		mov	ax,0126h
		mov	si,ax
		mov	cx,EUCEXQTSz
		mov	di,offset EUCEXQTs
		call	FindCode
		jne	EUCEX_exit

		mov	byte ptr ds:[0013h],0BEh ; skip integrity check
		mov	bx,00A1h
		mov	cx,00C2h
		mov	dx,0126h

		mov	si,offset IDUCEXEId
		call	eIndexedId
		mov	si,offset ACT_decomp
		jmp	SetBreakpoints
EUCEX_exit:
		ret


.data

IDUCEXEId label
dw 00A1h, 00C2h, 0126h, UCEXE, _V2_3   ,0
dw    0h,    0h,    0h, LB, UCEXE, RB  ,0

EUCEXGSs label
		db	2Eh,89h,36h,4Ah,0	; mov    cs:[004A],si

EUCEXGSSz	equ	$ - offset EUCEXGSs

GI_ESDICX label
		add	es:[di],cx
GI_ESDICXSz	equ	$ - offset GI_ESDICX

EUCEXQTs label
		db	2Eh,0FFh,2Eh,8,0	; jmp    cs:far [0008]
EUCEXQTSz	equ	$ - offset EUCEXQTs
