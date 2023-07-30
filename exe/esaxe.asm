; ESAXE.ASM
; last update	: 15-MAY-1993

.code
ESAXE_entry:	ASSUME	ds:NOTHING, es:NOTHING
		mov	es,SegData
		ASSUME	es:DGROUP
		mov	ds,RegCS
		ASSUME	ds:NOTHING

		mov	si,0322h
		mov	ax,0408h
		mov	di,offset ESAXEgs
		mov	cx,ESAXEgsl
		call	FindCode
		jne	ESAXE_exit
		mov	bx,si

		mov	si,017Eh
		mov	ax,01B6h
		mov	di,offset ESAXEqt
		mov	cx,ESAXEqtl
		call	FindCode
		jne	ESAXE_exit
		mov	dx,si

		mov	si,0150h
		mov	ax,017Ch
		mov	di,offset GI_ESBXDX
		mov	cx,GI_ESBXDXSz
		call	FindCode
		jne	ESAXE_exit


		inc	SwitchRforced		; do not copy overlay
		mov	cx,si

		mov	si,offset ESAXEid
		call	eIndexedId

		mov	ExpectedInts,offset ESAXE_ints

		mov	si,offset ACT_decomp
		jmp	SetBreakpoints

ESAXE_exit:
		ret



.data

ESAXEid label word
dw 0408h, 017Ch, 01B6h, AXE, _V2_2		, 0
dw 0322h, 0150h, 017Eh, LB, AXE, RB		, 0
dw 0    , 0    , 0    , LB, AXE, RB		, 0


ESAXE_ints label
		db	1Ah			; Set DTA
		db	30h			; get dos version
		db	3Dh			; open file
		db	42h			; move file pointer
		db	3Eh			; close file
		db	3Fh			; read from file
		db	0

ESAXEgs label
		db	0E8h,0D3h,0		; call   04DE
		db	8Ch,0C0h		; mov    ax,es
		db	40h			; inc    ax
		db	1Fh			; pop    ds
		db	7			; pop    es
ESAXEgsl	        equ	$ - ESAXEgs

GI_ESBXDX label
		db	26h,1,17h		; add    es:[bx],dx
GI_ESBXDXSz     equ	$ - GI_ESBXDX

ESAXEqt label
		db	8Eh,0D8h		; mov    ds,ax
		db	8Eh,0C0h		; mov    es,ax
		db	0B4h,1Ah		; mov    ah,1A
		db	0BAh,80h,0		; mov    dx,0080
		db	0CDh,21h		; int    21
ESAXEqtl	        equ	$ - ESAXEqt

