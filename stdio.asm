; STDIO.ASM
; last update : 13-Sep-1993
;
; 11-Sep-1993  001  WriteASCIIZ now preserves AX and SI registers
; 12-Sep-1993  002  added GetChar function
;	       003  changed SetExecOnly to use AL as value
; 13-Sep-1993  004  added functions ReadStamp and WriteStamp
; 14-Sep-1993  005  added functions DeleteFile and RenameFile
; 10-Okt-1993  006  fixed incorrect handling of -M with Silent on
; 22-Okt-1993  007  added function MovePointer
; 10-May-1994  008  preserved BP register
; 12-May-1994  009  added several CLD instructions.
; 14-Okt-1994  010  added functions MoveFile and CopyFile

include compiler.h				; include standard settings
include find.h

; /* external data/code used */
.code
extrn Quit: near				; U4.ASM
extrn SegData: word
extrn OldInt21:dword
.data
extrn SwitchM: byte
extrn DTA_Filename: tbyte

public Silent

public SetSrchAttrib
public SetExecOnly
public FindFirst
public FindNext
public OpenFile
public CreateFile
public ReadFile
public WriteFile
public CloseFile
public WriteLnASCIIZ
public WriteLn
public WriteASCIIZ
public WriteLongInt
public WriteLongIntAl
public WriteHexWord
public GetChar
public ReadStamp
public WriteStamp
public DeleteFile
public RenameFile
public MovePointer
public HomeCursor
public MoveFile
public CopyFile

int21h macro
		pushf
		call	dword ptr OldInt21
endm

;---------------------------------------------------------------------------;
; /* SetSrchAttrib; sets the file attribute used in FindFirst		    ;
;									    ;
; Input:								    ;
;    AX  the new file attribute						    ;
;									    ;
; Output:								    ;
;    none                                                                */ ;
;---------------------------------------------------------------------------;
.code
SetSrchAttrib:	ASSUME	ds:NOTHING, es:NOTHING
		push	ds
		mov	ds,SegData
		ASSUME	ds:DGROUP
		mov	_SearchAttrib,ax
		pop	ds
		ret

;---------------------------------------------------------------------------;
; /* SetExecOnly; handles the internal "ExecOnly" flag causing when set to  ;
;    only pass .COM and .EXE file					    ;
;									    ;
; Input:								    ;
;    al  new ExecOnly status                                          #003# ;
;       00  allow any extention                                             ;
;       01  only search for .COM and .EXE files                             ;
;									    ;
; Output:								    ;
;    none                                                                */ ;
;---------------------------------------------------------------------------;
.code
SetExecOnly:	ASSUME	ds:NOTHING, es:NOTHING
		push	ds
		mov	ds,SegData
		ASSUME	ds:DGROUP
		mov	_ExecOnly,al		; use AL as value #003#
		pop	ds
		ret

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
		int21h
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
		int21h
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

;---------------------------------------------------------------------------;
; /* OpenFile; opens an existing file					    ;
;									    ;
; Input:								    ;
;    DGROUP:DX	filename						    ;
;									    ;
; Output:								    ;
;    C=0 ; successfull							    ;
;	AX  file handle 						    ;
;	BX  file handle 						 */ ;
;---------------------------------------------------------------------------;
.code
OpenFile:	ASSUME	ds:NOTHING, es:NOTHING
		push	ds			; save DS
		mov	ds,SegData
		ASSUME	ds:DGROUP
;		mov	ax,3D02h		; try opening file for R/W
;		int21h
;		jnc	_NoteHandle
		mov	ax,3D00h		; try opening file read only
		int21h
		jc	_NotOpen
_NoteHandle:
		mov	bx,ax			; write down offset filename
		shl	bx,1
		mov	[Handles+bx],dx
		mov	bx,ax
		pop	ds			; restore DS
		ret

_NotOpen:
		mov	si,offset open$
_NoFile:
		push	dx			; push offset filename
_DosError:
		mov	Silent,FALSE
		xchg	bx,ax
		push	si			; push failed command
		mov	si,offset DOSError	; write intial dos error txt
		call	WriteASCIIZ
		pop	si
		call	WriteASCIIZ		; write failed command
		mov	si,offset _file_$
		call	WriteASCIIZ		; write " file "
		pop	si
		call	WriteASCIIZ		; writeln filename
		mov	si,offset errorCdTxt
		call	WriteASCIIZ
		xchg	bx,ax
		xor	dx,dx
		call	WriteLongInt
		mov	si,offset errorCdTxt2
		call	WriteLnASCIIZ
		mov	al,ECDOSERROR
		jmp	Quit

.data
DOSError	db	'DOS ERROR - unable to ',0
open$		db	'open',0
write_to$	db	'write to',0
read_from$	db	'read from',0
create$ 	db	'create',0
_file_$ 	db	' file ',0
errorCdTxt	db	' (error ',0
errorCdTxt2	db	')',0


STDIN$		db	'STDIN',0	        ; names for standard handles
STDOUT$ 	db	'STDOUT',0
STDERR$ 	db	'STDERR',0
STDAUX$ 	db	'STDAUX',0
STDPRN$ 	db	'STDPRN',0

Handles 	dw	offset STDIN$	        ; standard dos handles
		dw	offset STDOUT$
		dw	offset STDERR$
		dw	offset STDAUX$
		dw	offset STDPRN$
		dw	20  dup (0)	        ; reserved space for handles

;---------------------------------------------------------------------------;
; /* CreateFile; creates a  file with handle				    ;
;									    ;
; Input:								    ;
;    DGROUP:DX	filename						    ;
;									    ;
; Output:								    ;
;    C=0 ; successfull							    ;
;	AX  file handle 						    ;
;	BX  file handle 						 */ ;
;---------------------------------------------------------------------------;
.code
CreateFile:     ASSUME	ds:NOTHING, es:NOTHING
		mov	ah,3Ch
		xor	cx,cx
		push	ds			; save DS
		mov	ds,SegData
		ASSUME	ds:DGROUP
		int21h
		jnc	_NoteHandle
		mov	si,offset create$
		jmp	_NoFile

;---------------------------------------------------------------------------;
; /* ReadFile; read from file with handle				    ;
;									    ;
; Input:								    ;
;    BX  file handle							    ;
;    CX  number of bytes to read					    ;
;    DS:DX  pointer to buffer						    ;
;									    ;
; Output:								    ;
;    C=0 ; successfull 						    	    ;
;       AX  number of bytes read					 */ ;
;---------------------------------------------------------------------------;
.code
ReadFile:	ASSUME	ds:NOTHING, es:NOTHING
		mov	ah,3Fh
		int21h
		jnc	_Ret
		mov	si,offset read_from$
_FileError:
		mov	ds,SegData
		ASSUME	ds:DGROUP
		shl	bx,1
		push	[Handles+bx]
		jmp	_DosError

;---------------------------------------------------------------------------;
; /* WriteFile; writes to a file with handle				    ;
;									    ;
; Input:								    ;
;    BX  file handle							    ;
;    CX  number of bytes to write					    ;
;    DS:DX  pointer to buffer						    ;
;									    ;
; Output:								    ;
;    C=0 ; successfull							    ;
;       AX  number of bytes written					 */ ;
;---------------------------------------------------------------------------;
.code
WriteFile:	ASSUME	ds:NOTHING, es:NOTHING
		mov	ah,40h
		int21h
		jc	_WriteError
		cmp	ax,cx
		je	_Ret
_WriteError:
		mov	si,offset write_to$
		jmp	_FileError

;---------------------------------------------------------------------------;
; /* CloseFile; closes file with handle 				    ;
;									    ;
; Input:								    ;
;    BX  file handle							    ;
;									    ;
; Output:								    ;
;    C=0 ; successfull							    ;
;      AX  destroyed							    ;
;      BX  destroyed							 */ ;
;---------------------------------------------------------------------------;
.code
CloseFile:	ASSUME	ds:NOTHING, es:NOTHING
		push	ds
		mov	ds,SegData
		ASSUME	ds:DGROUP
		mov	ah,3Eh
		shl	bx,1
		cmp	[Handles+bx],0
		je	_IsClosed
		mov	[Handles+bx],0
		shr	bx,1
		int21h
_IsClosed:
		pop	ds
_Ret:		ret

;---------------------------------------------------------------------------;
; /* WriteLnASCIIZ; writes a NULL terminated string to STDOUT followed by a ;
;    newline 								    ;
;    - does not generate output when Silent != FALSE   	    		    ;
;    - behaves like dos' more.exe when SwitchM != FALSE                     ;
;                                                                           ;
; Input:								    ;
;    DGROUP:SI  NULL terminated string				    	    ;
;                                                                           ;
; SUBENTRY:                                                                 ;
; /* WriteLn; lets the cursor move to the beginning of the next line and    ;
;    - behaves like dos' more.exe when SwitchM != FALSE                     ;
;    - does not generate output when Silent != FALSE   	    		    ;
;									    ;
; Output:								    ;
;    SI	 destroyed						            ;
;    C=0 ; successfull						    	    ;
;       AX  size of string						    ;
;    C=1 ; unsuccessfull						    ;
;       AX  error code						 	 */ ;
;---------------------------------------------------------------------------;
.code
WriteLnASCIIZ:	ASSUME	ds:NOTHING, es:NOTHING
		call	WriteASCIIZ
WriteLn:
		push	ds
		mov	ds,SegData
		ASSUME	ds:DGROUP
		cmp	Silent,TRUE		; #006#
		je	_IsClosed
		mov	si,offset CRLF$
		call	WriteASCIIZ
		push	ax
		push	si
		mov	CursorHome,TRUE
		inc	LinesWritten
		mov	al,LinesOnScreen
		cmp	al,0			; not initialized ?
		jne	_CheckFullScreen
		push	es			; get LinesOnScreen
		xor	ax,ax
		mov	es,ax
		ASSUME	es:NOTHING
		mov	al,es:[0484h]
		sub	ax,3
		mov	LinesOnScreen,al
		pop	es
_CheckFullScreen:
		cmp	al,LinesWritten
		jne	_EndWrite
		mov	LinesWritten,0
		cmp	SwitchM,FALSE
		je	_EndWrite
		mov	si,offset Prompt
		call	WriteASCIIZ
		mov	ax,0C08h
		int21h
		mov	si,offset PromptClr
		call	WriteASCIIZ
_EndWrite:
		pop	si
		pop	ax
		pop	ds
		ret

.data
Prompt		db	'-- More --',0
PromptClr	db	CR,'	      ',CR,0
CRLF$		db	CR,LF,0
LinesOnScreen	db	0
LinesWritten	db	0
CursorHome	db	TRUE

;---------------------------------------------------------------------------;
; /* HomeCursor; makes sure the cursor is at the beginning of an empty line ;
;									    ;
; Input:								    ;
;    none                                                                   ;
;									    ;
; Output:								    ;
;    none                                                                   ;
;                 						 	 */ ;
;---------------------------------------------------------------------------;
.code
HomeCursor:	ASSUME	ds:NOTHING, es:NOTHING
		push	ds
		mov	ds,SegData
		ASSUME	ds:DGROUP
		cmp	CursorHome,TRUE
		je	_IsHome
		push	si
		call	WriteLn
		pop	si
_IsHome:
		pop	ds
		ret
;---------------------------------------------------------------------------;
; /* WriteASCIIZ; writes a NULL terminated string to STDOUT		    ;
;    - does not generate output when Silent != FALSE   	    		    ;
;									    ;
; Input:								    ;
;    DGROUP:SI	NULL terminated string				    	    ;
;									    ;
; Output:								    ;
;    SI  destroyed						    	    ;
;    C=0 ; successfull						    	    ;
;       AX  size of string						    ;
;    C=1 ; unsuccessfull						    ;
;	AX  error code						 	 */ ;
;---------------------------------------------------------------------------;
.code
WriteASCIIZ:	ASSUME	ds:NOTHING, es:NOTHING
		cld				; #009#
		push	ds
		mov	ds,SegData
		ASSUME	ds:DGROUP
		cmp	Silent,FALSE
		je	_WriteOk
		pop	ds
		ASSUME	ds:NOTHING
		clc
		ret

_WriteOk:	ASSUME	ds:DGROUP
		push	ax			; save AX #001#
		push	bx			; save BX
		push	cx			; save CX
		push	dx			; save DX
		push	si			; save SI #001#
		mov	CursorHome,FALSE

		mov	dx,si			; DS:DX points to string
		xor	cx,cx			; CX string size
_GetEnd:
		cmp	byte ptr [si],0 	; end of string found?
		je	_Write			; yes, write string
		inc	cx
		inc	si
		jne	_GetEnd			; write if end of segment
_Write:
		mov	bx,STDOUT
		call	WriteFile

		pop	si			; restore SI #001#
		pop	dx			; restore DX
		pop	cx			; restore CX
		pop	bx			; restore BX
		pop	ax			; restore AX #001#
		pop	ds			; restore DS
		ASSUME	ds:NOTHING
		ret

.data
Silent		db	FALSE

;---------------------------------------------------------------------------;
; /* WriteLongIntAl; writes a signed 16bit number right alligned to STDOUT  ;
;									    ;
; Input:								    ;
;    AX:DX  a long integer						    ;
;									    ;
; Output:								    ;
;    all registers (except segment) destroyed 		    	 	 */ ;
;---------------------------------------------------------------------------;
.code
WriteLongIntAl:	ASSUME	ds:NOTHING, es:NOTHING
		inc     AllignIt
		call	WriteLongInt
		dec	AllignIt
		ret

AllignIt	db	FALSE
;---------------------------------------------------------------------------;
; /* WriteLongInt; writes a signed 16bit number to STDOUT		    ;
;									    ;
; Input:								    ;
;    AX:DX  a long integer						    ;
;									    ;
; Output:								    ;
;    all registers (except segment) destroyed 		    	 	 */ ;
;---------------------------------------------------------------------------;
.code
WriteLongInt:	ASSUME	ds:NOTHING, es:NOTHING
		cld				; #009#
		push	bp			; save BP #008#
		push	ds			; save DS
		push	es			; save ES
		mov	ds,SegData
		mov	es,SegData
		mov	di,offset _Result
		mov	si,offset _Decimals
		xor	bp,bp
		test	dh,80h
		je	_IsPositive
		xor	bx,bx
		xor	cx,cx
		sub	bx,ax
		sbb	cx,dx
		mov	al,'-'
		stosb
		jmp	_StartConvert

_IsPositive:
		xchg	bx,ax
		xchg	cx,dx
_StartConvert:
		add	di,bp
		lodsw
		cmp	al,255
		je	_WriteInt
		xchg	dx,ax
		lodsw
		mov	byte ptr [di],'0'
_CheckFit:
		cmp	cx,ax
		ja	_Substract
		jb	_StartConvert
		cmp	bx,dx
		jb	_StartConvert
_Substract:
		sub	bx,dx
		sbb	cx,ax
		inc	byte ptr [di]
		mov	bp,1
		jmp	_CheckFit

_WriteInt:
		xor	bp,1
		add	di,bp
		mov	al,0
		stosb
		mov	si,offset _Result
		cmp	AllignIt,FALSE
		je	_EndWriteInt
		sub	di,offset _Result
		lea	si,[_AlResult+di]
_EndWriteInt:
		pop	es			; restore ES
		pop	ds			; restore DS
		pop	bp			; restore BP #008#
		jmp	WriteASCIIZ

.data
_AlResult	db	'         '
_Result		db	11 dup (0)

_Decimals label
		dd	1000000000
		dd	100000000
		dd	10000000
		dd	1000000
		dd	100000
		dd	10000
		dd	1000
		dd	100
		dd	10
		dd	1
		db	255

;---------------------------------------------------------------------------;
; /* WriteHexWord; Writes AX in ASCII to STDOUT          		    ;
;									    ;
; Input:								    ;
;    AX 								    ;
;									    ;
; Output:								    ;
;    BX  destroyed							    ;
;    ES:DI  point to next char						 */ ;
;---------------------------------------------------------------------------;
.code
WriteHexWord:	ASSUME	ds:NOTHING, es:NOTHING
		cld				; #009#
		push	ds
		push	es
		push	si
		mov	ds,SegData
		ASSUME	ds:DGROUP
		mov	es,SegData
		mov	cx,4
		mov	bx,offset HexTabel
		mov	di,offset TempStore
_ConvertDigit:
		push	cx
		mov	cl,4
		rol	ax,cl
		pop	cx
		push	ax
		and	al,0Fh
		xlat
		stosb
		pop	ax
		loop	_ConvertDigit
		mov	si,offset TempStore
		call	WriteASCIIZ
		pop	si
		pop	es
		pop	ds
		ret

.data
HexTabel	db	'0123456789ABCDEF'
TempStore	db	5 dup (0)

;---------------------------------------------------------------------------;
; /* GetChar, flushes buffer and reads a character from STDIN	      #002# ;
;									    ;
; Input:								    ;
;    none                                                                   ;
;									    ;
; Output:								    ;
;    AL  character read                                                     ;
;    AH  destroyed                                                       */ ;
;---------------------------------------------------------------------------;
.code
GetChar:	ASSUME	ds:NOTHING, es:NOTHING
		mov	ax,0C08h
		int21h
		ret

;---------------------------------------------------------------------------;
; /* ReadStamp; get a file's date/time stamp			      #004# ;
;									    ;
; Input:								    ;
;    BX  file handle		                                            ;
;									    ;
; Output:								    ;
;    C=0 ; successfull						            ;
;       AX  destroyed						            ;
;	CX  file's time 						    ;
;	DX  file's date                                                     ;
;    C=1 ; unsuccessfull						    ;
;	AX  error code						         */ ;
;---------------------------------------------------------------------------;
.code
ReadStamp:	ASSUME	ds:NOTHING, es:NOTHING
		mov	al,0
_Stamp:
		mov	ah,57h
		int21h
		ret

;---------------------------------------------------------------------------;
; /* WriteStamp; set a file's date/time stamp			      #004# ;
;									    ;
; Input:								    ;
;    BX  file handle		                                            ;
;    CX  file's new time 					            ;
;    DX  file's new date                                                    ;
;									    ;
; Output:								    ;
;    C=0 ; successfull		         				    ;
;      AX  destroyed	           					    ;
;    C=1 ; unsuccessfull						    ;
;      AX  error code 						         */ ;
;---------------------------------------------------------------------------;
.code
WriteStamp:	ASSUME	ds:NOTHING, es:NOTHING
		mov	al,1
		jmp	_Stamp

;---------------------------------------------------------------------------;
; /* DeleteFile; tries to delete a file 			      #005# ;
;									    ;
; Input:								    ;
;    DGROUP:DX  filename					            ;
;									    ;
; Output:								    ;
;    C=0 ; successfull						            ;
;	AX  destroyed						            ;
;    C=1 ; unsuccessfull						    ;
;	AX  error code						         */ ;
;---------------------------------------------------------------------------;
.code
DeleteFile:
		mov	ah,41h
		push	ds
		mov	ds,SegData
		int21h
		pop	ds
		ret

;---------------------------------------------------------------------------;
; /* RenameFile; changes the name of a file			      #005# ;
;									    ;
; Input:								    ;
;    DGROUP:DX  filename to change                                          ;
;    DGROUP:DI  new filename                                                ;
;									    ;
; Output:								    ;
;    C=0 ; successfull							    ;
;       AX  destroyed						    	    ;
;    C=1 ; unsuccessfull						    ;
;	AX  error code							 */ ;
;---------------------------------------------------------------------------;
.code
RenameFile:
		mov	ah,56h
		push	ds
		push	es
		mov	ds,SegData
		mov	es,SegData
		int21h
		pop	es
		pop	ds
		ret

;---------------------------------------------------------------------------;
; /* MovePointer; moves the file pointer to the specified location    #007# ;
;									    ;
;  Input:								    ;
;	BX	file handle		                                    ;
;	DX:AX	position to move pointer to                                 ;
;									    ;
; Output:								    ;
;	C=0 ; successfull						    ;
;         DX:AX	new position of pointer                                     ;
;	C=1 ; unsuccessfull						    ;
;	  AX	error code						 */ ;
;---------------------------------------------------------------------------;
.code
MovePointer:
		push	cx
		xchg	ax,dx
		xchg	ax,cx
		mov	ax,4200h
		int21h
		pop	cx
		ret

;---------------------------------------------------------------------------;
; /* MoveFile; moves a file                                           #010# ;
;									    ;
;  Input:								    ;
;	AX	segment of 64k of free memory                               ;
;	SI	source filename		                                    ;
;	DI   	destination filename                                        ;
;									    ;
; Output:								    ;
;	nothing          						 */ ;
;---------------------------------------------------------------------------;
MoveFile:	ASSUME	ds:NOTHING, es:NOTHING
		push	si
		mov	bp,ax
		mov	dx,di
		call	DeleteFile
		pop	dx
		call	RenameFile
		jnc	MV_exit
		push	dx
		mov	ax,bp
		call	CopyFile
		pop	dx
		call	DeleteFile
MV_exit:
		ret

;---------------------------------------------------------------------------;
; /* CopyFile; copies a file                                          #010# ;
;									    ;
;  Input:								    ;
;	AX	segment of 64k of free memory                               ;
;	SI	source filename		                                    ;
;	DI   	destination filename                                        ;
;									    ;
; Output:								    ;
;	nothing          						 */ ;
;---------------------------------------------------------------------------;
.code
CopyFile:	ASSUME	ds:NOTHING, es:NOTHING
		push	ds
		mov	ds,SegData
		ASSUME	ds:DGROUP
		mov	ds,ax                   ; get 64K of mem
		mov	dx,si			; open source file
		call	OpenFile
		mov	si,ax			; keep source handle in SI
		mov	dx,di			; open destination file
		call	CreateFile
		mov	di,ax			; keep dest. handle in DI
CF_copyblock:
		mov	bx,si			; read from file
		mov	cx,0FFFFh
		xor	dx,dx
		call	ReadFile
		mov	bx,di			; write to file
		mov	cx,ax
		call	WriteFile
		cmp	ax,0FFFFh		; full buffer written ?
		je	CF_copyblock
		mov	bx,si			; copy file's date/time stamp
		call	ReadStamp
		mov	bx,di
		call	WriteStamp
		call	CloseFile		; close destination file
		mov	bx,si
		pop	ds
		jmp	CloseFile		; close source file




end
