; CICE.ASM
; last update : 20-Mar-1994
;
; 20-Mar-1994: changed code to take advantage of final size overide code

.code
CICE_entry:	ASSUME	ds:NOTHING, es:NOTHING
		mov	es,SegData
		ASSUME	es:DGROUP
		mov	ds,RegCS
		ASSUME	ds:NOTHING

		mov	di,offset CICEs
		mov	si,010Ch
		mov	cx,CICEl
		repz	cmpsb
		jne	CICE_exit
		mov	si,offset CICE_ver
		call	WriteVersion
		mov	bx,0124h
		call	Break
		mov	bx,0126h
		call	Break
		mov	bx,0170h
		call	Break
		mov	bx,ds:[010Ah]
		add	bx,0Eh
		mov	ProgFinalOfs,-3
		mov	si,offset ACT_decomp
		jmp	HandleCom
CICE_exit:
		ret

.data
CICEs label
	dw	9918,35585,35838,2062,35585,534,47105,375,64592,13229,43970
	dw	53387,63714
CICEl  		equ	$ - offset CICEs

CICE_ver label
dw ICE, _V1_00, 0