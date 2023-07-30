; checks for Optlink

.code
EOPTL_entry:	ASSUME	ds:NOTHING, es:DGROUP
		mov	es,SegData
		ASSUME	es:DGROUP
		mov	ds,RegCS
		ASSUME	ds:NOTHING
		mov	ax,018Dh
		mov	si,0158h
		mov	di,offset EOPTLS
		mov	cx,EOPTLSSz
		call	FindCode
		jne	EOPTL_check1

		push	si
		mov	bx,2
		mov	ax,offset EOPTL_iid
		call	cIndexedId
		pop	bx
		mov	cx,-1			; grab reloc routine unused
		lea	dx,[bx+4]
		mov	si,offset ACT_decomp
		inc	SwitchAforced
		jmp	SetBreakpoints

; /* the first pass exists of a simple RLE compression */
EOPTL_check1:
		mov	si,00AAh
		mov	ax,00BAh
		mov	di,offset EOPTLSgi
		mov	cx,EOPTLSSzgi
		call	FindCode
		jne	EOPTL_exit
		mov	bp,si

		mov	si,0067h
		mov	ax,006Fh
		mov	di,offset EOPTLSqt
		mov	cx,EOPTLSSzqt
		call	FindCode
		jne	EOPTL_exit

		push	bx
		mov	bx,1
		mov	ax,offset EOPTL_iid
		call	cIndexedId
		pop	bx

		mov	bx,si
		mov	cx,bp
		lea	dx,[si+3]
		mov	si,offset ACT_decomp
		jmp	SetBreakpoints

EOPTL_exit:
		ret

.data
EOPTL_iid label
dw 1, OPTLINK, _pass_1, 0
dw 2, OPTLINK, _pass_2, 0

EOPTLS label
		db	5Ah			; pop    dx
		db	83h,0EAh,10h		; sub    dx,0010
		db	8Ch,0C3h		; mov    bx,es
		db	8Eh,0DAh		; mov    ds,dx
		db	8Eh,0C2h		; mov    es,dx
		db    	2Eh,0A1h,9,0		; mov    ax,cs:[0009]
		db	0FAh			; cli
EOPTLSSz		equ	$ - EOPTLS

EOPTLSgi label
		db	26h,87h,5Dh,0FFh	; xchg   es:[di-01],bx
EOPTLSSzgi		equ	$ - EOPTLSgi

EOPTLSqt label
		db	83h,0EAh,10h		; sub    dx,0010
		db	8Eh,0DAh		; mov    ds,dx
		db	8Eh,0C2h		; mov    es,dx
EOPTLSSzqt		equ	$ - EOPTLSqt

