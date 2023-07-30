; CSYRN.ASM
; last update : 21-Mar-1994
;
; 21-Mar-1994 ; changed code to take advantage of final size overide code

.code
CSYRN_entry:	ASSUME	ds:NOTHING, es:NOTHING
		mov	es,SegData
		ASSUME	es:DGROUP
		mov	ds,RegCS
		ASSUME	ds:NOTHING

		mov	di,offset CSYRNs
		mov	cx,CSYRNl
		mov	si,0110h
		repz	cmpsb
		jne	CSYRN_exit

		mov	ax,ds:[010Eh]
		push	ax
		add	ax,RegCS
		mov	ds,ax
		ASSUME	ds:NOTHING
		xor	si,si
		mov	di,offset CSYRN2s
		mov	cx,CSYRN2l
		repz	cmpsb
		pop	di
		jne	CSYRN_exit

		mov	si,offset CSYRNver
		call	WriteVersion
		mov	cl,4
		shl	di,cl
		mov	bx,0043h
		mov	ProgFinalOfs,di
		dec	ProgFinalSeg

		mov	si,offset ACT_remavirus
		jmp	HandleCom

CSYRN_exit:
		ret

.data
CSYRNver label
dw SYRINGE, 0

CSYRNs label
		push	ax
		xor	ax,ax
		push	ax
		retf
CSYRNl		equ	$ - offset CSYRNs

CSYRN2s label
		pop	cs:word ptr [0100h]
		pop	cs:word ptr [00DFh]
		push	cs:word ptr [00DFh]
		mov	bp,0100h
		push	bp
		push    ax
		mov	cs:[00DBh],ss
		mov	cs:[00DDh],sp
		mov	ax,cs
		mov	ss,ax
CSYRN2l		equ	$ - offset CSYRN2s


