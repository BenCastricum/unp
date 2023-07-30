
include compiler.h				; include standard settings

; /* external data/code used */

public FindCode
public FindExtention
public FindFilename

;---------------------------------------------------------------------------;
; /* FindCode; search for a string                                          ;
;                                                                           ;
; Input:                                                                    ;
;    ES:DI  start adress of string                                          ;
;    CX  size of string in bytes                                            ;
;    DS:SI  begin adress of block to search in                              ;
;    DS:AX  end adress of block to search in                                ;
;                                                                           ;
; Output:                                                                   ;
;    CX  signature size                                                     ;
;    C=0 ; code found                                                       ;
;       SI  location of code found                                          ;
;    C=1 ; code not found                                                   ;
;       SI  AX+1                                                         */ ;
;---------------------------------------------------------------------------;
.code
FindCode:	ASSUME	ds:NOTHING, es:NOTHING, ss:NOTHING
		cld
		push	bx
		push	dx
		push	bp
		mov	bx,di
		mov	dx,cx
		mov	bp,si
_FindCode:
		mov	si,bp
		repz	cmpsb
		mov	cx,dx
		mov	di,bx
		je	_FoundCode
		inc	bp
		cmp	bp,ax
		jle	_FindCode
		mov	si,bp
		pop	bp
		pop	dx
		pop	bx
		stc
		ret
_FoundCode:
		mov	si,bp
		pop	bp
		pop	dx
		pop	bx
		clc
		ret

;---------------------------------------------------------------------------;
; /* FindFilename; search for the start of the filename in a path           ;
;                                                                           ;
; Input:                                                                    ;
;    DS:SI  pointer to filename                                             ;
;                                                                           ;
; Output:                                                                   ;
;    DI	 points to start extention ('.')	                         */ ;
;---------------------------------------------------------------------------;
.code
FindFilename:   ASSUME	ds:NOTHING, es:NOTHING, ss:NOTHING
		push	es			; save ES
		push	ax			; save AX
		push	cx			; save CX
		push	si			; save SI

		push	ds
		pop	es
		mov	al,00h
		mov	ch,10h
		mov	di,si
		repnz	scasb			; get end of filename
		dec	di			; assume extention at end
		xchg	ax,si
		mov	si,di
_ScanPath:
		dec	si
		cmp	byte ptr [si],':'	; drive found ?
		je 	_GotName
		cmp	byte ptr [si],'\'	; path found ?
		je	_GotName
		cmp	ax,si
		jbe	_ScanPath
_GotName:
		mov	di,si
		inc	di
		pop	si			; restore SI
		pop	cx			; restore CX
		pop	ax			; restore AX
		pop	es			; restore ES
		ret

;---------------------------------------------------------------------------;
; /* FindExtention; search the extention in a filename                      ;
;                                                                           ;
; Input:                                                                    ;
;    DS:SI  pointer to filename                                             ;
;                                                                           ;
; Output (FindExtention):                                                   ;
;    DI	 points to start extention ('.')	                         */ ;
;---------------------------------------------------------------------------;
.code
FindExtention:  ASSUME	ds:NOTHING, es:NOTHING, ss:NOTHING
		push	es			; save ES
		push	ax			; save AX
		push	cx			; save CX
		push	si			; save SI

		push	ds
		pop	es
		mov	al,00h
		mov	ch,10h
		mov	di,si
		repnz	scasb			; get end of filename
		dec	di			; assume extention at end
		xchg	ax,si
		mov	si,di
_ScanExt:
		dec	si
		cmp	byte ptr [si],':'	; drive found ?
		je 	_EndSearch
		cmp	byte ptr [si],'\'	; path found ?
		je	_EndSearch
		cmp	si,ax
		je	_EndSearch
		cmp	byte ptr [si],'.'	; found real extention ?
		jne	_ScanExt
		mov	di,si
_EndSearch:
		pop	si			; restore SI
		pop	cx			; restore CX
		pop	ax			; restore AX
		pop	es			; restore ES
		ret

end