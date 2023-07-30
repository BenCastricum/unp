; /**/
; /*
;    filename    : ECPAV.ASM
;    created by  : Ben Castricum
;    created on  : 23-Okt-1994
;    handles     : ELITE V1.00aF
;    last update :  8-Apr-1995
;    status      : completed
;    comments    :
;
;    revision history :
; 08-Apr-1995 : Renamed GI signature
;									   */
;									 /**/

.code
EELIT_entry:	ASSUME	ds:NOTHING, es:NOTHING
		mov	es,SegData
		ASSUME	es:DGROUP
		mov	ds,RegCS		; check for code found in all
		mov	si,RegIP
		lea	ax,[si+23h]
		add	si,23h
		mov	di,offset ELITHeadS
		mov	cx,ELITHeadSSz
		call	FindCode
		je	EELIT_exexp1
EELIT_exit:
		ret

EELIT_exexp1:
		lea	bx,[si+ELITHeadSSz-1]
		call	Break                   ; allow memory copy part
		call	Trace			; do far jmp / retf
		mov	ax,RegIP
		push	ax
		mov	cl,4
		shr	ax,cl
		add	ax,RegCS
		mov	ds,ax
		pop	si
		and	si,000Fh		; ds:si next part
		mov	TempDouble,si

		mov	si,100h
		mov	ax,100h
		mov	di,offset ELITGSS	; search GS
		mov	cx,ELITGSSSz
		call	FindCode
		jc	EELIT_exit
		mov	bx,si
                add	bx,cx

EELIT_GetGI:
		mov	dx,-1
		mov	si,12Ah
		mov	ax,12Ah
		mov	di,offset GI_ESDIBP	; search GI
		mov	cx,GI_ESDIBPSz
		call	FindCode
		jc	EELIT_GetQT
		mov	dx,si
EELIT_GetQT:
		mov	si,175h
		mov	ax,175h
		mov	di,offset ELITQTS	; search QT
		mov	cx,ELITQTSSz
		call	FindCode
		jc	EELIT_exit

						; GS=BX already set
		mov	cx,dx		        ; GI
		mov	dx,si                   ; QT

		mov	ax,TempDouble
		sub	bx,ax
		sub	dx,ax
		sub	cx,ax
EELIT_identify:
		mov	si,offset EELITData
		call	eIndexedId

		mov	ax,TempDouble
		add	bx,ax
		add	dx,ax
		add	cx,ax

		mov	HeaderBuild,offset HBDIET
		mov	si,offset ACT_decomp
		jmp	SetBreakpoints


.data
EELITData label word
dw 00FCh, 0121h, 016Ch, EXELITE, _V1_00aF				,0
dw 0    , 0    , 0    , LB, EXELITE, RB					,0


ELITHeadS label
		db	8Eh,0C3h		; mov    es,bx
		db	8Eh,0D8h		; mov    ds,ax
		db	0BEh,40h,0		; mov    si,0040
		db	33h,0FFh		; xor    di,di
		db	0Eh			; push   cs
		db	0EAh			; jmp far
ELITHeadSSz	equ	$ - ELITHeadS

ELITGSS label
		db	46h			; inc    si
		db	46h			; inc    si
		db	0B6h,10h		; mov    dh,10
		db	0C3h			; ret
ELITGSSSz	equ	$ - ELITGSS

GI_ESDIBP label
		db	26h,1,2Dh		; add    es:[di],bp
GI_ESDIBPSz	equ	$ - GI_ESDIBP

ELITQTS label
		db	33h,0EDh		; xor    bp,bp
		db	33h,0F6h		; xor    si,si
		db	33h,0FFh		; xor    di,di
		db	0EAh
ELITQTSSz	equ	$ - ELITQTS
