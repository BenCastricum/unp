;---------------------------------------------------------------------------;
; /* FindFirst; searches for first matching file in directory		    ;
;									    ;
; Input:								    ;
;    DGROUP:DX	wildcard						    ;
;									    ;
; Output:								    ;
;    C=0 ; successfull							    ;
;	[DTA] file data block						    ;
;    C=1 ; unsuccessfull						    ;
;	AX  error code							 */ ;
;---------------------------------------------------------------------------;
.code
FindFirst:	ASSUME	ds:NOTHING, es:NOTHING
		push	ds			; save DS
		push	cx			; save CX
		mov	ds,SegData
		ASSUME	ds:DGROUP
		mov	cx,_SearchAttrib
		mov	ah,4Eh
		int	21h
		pop	cx			; restore CX
		push	di
		jmp	_CheckIfExec

.data
_SearchAttrib	dw	0

;---------------------------------------------------------------------------;
; /* FindNext; searches for next matching file in directory		    ;
;									    ;
; Input:								    ;
;    nothing								    ;
;									    ;
; Output:								    ;
;    C=0 ; successfull							    ;
;	[DTA] file data block						    ;
;    C=1 ; unsuccessfull						    ;
;	AX  error code							 */ ;
;---------------------------------------------------------------------------;
.code
FindNext:	ASSUME	ds:NOTHING, es:NOTHING
		push	ds			; save DS
		mov	ds,SegData
		push	di
		ASSUME	ds:DGROUP
_SearchNext:
		mov	ah,4Fh
		int	21h
_CheckIfExec:
		jc	_NoMore
		cmp	_ExecOnly,FALSE
		je	_FoundOne
		push	si
		mov	si,offset DTA_Filename
		call	FindExtention
		pop	si
		cmp	[di],'C.'
		je	_CheckCOM
		cmp	[di],'E.'
		jne	_SearchNext
		cmp	[di+2],'EX'
		jne	_SearchNext
_FoundOne:
		clc
_NoMore:
		pop	di
		pop	ds			; restore DS
		ASSUME	ds:NOTHING
		ret
_CheckCOM:
		cmp	[di+2],'MO'
		jne	_SearchNext
		jmp	_FoundOne

.data
_ExecOnly	db	FALSE

