; CSPCM.ASM
; last update : 17-Apr-1994

.code
CSPCM_entry:	ASSUME	ds:NOTHING, es:NOTHING
		mov	es,SegData
		ASSUME	es:DGROUP
		mov	ds,RegCS
		ASSUME	ds:NOTHING
		mov	si,0100h
		mov	di,offset CSPCMs
		mov	cx,CSPCMl
		repz	cmpsb
		jne	CSPCM_exit

		mov	ax,RegCS
		add	ax,10h
		add	ax,ds:[010Ah]
		mov	si,ds:[010Eh]
		mov	ds,ax

		mov	si,0D9h			; check GS
		mov	ax,0F3h
		mov	di,offset CSPCM2s
		mov	cx,CSPCM2l
		call	FindCode
		jne	CSPCM_exit
		mov	bx,si

		mov	si,00AEh		; check GI
		mov	ax,00C8h
		mov	di,offset CSPCM3s
		mov	cx,CSPCM3l
		call	FindCode
		jne	CSPCM_exit
		mov	bp,si

		mov	si,0120h		; check QT
		mov	ax,013Ah
		mov	di,offset CSPCM4s
		mov	cx,CSPCM4l
		call	FindCode
		jne	CSPCM_exit
		add	si,3

		mov	cx,bp
		mov	dx,si

		mov	si,offset CSPCMidData
		call	eIndexedId

		mov	si,offset ERR_unable
		call	Error
		jmp 	Continue

		inc	ExeSizeAdjust
		mov	si,offset ACT_decomp
		jmp	SetBreakpoints

CSPCM_exit:
		ret

.data
CSPCMs label
		db	9Ch			; pushf
		db	55h			; push   bp
		db	56h			; push   si
		db	8Ch,0CDh		; mov    bp,cs
		db	83h,0C5h,10h		; add    bp,0010
		db	8Dh,0B6h		; lea    si,[bp+....]
CSPCMl		equ	$ - offset CSPCMs

CSPCM2s label
		db	0FDh			; std
		db	16h			; push   ss
		db	51h		        ; push   cx
		db	0CBh			; retf
CSPCM2l		equ	$ - offset CSPCM2s

CSPCM3s label
		db	26h,08Bh,15h		; mov    dx,es:[di]
		db	0ABh			; stosw
CSPCM3l		equ	$ - offset CSPCM3s

CSPCM4s label
		db	0B8h,34h,12h		; mov    ax,1234
		db	0EAh			; jmp far
CSPCM4l		equ	$ - offset CSPCM4s

CSPCMidData label
dw 00D9h, 00AEh, 0123h, SPACEMAKER, _V1_03, 0
dw 00F3h, 00C8h, 013Ah, LB, SPACEMAKER, RB, 0
dw 0000h, 0000h, 0000h, LB, SPACEMAKER, RB, 0
;dw LB, SPACEMAKER, _V1_03, 0