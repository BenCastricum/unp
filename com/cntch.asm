; CNTCH.ASM
; last update : 21-Mar-1994
;
; 21-Mar-1994: changed code to take advantage of final size overide code

.code
CNTCH_entry:	ASSUME	ds:NOTHING, es:NOTHING
		mov	es,SegData
		ASSUME	es:DGROUP
		mov	ds,RegCS
		ASSUME	ds:NOTHING

		mov	ax,ds:[0104h]
		mov	CNTCHadj,ax
		mov	di,offset CNTCHs
		mov	cx,CNTCHl
		mov	si,0100h
		repz	cmpsb
		jne	CNTCH_exit
		add	ax,RegCS
		mov	ds,ax
		ASSUME	ds:NOTHING
		mov	si,0100h
		mov	di,offset CNTCH2s
		mov	cx,CNTCH2l
		repz	cmpsb
		jne	CNTCH_exit
CNTCH_retf:
		inc	si			; search for retf
		cmp	byte ptr ds:[si],0CBh
		jne	CNTCH_retf

		lea	bx,[si-1]
		mov	ax,offset CNTCHver
		call	cIndexedId
		mov	ax,CNTCHadj
		mov	cl,4
		shl	ax,cl
		inc	ah
		mov	ProgFinalOfs,ax
		dec	ProgFinalSeg
		mov	si,offset ACT_removeintro
		jmp	HandleCom

CNTCH_exit:
		ret

.data
CNTCHver label
dw  0h,	LB, UNTOUCHABLES, RB, 0

CNTCHs label
		push	cs
		db	8Ch,0C8h		; mov ax,cs
		db	5			; add ax,CONST
CNTCHadj	dw	0
		push	ax
		mov	ax,0100h
		push	ax
		retf
CNTCHl		equ	$ - offset CNTCHs

CNTCH2s label
		pop	es
		mov	di,100h
		push	es
		push	di
		push	cs
		pop	ax
CNTCH2l		equ	$ - offset CNTCH2s