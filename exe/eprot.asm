; EPROT.ASM
; last update : 26-Apr-1994
;

.code
EPROT_entry:	ASSUME	ds:NOTHING, es:NOTHING
		mov	es,SegData
		ASSUME	es:DGROUP
		mov	ds,RegCS
		ASSUME	ds:NOTHING
		mov	si,RegIP
		lodsb
		cmp	al,0E8h
		jne	EPROT_check30
		lodsw
		add	si,ax
		mov	di,offset EPROT10s
		mov	cx,EPROT10l
		repz	cmpsb
		jne	EPROT_exit
		lodsb
		cmp	al,0BEh
		je	EPROT_v2
		mov	bx,10h
		cmp	byte ptr ds:[0DCh],0C6h
		jne	EPROT_v1
		inc	bx
EPROT_v1:
		mov	ax,offset CPROTiid
		call	cIndexedId
		mov	bx,61h
		mov	cx,-1			; no GI
		mov	dx,128h
		mov	si,offset ACT_remencrypt
		jmp	SetBreakpoints

EPROT_v2:
		mov	bx,20h
		mov	ax,offset CPROTiid
		call	cIndexedId
		mov	bx,013Ah
		call	Break
		mov	bx,61h
		mov	cx,-1			; no GI
		mov	dx,15Ch
		mov	si,offset ACT_remencrypt
		jmp	SetBreakpoints

EPROT_check30:
		mov	si,RegIP
		mov	di,offset EPROT30s
		mov	cx,EPROT30l
		repz	cmpsb
		jne	EPROT_check40

		mov	bx,30h
		cmp	byte ptr ds:[04Ah],026h	; v3.0 ?
		je	EPROT_v3
		inc	bx			; v3.1
EPROT_v3:
		mov	ax,offset CPROTiid
		call	cIndexedId
		mov	bx,01FFh
		call	Break
		mov	bx,0129h		; GS
		mov	cx,-1			; no GI
		mov	dx,01D1h		; QT
;		mov	QTRoutine,offset QTEProt30
		mov	si,offset ACT_remencrypt
		jmp	SetBreakpoints

EPROT_check40:	ASSUME	ds:NOTHING, es:NOTHING
		mov	es,SegData
		ASSUME	es:DGROUP
		mov	ds,RegCS
		ASSUME	ds:NOTHING
		mov	si,RegIP
		mov	di,offset EPROT40s
		mov	cx,EPROT40l
		repz	cmpsb
		jne	EPROT_check50
		mov	bx,40h
		mov	ax,offset CPROTiid
		call	cIndexedId
		mov	si,offset ACT_remencrypt
		call	Action
		mov	bx,16h
		call	Break
		mov	bx,14h
		call	Break
		mov	bx,19h
		call	Break
		xor	cx,cx
EPROT_trace4:
		call	Trace
		mov	ds,RegCS
		mov	si,RegIP
		lodsb
		cmp	al,0CBh
		je      EPROT_4retf
		cmp	al,0E2h
		jne	EPROT_trace4
		dec	si
		cmp	si,cx
		je	EPROT_checkloop
		mov	cx,si
		xor	bp,bp
		jmp	EPROT_trace4
EPROT_checkloop:
		inc	bp
		cmp	bp,3
		jne	EPROT_trace4
		lea	bx,[si+2]
		call	Break
		jmp	EPROT_trace4

EPROT_4retf:
		call	Trace
		mov	ds,RegCS
		mov	si,RegIP
		mov	di,offset EPROT40s2
		mov	cx,EPROT40l2
		repz	cmpsb
		jne	EPROT_trace4

		mov	bx,0240h
		call	Break
		mov	bx,0189h
		mov	cx,0121h
		mov	dx,0136h
		xor	si,si
		jmp	SetBreakpoints

EPROT_check50:
		mov	si,RegIP
		mov	di,offset EPROT50s
		mov	cx,EPROT50l
		repz	cmpsb
		jne	EPROT_exit

		lodsb
		dec	si
		and	al,0F0h
		cmp	al,0B0h
		jne	EPROT_exit
		mov	cx,2Eh
EPROT_scan:
		lodsw
		dec	si
		cmp	ax,01EBh		; jmp +1 ?
		je	EPROT_add1
		cmp	ax,04EBh		; jmp +4 ?
		je	EPROT_Sig2
		cmp	ax,0E450h		; push ax ; in al,
		je	EPROT_Sig3
		cmp	cx,15h
		jnl	EPROT_next
		cmp	ax,0274h
		je	EPROT_Is50
		cmp	al,75h
		jne	EPROT_next
		cmp	ah,80h
		ja	EPROT_Is50

EPROT_next:
		loop	EPROT_scan
		jmp	EPROT_exit

EPROT_Sig2:
		cmp	[si+2],ax		; jmp +4 ?
		je	EPROT_add8
		jmp	EPROT_next
EPROT_Sig3:
		cmp	[si+1],5021h		; 21h; push ax
		jne	EPROT_next
EPROT_add1A:
		add	si,12h
EPROT_add8:
		add	si,7
		dec	cx
EPROT_add1:
		inc	cx
		inc	si
		jmp	EPROT_scan

EPROT_Is50:
		sub	bp,2

		mov	bx,50h
		mov	ax,offset CPROTiid
		call	cIndexedId
EPROT_trace:
		call	Trace
		mov	si,RegIP
		lodsw
		cmp	ax,274h			; jne +2 ?
		jne	EPROT_checkJe
		lodsw
EPROT_checkCall:
		lodsw
		cmp	ax,0E8h			; call +0 ?
		jne	EPROT_exit
		sub	si,2			; back to call +0
		jmp	EPROT_gotCall
EPROT_checkJe:
		cmp	al,75h			; je?
		jne	EPROT_trace
		cmp	ah,80h			; backwards je ?
		jb	EPROT_exit
		jmp	EPROT_checkCall

EPROT_gotCall:
		mov	bx,si
		call	Break
		add	bx,10Eh-7Eh
		mov	al,[bx]
		and	ax,1
		xor	al,1
		add	bx,ax
		call	Break
		sub	bx,ax
		add	bx,204h-10Eh
		lea	cx,[bx+02CDh-0204h]
		lea	dx,[bx+0305h-0204h]
EPROT_go:
		mov	si,offset ACT_remencrypt
		jmp	SetBreakpoints
EPROT_exit:
		ret

.data

EPROT10s label
		db	1Eh			; push	ds
		db	06h			; push	es
		db	08Ch,0C8h		; mov	ax,cs
		db	08Eh,0D8h		; mov	ds,ax
		db	08Eh,0C0h		; mov	es,ax
EPROT10l	equ	$ - offset EPROT10s

EPROT30s label
		mov	cs:[0000],ax
		mov	ax,ds
		mov	cs:[0002],ax
		mov	ax,cs
		mov	cs:[0006],ax
EPROT30l	equ	$ - offset EPROT30s

EPROT40s label
		db	8Ch,0DBh		; mov	bx,ds
		db	0Eh			; push	cs
		db	0Eh			; push	cs
		db	1Fh			; pop	ds
		db	7			; pop	es
		db	0B9h			; mov	cx,
EPROT40l	equ	$ - offset EPROT40s

EPROT40s2 label
		db	08Ch,0D0h		; mov	ax,ss
		db	0A3h,6Ch,0		; mov	[006C],ax
		db	89h,26h,6Eh,0		; mov	[006E],sp
		db	0A1h,2,0		; mov	ax,[0002]
		db	2Dh,10h,0		; sub	ax,0010
		db	8Ch,0CAh		; mov	dx,cs
		db	0FAh			; cli
EPROT40l2	equ	$ - offset EPROT40s2

EPROT50s label
		db	1Eh			; push	ds
		db	0Eh			; push	cs
		db	0Eh			; push	cs
		db	1Fh			; pop	ds
		db	07h			; pop	es
EPROT50l		equ	$ - offset EPROT50s
