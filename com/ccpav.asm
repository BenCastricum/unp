; CCPAV.ASM
; last update : 19-Apr-1994
;
; 20-Mar-1994: changed code to take advantage of final size overide code
;              noticed bug, fixed
; 17-Apr-1994: added search for endcode
; 19-Apr-1994: skipped first near jump (E9h)

.code
CCPAV_entry:	ASSUME	ds:NOTHING,es:DGROUP
		mov	si,RegIP
		lodsb				; check 2nd instruction
		cmp	al,0E9h			; jmp XXXX ?
		jne	CCPAV_exit
		lodsw
		add	si,ax
		mov	bx,si
		mov	dx,si			; save possible COM length
		mov	di,offset CCPAVs
		mov	cx,CCPAVl
		repz	cmpsb
		jne	CCPAV_exit
		mov	al,[bx+13h]
		push	bx
		mov	bx,ax
		mov	bh,0
		mov	ax,offset CCPAV_iid
		call	cIndexedId
		pop	bx

		lea	si,[bx+17Fh]
		lea	ax,[si+9]
		mov	di,offset CCPAVs2
		mov	cx,CCPAVl2
		call	FindCode		; search endcode
		add	bx,10h
		mov	byte ptr [bx],0E9h	; jmp
		add	bx,3
		push	si
		sub	si,bx
		mov	word ptr [bx-2],si

		pop	bx
		add	bx,9192h-917Fh
		dec	ProgFinalSeg
		mov	ProgFinalOfs,dx
		mov	si,offset ACT_remavirus
		call	HandleCom
CCPAV_exit:
		ret

.data
CCPAVs label
		db	0E8h			; call
		dw	0                       ;      +0
		pop	bx
		sub	bx,0103h
		push	ax
		push	cx
		push	dx
		push	si
		push	di
		push	bp
		mov	bp,bx
CCPAVl		equ	$ - offset CCPAVs

CCPAVs2 label
		db	8Ch,0C8h		; mov    ax,cs
		db	8Eh,0D8h		; mov    ds,ax
		db	8Eh,0C0h		; mov    es,ax
		db	0BEh			; mov	 si,....
CCPAVl2		equ	$ - offset CCPAVs2

CCPAV_iid label
dw 0A2h, CENTRAL_POINT_, ANTI_VIRUS, _V1   , 0
dw 0ABh, CENTRAL_POINT_, ANTI_VIRUS, _V1_1 , 0
dw 0AFh, TURBO_, ANTI_VIRUS, _V7_02A       , 0
dw 000h, LB, ANTI_VIRUS, RB                , 0