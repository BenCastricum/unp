; /**/
; /*
;    filename    : MEM.ASM
;    created by  : Ben Castricum
;    created on  : ?
;    purpose     : all memoryfunctions used are in here
;    last update :  9-Apr-1995
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
; 10-Okt-1993 : freeing memoryblock 0000 will be ignored
; 09-Apr-1995 : allocating 0 bytes will return a 0 segment
;									   */
;									 /**/

include compiler.h				; include standard settings
include stdio.h

; /* external data/code used */
.code
extrn Quit: near				; U4.ASM
extrn Continue: near

public GetFreeMem
public AllocateMem
public FreeMem
public ResizeMem
public GetMemStrategy
public SetMemStrategy
public GetUMBState
public SetUMBState

;---------------------------------------------------------------------------;
; /* GetFreeMem; returns size of largest available memory block 	    ;
;									    ;
; Input:								    ;
;    nothing								    ;
;									    ;
; Output:								    ;
;    AX destroyed							    ;
;    BX size of largest available block in paragraphs			 */ ;
;---------------------------------------------------------------------------;
.code
GetFreeMem:	ASSUME	ds:NOTHING, es:NOTHING, ss:NOTHING
		push	si
		xor	si,si
		mov	bx,-1
		call	AllocateMem
		pop	si
		ret

;---------------------------------------------------------------------------;
; /* AllocateMem; allocate a memory block				    ;
;									    ;
; Input:								    ;
;    BX  wanted block size in paragraphs				    ;
;    DGROUP:SI	description for what mem is necessary (si=0;no error check) ;
;									    ;
; Output:								    ;
;    C=0 ; successfull							    ;
;	AX segment of allocated block					    ;
;    C=1 ; unsuccessfull (SI=0) 					    ;
;	AX error code							    ;
;	BX size of largest available block				 */ ;
;---------------------------------------------------------------------------;
.code
AllocateMem:	ASSUME	ds:NOTHING, es:NOTHING, ss:NOTHING
		mov	ax,bx
		or	ax,ax
		clc
		je	_Ret
		mov	ah,48h
		int	21h
		jnc	_Ret
		or	si,si
		stc				; keep CF=1
		je	_Ret

		push	ax
		push	si
		mov	si,offset _MemError
		call	WriteASCIIZ
		pop	si
		call	WriteLnASCIIZ
		pop	ax
		cmp	ax,7
		jne	_MemErr
		mov	si,offset _MCBError
		call	WriteLnASCIIZ
		mov	al,ECMEMERROR
		jmp	Quit

_MemErr:
		jmp	Continue
.data
_MCBError	db	CR,LF,'FATAL ERROR - Memory Control Blocks destroyed.',0
_MemError	db	CR,LF,'ERROR - Not enough memory to ',0

;---------------------------------------------------------------------------;
; /* FreeMem; release a allocated memory block				    ;
;									    ;
; Input:								    ;
;    ES segment of block to be freed					    ;
;									    ;
; Output:								    ;
;    C=0 ; successfull							    ;
;	AX segment of allocated block					    ;
;    C=1 ; unsuccessfull						    ;
;	AX error code							 */ ;
;---------------------------------------------------------------------------;
.code
FreeMem:        ASSUME	ds:NOTHING, es:NOTHING, ss:NOTHING
		mov	ax,es			; #001#
		or	ax,ax
		je	_Ret
		mov	ah,49h
		int	21h
_Ret:
		ret

;---------------------------------------------------------------------------;
; /* ResizeMem; change the size of an allocated memory block		    ;
;									    ;
; Input:								    ;
;    ES segment of block to resize					    ;
;    BX new size in paragraphs						    ;
;									    ;
; Output:								    ;
;    C=0 ; successfull							    ;
;	AX destroyed							    ;
;    C=1 ; unsuccessfull						    ;
;	AX error code							    ;
;	BX maximum size available for this block			 */ ;
;---------------------------------------------------------------------------;
.code
ResizeMem:      ASSUME	ds:NOTHING, es:NOTHING, ss:NOTHING
		mov	ah,4Ah
		int	21h
		ret

;---------------------------------------------------------------------------;
; /* GetMemStrategy; get DOS's memory allocation strategy		    ;
;									    ;
; Input:								    ;
;    nothing								    ;
;									    ;
; Output:								    ;
;    AX current memory allocation strategy				 */ ;
;---------------------------------------------------------------------------;
.code
GetMemStrategy: ASSUME	ds:NOTHING, es:NOTHING, ss:NOTHING
		mov	al,0
_ToMemStrat:
		mov	ah,58h
		int	21h
		ret

;---------------------------------------------------------------------------;
; /* SetMemStrategy; set DOS's memory allocation strategy		    ;
;									    ;
; Input:								    ;
;   BL strategy to use							    ;
;									    ;
; Output:								    ;
;   C=0 ; successfull							    ;
;      AX destroyed							    ;
;   C=1 ; unsuccessfull 						    ;
;      AX error code							 */ ;
;---------------------------------------------------------------------------;
.code
SetMemStrategy: ASSUME	ds:NOTHING, es:NOTHING, ss:NOTHING
		mov	al,1
_SetMemStrat:
		mov	bh,0
		jmp	_ToMemStrat

;---------------------------------------------------------------------------;
; /* GetUMBState; get UMB link state				            ;
;									    ;
; Input:								    ;
;    nothing								    ;
;									    ;
; Output:								    ;
;    AL UMB link state:                                                     ;
;       AL=00 ; UMBs not part of DOS memory chain			    ;
;       AL=01 ; UMBs in DOS memory chain				 */ ;
;---------------------------------------------------------------------------;
.code
GetUMBState:    ASSUME	ds:NOTHING, es:NOTHING, ss:NOTHING
		mov	al,2
		jmp	_ToMemStrat

;---------------------------------------------------------------------------;
; /* SetUMBState; set UMB link state					    ;
;									    ;
; Input:								    ;
;   BL strategy to use:							    ;
;      00 ; remove UMBs from DOS memory chain				    ;
;      01 ; add UMBs to DOS memory chain				    ;
;									    ;
; Output:								    ;
;   C=0 ; successfull							    ;
;      AX destroyed							    ;
;   C=1 ; unsuccessfull 						    ;
;      AX error code							 */ ;
;---------------------------------------------------------------------------;
.code
SetUMBState:    ASSUME	ds:NOTHING, es:NOTHING, ss:NOTHING
		mov	al,3
		jmp	_SetMemStrat
end
