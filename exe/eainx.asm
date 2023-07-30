; /**/
; /*
;    filename    : EAINX.ASM
;    created by  : Ben Castricum
;    created on  : ?
;    handles     : AINEXE V2.1
;    last update : 5-May-1994
;    status      : completed
;    comments    : AINEXE is encryption program for .EXE files only.
;									   */
;									 /**/

.code
EAINX_entry:	ASSUME	ds:NOTHING, es:NOTHING	; assume nothing on entry
		mov	es,SegData
		ASSUME	es:DGROUP
		mov	ds,RegCS
		ASSUME	ds:NOTHING

		mov	si,RegIP
		mov	di,offset EAINX_C1
		mov	cx,EAINX_C1l
		repz	cmpsb
		je	EAINX_DoId
		ret

EAINX_DoId:
		mov	si,offset EAINX_ver
		call	WriteVersion

		inc	SwitchLforced

		mov	bx,280h
		call	Break
		mov	ds,RegCS

		mov	bx,131h
		mov	cx,166h
		mov	dx,0EFh
		mov	si,offset ACT_remencrypt
		jmp	SetBreakpoints

.data
EAINX_C1 label
		db	0A1h,2,0		; mov    ax,[0002]
		db	2Dh,0E1h,0Bh		; sub    ax,0BE1
		db	8Eh,0D0h		; mov    ss,ax
		db	0BCh,0,0BEh		; mov    sp,BE00
		db	8Ch,0D8h		; mov    ax,ds
		db	36h,0A3h,0,0BEh		; mov    ss:[BE00],ax
EAINX_C1l 	equ	$ - offset EAINX_C1

EAINX_ver label
dw AINEXE, _V2_1, 0
