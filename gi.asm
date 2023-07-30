; /**/
; /*
;    filename    : GI.ASM
;    created by  : Ben Castricum
;    created on  : ?
;    purpose     : all functions used to process fixups are in here
;    last update :  8-Apr-1995
;    status      : completed
;    comments    : Items are stored in memory using a linked list; stucture
;                    follows.
;
; 0	word	segment of next block
; 2	word	number of items stored in this block
; 4+		first fixup stored as:
;	word    offset
;	word	segment
;
;    revision history :
; 31-May-1994 : Added -F switch
; 08-Apr-1995 : Added common GI signature
;									   */
;									 /**/

;---------------------------------------------------------------------------;
.code
BreakGI:	ASSUME	ds:NOTHING, es:NOTHING
		push	ds
		mov	ds,SegData
		ASSUME	ds:DGROUP
		pop	RegDS
		mov	RegAX,ax
		mov	RegBX,bx
		mov	RegCX,cx
		mov	RegDX,dx
		mov	RegSI,si
		mov	RegDI,di
		mov	RegES,es
		xor	ax,ax
		xchg	InProgram,al
		mov	InProgramStatus,al
		call	[SetFixupRegs]

		mov	ax,SegItemCur
		mov	es,ax
		ASSUME	es:NOTHING
		or	ax,ax			; first item ?
		jne	GIResolve
		call	GetNewItemBlck
		mov	SegItemCur,es
		mov	SegItemStart,es
		mov	word ptr es:[0],0
		mov	word ptr es:[2],0
GIResolve:
		mov	si,es:[2]		; store item
		shl	si,2
		mov	bx,FixupOfs
		mov	dx,FixupSeg
		sub	dx,SegProgram
		cmp	SwitchF,FALSE
		je	GIStore
		xchg	ax,dx
		mul	ParSize
		add	bx,ax
		adc	dx,0
		mov	cl,12
		shl	dx,cl
		mov	FixupSeg,dx
		cmp	bx,0FFFFh		; segment wrap?
		jne	GIStore
		inc	dx
		sub	bx,10h
GIStore:
		mov	es:[si+4],bx
		mov	es:[si+6],dx
		inc	word ptr es:[2]

		push	es			; get block size
		mov	ax,es
		dec	ax
		mov	es,ax
		ASSUME	es:NOTHING
		mov	cx,es:[3]
		shl	cx,4
		pop	es
		ASSUME	es:NOTHING
		mov	ax,es:[2]
		inc	ax
		shl	ax,2
		cmp	ax,cx			; block full?
		jne	EndGI

		push	es
		call	GetNewItemBlck
		mov	SegItemCur,es
		mov	word ptr es:[0],0
		mov	word ptr es:[2],0
		mov	ax,es
		pop	es
		ASSUME	es:NOTHING
		mov	es:[0],ax
EndGI:
		inc	NrRelocFound
		mov	al,InProgramStatus
		mov	InProgram,al
		mov	ax,RegAX
		mov	bx,RegBX
		mov	cx,RegCX
		mov	dx,RegDX
		mov	si,RegSI
		mov	di,RegDI
		mov	es,RegES
		mov	ds,RegDS
		iret

GetNewItemBlck:
		mov	bx,1
		mov	si,offset ME_Fixups
		call	AllocateMem
		mov	bx,65535/16
		mov	es,ax
		call	ResizeMem
		call	ResizeMem
		ret


GI_DSBX:	ASSUME	ds:DGROUP, es:NOTHING
		mov	ax,RegDS
		mov	FixupSeg,ax
		mov	FixupOfs,bx
		ret

GI_DSDI:	ASSUME	ds:DGROUP, es:NOTHING
		mov	ax,RegDS
		mov	FixupSeg,ax
		mov	FixupOfs,di
		ret

GI_ESDIxchgr:	ASSUME	ds:DGROUP, es:NOTHING
		mov	FixupSeg,es
		mov	al,byte ptr RelItemOfs
		cbw
		add	di,ax
		mov	FixupOfs,di
		mov	ax,RegBX
		sub	ax,SegProgram
		xchg	es:[di],ax
		mov	RegBX,ax
		ret

GI_ESDIxchg:    ASSUME	ds:DGROUP, es:NOTHING
		mov	ax,RegAX
		sub	ax,SegProgram
		xchg	es:[di],ax
		mov	RegAX,ax

GI_ESDI:	ASSUME	ds:DGROUP, es:NOTHING
		mov	FixupSeg,es
		mov	FixupOfs,di
		ret

GI_ESSI:	ASSUME	ds:DGROUP, es:NOTHING
		mov	FixupSeg,es
		mov	FixupOfs,si
		ret

GI_ESDIr:	ASSUME	ds:DGROUP, es:NOTHING
		mov	FixupSeg,es
		add	di,RelItemOfs
		mov	FixupOfs,di
		ret


GI_ESa:		ASSUME	ds:DGROUP, es:NOTHING
		mov	FixupSeg,es
		mov	ax,RelItemOfs
		mov	FixupOfs,ax
		ret

GI_ESBX:	ASSUME	ds:DGROUP, es:NOTHING
		mov	FixupSeg,es
		mov	FixupOfs,bx
		ret

GI_STOSW:	ASSUME	ds:DGROUP, es:NOTHING
		mov	FixupSeg,es
		mov	FixupOfs,di
		add	FixupOfs,0E4h
		mov	ax,es:[di]		; mov dx,es:[di]
		mov	RegDX,ax
		mov	ax,RegAX		; stosw
		sub	ax,SegProgram
		stosw
		mov	RegDI,di
		ret
;---------------------------------------------------------------------------;
SetFixups:	ASSUME	ds:NOTHING, es:NOTHING
		push	ds
		push	es
		mov	ds,SegData
		ASSUME	ds:DGROUP
		mov	bx,SegProgram
		xor	ax,ax
		mov	SegItemCur,ax
		mov	NrRelocFound,ax
		xchg	SegItemStart,ax
SetBlckFixup:
		or	ax,ax
		je	EndSetFixups
		mov	ds,ax
		mov	cx,ds:[2]
		jcxz	FreeItemMem
		mov	si,4
Set1Fixup:
		lodsw
		mov	di,ax
		lodsw
		add	ax,bx
		mov	es,ax
		add	es:[di],bx
		loop	Set1Fixup
FreeItemMem:
		push	es			; free memory block
		push	ds
		pop	es
		call	FreeMem
		pop	es
		mov	ax,ds:[0]
		jmp	SetBlckFixup
EndSetFixups:
		pop	es
		pop	ds
		ret
;---------------------------------------------------------------------------;
WriteItems:	ASSUME	ds:NOTHING, es:NOTHING
		push	ds
		push	es
		push	dx
		mov	es,SegData
		ASSUME	es:DGROUP
		mov	ax,SegItemStart
WriteItemBlck:
		or	ax,ax			; no items ?
		je	EndWriteItems
		mov	ds,ax
		mov	cx,ds:[2]
		shl	cx,2
		mov	dx,4
		call	WriteFile
		push	es
		push	ds
		pop	es
		call	FreeMem
		pop	es
		mov	ax,ds:[0]
		jmp	WriteItemBlck

EndWriteItems:
		pop	dx
		pop	es
		pop	ds
		ret


SetGI:		ASSUME	ds:NOTHING, es:NOTHING
		push	ax
		push	bx
		push	cx
		push	es
		mov	es,SegData
		ASSUME	es:DGROUP
		mov	ax,INTGI*100h + 0CDh
		mov	cl,ds:[bx]
		cmp	cl,26h
		je	GIES
		xchg	ds:[bx],ax
		mov	si,offset GI_DSBX
		cmp	ax,0F01h		; add [bx],cx
		je	SetGIRegs
		cmp	ax,0701h		; add [bx],ax
		je	SetGIRegs
		mov	si,offset GI_DSDI
		cmp	ax,1501h		; add [di],dx
		je	SetGIRegs
GIES:
		mov	byte ptr ds:[bx],90h	; nop
		inc	bx
		xchg	ds:[bx],ax
		mov	si,offset GI_ESDIxchg
		cmp	ax,0587h		; xchg [di],ax (pgmpak)
		je	SetGIRegs
		mov	si,offset GI_ESDI
		cmp	ax,0501h		; add [di],ax
		je	SetGIRegs	
		cmp	ax,1D01h		; add [di],bx (exepack)
		je	SetGIRegs
		cmp	ax,0D01h		; add [di],cx (UCEXE)
		je	SetGIRegs
		cmp	ax,1501h		; add [di],dx
		je	SetGIRegs
		cmp	ax,2D01h		; add [di],bp
		je	SetGIRegs
		mov	si,offset GI_ESSI
		cmp	ax,1489h		; mov [si],dx (compressor)
		je	SetGIRegs
		mov	si,offset GI_ESBX
		cmp	ax,0701h		; add [bx],ax
		je	SetGIRegs
		cmp	ax,0F01h		; add [bx],cx (tinyprog v3.6)
		je	SetGIRegs
		cmp	ax,1701h		; add [bx],dx
		je	SetGIRegs
		cmp	ax,3F01h		; add [bx],di (compack v4.4)
		je	SetGIRegs
		cmp	ax,2F01h		; add [bx],bp (diet v1.45f)
		je	SetGIRegs
		mov	si,offset GI_ESDIxchgr
		mov	cl,90h
		xchg	ds:[bx+2],cl
		mov	byte ptr RelItemOfs,cl
		cmp	ax,5D87h		; xchg [di+XX],bx (optlink)
		je	SetGIRegs

		mov	si,offset GI_STOSW	; spacemaker
		cmp	ax,158Bh		; mov dx,es:[di] 
		je	SetGIRegs		; cl should be 0ABH (stosw)

		mov	si,offset GI_ESDIr
		mov	ch,90h
		xchg	ds:[bx+3],ch
		mov	byte ptr [RelItemOfs+1],ch
		cmp	ax,0AD01h		; add [di+XXXX],bp
		je	SetGIRegs
		mov	si,offset GI_ESa
		cmp	ax,0601h		; add [XXXX],ax (protect 5.0)
		je	SetGIRegs
		mov	si,offset ERR_reloc
		call	Error
		jmp	Continue

SetGIRegs:
		mov	SetFixupRegs,si
		pop	es
		pop	cx
		pop	bx
		pop	ax
		ret
;---------------------------------------------------------------------------;
GIShrink:	ASSUME	ds:NOTHING, es:NOTHING
		push	es
		push	ds
		mov	ds,SegData
		ASSUME	ds:DGROUP
		mov	ax,SegItemCur
		mov	es,ax
		ASSUME	es:NOTHING
		or	ax,ax			; first item ?
		je	GI_NoShrink
		mov	ax,es:[2]
		inc	ax			; +4 bytes for info field
		shl	ax,2
		mov	bx,ax

		shr	bx,4
		and	ax,0Fh
		cmp	ah,al
		adc	bx,0
		call	ResizeMem
GI_NoShrink:
		pop	ds
		pop	es
		ret

;---------------------------------------------------------------------------;
.data
; common signatures
GI_ESDIBX label
		add	es:[di],bx
GI_ESDIBXSz	equ	$ - GI_ESDIBX

FixupSeg	dw	0
FixupOfs	dw	0
RelItemOfs	dw	0

SetFixupRegs    dw	0