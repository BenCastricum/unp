include compiler.h
include version.h

include mem.h
include find.h
include stdio.h

.code
extrn Break10: near				; U4.ASM
extrn Break20: near
extrn Break21: near
extrn BreakCC: near
extrn BreakEP: near
extrn BreakGS: near
extrn BreakGI: near
extrn BreakQT: near
extrn BreakDZ: near
extrn Info: near
extrn SetDTA: near
extrn SegData: word
extrn OldInt21: word
extrn Warning: near
extrn Quit: near

extrn WriteASCIIZ: near
extrn WriteLn: near
extrn WriteLnASCIIZ: near
extrn WriteLongInt: near
extrn FindNext: near
.data
extrn ME_BasicOp: tbyte				; U4.ASM
extrn DefAlignSize: word
extrn Command: byte
extrn DTA_Filename: tbyte
extrn DTABlock: tbyte
extrn File1NmePtr: word
extrn FilenameCnt: byte
extrn Filename1: tbyte
extrn Filename2: tbyte
extrn Filename3: tbyte
extrn Filename4: tbyte
extrn FilesFound: word
extrn HookedInts: tbyte
extrn HookedIntsCnt: abs
extrn IntsCopied: byte
extrn MemStrategy: word
extrn OldInts: tbyte
extrn SegFiles: MEMBLOCK
extrn SegHMAStart: word
extrn SegPSP: word
extrn SwitchB: byte
extrn SwitchI: byte
extrn SwitchN: byte
extrn SwitchP: byte
extrn SwitchV: byte
extrn SwitchS: byte
extrn Switches: byte
extrn SwitchesCnt: abs
extrn SwitchHlp: byte
extrn UMBState: word
DataEnd	label

public DataEnd
public Init

.code
Init:		ASSUME	ds:NOTHING, es:NOTHING, ss:NOTHING
		mov	ds,SegData
		ASSUME	ds:DGROUP
		mov	SegPSP,es

		call	GetInt21
		call	WriteTitle
		call	GetDefaults
		call	HandleCLI
		call	BuildTempfile
		call	CheckDCmmnd
		call	HandleOptions
		call	SetDefCmmnd
		call	SetDTA
		call	CheckFilenames
		call	FreeConvMem
		call	SetupMemory
		call	ReadFilenames
		call	RelocateMem
		ASSUME	ds:NOTHING,es:NOTHING
		call	HookInts
		call	Specials
		call	DebugInfo

		mov	es,SegData
		ASSUME	es:DGROUP
		mov	ds,SegData
		ASSUME	ds:DGROUP
		mov	dx,offset Filename1
		call	FindFirst
		mov	es,SegData
		ASSUME	es:DGROUP
		mov	si,offset Filename1
		call	FindFilename
		mov	File1NmePtr,di
		mov	si,offset DTA_Filename
		mov	cx,13
		repnz	movsb

		mov	al,FALSE
		call	SetExecOnly		; clears ExecOnly flag

		mov	cx,DataSegSz
		mov	es,NewSegData
		xor	si,si
		xor	di,di
		shl	cx,3
		mov	bx,ProgSegSz
		ret
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
.code
WriteTitle:	ASSUME	ds:NOTHING, es:NOTHING
		mov	si,offset Titlebar
		call	WriteLnASCIIZ

IFDEF REGISTERED
		mov	si,offset Subbar
		call	WriteLnASCIIZ
.data
;Subbar		db	'Registered to ',REGISTERED, ', distribution prohibited.',0
Subbar		db	'Special version registered to ',REGISTERED, ', distribution prohibited.',0
.code
ENDIF
		call	WriteLn
		ret
.data
Titlebar	db	LF,'UNP ',Version
		db	' Executable file restore utility, written by Ben Castricum, ',??date,0
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
.code
GetDefaults:	ASSUME	ds:NOTHING, es:NOTHING, ss:NOTHING
		mov	es,SegData
		ASSUME	es:DGROUP
		mov	ds,SegPSP
		mov	ds,ds:[002Ch]
		xor	si,si
		xor	ax,ax
ScanEnv:
		cmp	ds:[si],ax
		je	GotEndEnv
		inc	si
		jmp	ScanEnv
GotEndEnv:
		add	si,4
		mov	di,offset Filename1
		mov	dx,di
		mov	cx,64
		repnz   movsw
		mov	ds,SegData
		ASSUME	ds:DGROUP
		call	OpenFile
		mov	dx,offset Filename3
		mov	cx,1Ch
		call	ReadFile
		mov	cx,100h
		call	ReadFile
		mov	cx,ax
		call	CloseFile
		mov	si,dx
ScanToDefaults:
		lodsb
		cmp	al,EOF
		je	GotDefaults
		loop	ScanToDefaults
		jmp	EndDefaults
GotDefaults:
		call	AnalyzeCLI
EndDefaults:
		ret

CheckDCmmnd:	ASSUME	ds:NOTHING, es:NOTHING, ss:NOTHING
		push	ds
		push	es
		mov	ds,SegData
		ASSUME	ds:DGROUP
		mov	es,SegData
		ASSUME	es:DGROUP
		cmp	Command,'D'
		jne	CD_done
		mov	cx,SwitchesCnt -1	; skip the '-' switch
		mov	bp,offset Switches
		mov	si,offset SwitchHlp
		mov	di,offset MyCLISz+1

		cmp	FilenameCnt,0
		je	CD_NextSwitch
		mov	si,offset NoNamesReq
		call	WriteLnASCIIZ
		mov	al,ECINVALIDCL
		jmp	Quit

CD_NextSwitch:
		lodsb
		mov	ah,[bp]
		inc	bp
		mov	al,'-'
		stosb
		mov	al,ah
		stosb
		cmp	ah,'K'
		mov	al,ds:[si-1]
		mov	bl,al
		xor	bh,bh
		mov	al,Swtch2Asc[bx]
		stosb
		mov	al,' '
		stosb
		loop	CD_NextSwitch
		mov	al,CR
		dec	di
		stosb
		mov	cx,di
		sub	cx,offset DefTxt
		push	cx
		sub	di,offset MyCLISz
		mov	ax,di
		mov	MyCLISz,al
		mov	FilenameCnt,2
		mov	si,offset Filename4
		mov	di,offset Filename2
		mov	cx,40h
		repnz	movsw
		mov	dx,offset Filename2
		call	CreateFile
		mov	dx,offset DefTxt
		pop	cx
		call	WriteFile
		call	CloseFile
		mov	Command,'M'
CD_done:
		pop	es
		pop	ds
		ret

.data
DefTxt		db	CR,'UNP ', Version, ' Executable file restore utility,'
		db	' written by Ben Castricum.',CR,LF,EOF
MyCLISz		db	0
		db	128 dup (0)

.code
HandleCLI:	ASSUME	ds:NOTHING, es:NOTHING, ss:NOTHING
		mov	es,SegData
		ASSUME	es:DGROUP
		push	ds
		mov	ds,SegPSP
		ASSUME	ds:NOTHING
		mov	si,80h
		call	AnalyzeCLI

		mov	ds:[0080h],0D00h	; clear cli
		cmp	SwitchHlp,FALSE
		jne	Help
EndCLI:
		pop	ds
		ret

AnalyzeCLI:
		push	es
		mov	es,SegData
		ASSUME	es:DGROUP
		mov	cl,ds:[si]
		mov	ch,0
		inc	si
ReadCLI:
		or	cx,cx
		jle	EndLine
		call	ReadUpCase
		cmp	al,' '
		jbe	ReadCLI
		cmp	al,'-'
		je	GotSwitch
		cmp	al,'/'
		je	GotSwitch
		cmp	byte ptr ds:[si],' '
		jbe	GotCommand
GotFilename:
		mov	bl,FilenameCnt
		cmp	bl,2
		je	Help
		mov	bh,0
		push	ax
		mov	ax,128
		mul	bx
		add	ax,offset Filename1
		mov	di,ax
		pop	ax
WriteFilename:
		stosb				; copy filename
		call	ReadUpCase
		cmp	al,' '
		ja	WriteFilename
		or	bl,bl
		jne	Name2
		cmp	byte ptr es:[di-1],'\'	; is name path ?
		jne	Name2
		cmp	byte ptr es:[di-1],':'	; is name drive ?
		jne	Name2
		mov	ax,'.*'			; append *.*
		stosw
		mov	ah,0
		stosw
Name2:
		mov	al,0
		stosb
		inc	FilenameCnt
		jmp	ReadCLI

GotSwitch:
		call	ReadUpCase
		cmp	al,' '
		jbe     ReadCLI
		cmp	al,'-'
		je	ChildCL
		cmp	al,'/'
		je	ChildCL
		mov	di,offset Switches
		push	cx
		mov	cx,SwitchesCnt
		repnz	scasb			; check for valid switch
		jne	Help
		sub	di,offset Switches +1
		pop	cx
		mov	ah,al			; remember switch
		call	ReadUpCase
		mov	bl,TRUE
		cmp	al,'+'
		je	SetSwitch
		mov	bl,ASK
		cmp	al,'?'
		je	SetSwitch
		mov	bl,FALSE
		cmp	al,'-'
		je	SetSwitch
		cmp	ah,'P'
		jne	Toggle
		push	ax
		and	al,0F0h
		cmp	al,30h
		pop	ax
		jne	Toggle
		and	ax,000Fh
		mov	DefAlignSize,ax
		mov	SwitchP,FALSE
GetNextDigit:
		call	ReadUpCase
		push	ax
		and	al,0F0h
		cmp	al,30h
		pop	ax
		jne	ReadCLI
		push	ax
		mov	ax,DefAlignSize
		mov	bx,10
		mul	bx
		pop	bx
		and	bx,000Fh
		add	ax,bx
		mov	DefAlignSize,ax
		jmp	GetNextDigit

Toggle:
		mov	bl,byte ptr [SwitchHlp+di]
		xor	bl,1			; toggle switch
		dec	si			; char might be other switch
		inc	cx
SetSwitch:
		mov	byte ptr [SwitchHlp+di],bl
		jmp	GotSwitch
GotCommand:
		cmp	Command,0
		jne	GotFilename
		mov	di,offset Commands
		push	cx
		mov	cx,CommandsCnt
		repnz	scasb			; check for valid command
		pop	cx
		jne	GotFilename		; if not valid then filename
		mov	Command,al
		jmp	ReadCLI

EndLine:
		pop	es
		ret

ChildCL:	ASSUME	ds:NOTHING, es:DGROUP
		push	ds
		pop	es
		ASSUME	es:NOTHING
		mov	di,81h
ShrinkCL:
		lodsb
		stosb
		cmp	al,0Dh
		jne	ShrinkCL
		xchg	ax,di
		sub	ax,82h
		mov	ds:[80h],al
		jmp	EndLine

Help:		ASSUME	ds:NOTHING, es:DGROUP
		mov	ds,SegData
		ASSUME	ds:DGROUP
		mov	si,offset HelpText
		call	WriteLnASCIIZ

		mov	ch,CommandsCnt
		shr	ch,1
		adc	ch,0
		mov	cl,0
WriteComHelp:
		mov	si,offset CommandHelp
		mov	ax,HalveLineSz
		mul	cl
		add	si,ax
		call	WriteASCIIZ
		mov	si,offset space
		call	WriteASCIIZ
		mov	si,offset CommandHelp
		mov	ax,HalveLineSz
		mul	ch
		add	si,ax
		call	WriteLnASCIIZ
		add	cx,0101h
		mov	al,ch
		and	al,0FEh
		cmp	al,CommandsCnt
		jl	WriteComHelp

		mov	si,offset MoreHelpText
		call	WriteLnASCIIZ
		mov	ch,SwitchesCnt
		shr	ch,1
		adc	ch,0
		mov	cl,0
WriteHelp:
		mov	si,offset SwitchHelp
		mov	ax,HalveLineSz
		mul	cl
		add	si,ax
		mov	bl,cl
		mov	bh,0
		mov	bl,SwitchHlp[bx]
		mov	al,Swtch2Asc[bx]
		mov	ds:[si+2],al
		call	WriteASCIIZ
		mov	si,offset space
		call	WriteASCIIZ
		mov	si,offset SwitchHelp
		mov	ax,HalveLineSz
		mul	ch
		add	si,ax
		mov	bl,ch
		mov	bh,0
		mov	bl,SwitchHlp[bx]
		mov	al,Swtch2Asc[bx]
		mov	ds:[si+2],al
		call	WriteLnASCIIZ
		add	cx,0101h
		mov	al,ch
		and	al,0FEh
		cmp	al,SwitchesCnt
		jl	WriteHelp

EndHelp:
		mov	al,ECHELP
		jmp	Quit
.data
Commands	db	'CDEIL'
IFDEF MARKEXE
		db	'M'
ENDIF
		db	'OSTX'
CommandsCnt	equ	$ - offset Commands

HelpText	db	'usage: UNP command [options] [[d:][\path]Infile] [[d:][\path]Outfile]',CR,LF,LF
		db	'  commands:',0

CommandHelp label
		db	'c = convert to COM file                ',0
		db	'd = make current options default       ',0
		db	'e = expand compressed file (default)   ',0
		db	'i = show info only                     ',0
		db	'l = load and save                      ',0
IFDEF MARKEXE
		db	'm = MarkEXE, insert a file in header   ',0
ENDIF
		db	'o = copy overlay                       ',0
		db	's = search for compressed files        ',0
		db	't = trace executable                   ',0
		db	'x = convert to EXE file                ',0
		db	' ',0

MoreHelpText label
		db	LF,'  options followed by their current setting',0
SwitchHelp label
		db	'-? = help (this screen)                ',0
HalveLineSz	equ	$ - offset SwitchHelp
		db	'-a = automatic retry                   ',0
		db	'-b = make backup .BAK file of original ',0
		db	'-c = ask for confirmation before action',0
		db	'-f = optimize fixups (like HDROPT.EXE) ',0
		db	'-g = merge overlay into image          ',0
		db	'-h = remove irrelevant header data     ',0
		db	'-i = interception of I/O interrupts    ',0
		db	'-k = [-|+|?] pklite signature handling ',0
		db	'-l = use large memory block            ',0
		db	'-m = MORE alike output                 ',0
		db	'-n = numbered Outfiles                 ',0
		db      '-o = overwrite output file if it exists',0
		db	'-p = align header data on a page       ',0
		db	'-r = remove overlay data               ',0
IFDEF TBAV
		db	'-s = scan file for virus with TbScanX  ',0
ENDIF ;TBAV
		db	'-u = update file time/date             ',0
		db	'-v = verbose                           ',0
		db	'-- = program''s command line           ',0

space		db	' ',0
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
.code
HandleOptions:	ASSUME	ds:NOTHING, es:NOTHING
		push	ds
		mov	ds,SegData
		ASSUME	ds:DGROUP
		cmp	SwitchHlp,FALSE
		jne	Help
		cmp	SwitchP,FALSE
		je      EndOptions
		mov	DefAlignSize,0200h
EndOptions:
		cmp	FilenameCnt,0
		jne	EndFiles
		cmp	Command,0
		je	Help
		mov	di,offset Filename1
		mov	ax,'.*'			; append *.*
		stosw
		mov	ah,0
		stosw
		inc	FilenameCnt
EndFiles:
		pop	ds
		ret

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
.code
ReadUpCase:	ASSUME	ds:NOTHING, es:NOTHING
		lodsb
		dec	cx
		cmp	al,'a'
		jb	EndUpCase
		cmp	al,'z'
		ja	EndUpCase
		and	al,11011111b
EndUpCase:
		ret
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
.code
CheckFilenames:	ASSUME	ds:NOTHING, es:NOTHING
		mov	ax,AT_ARCHIVE+AT_READONLY
		call	SetSrchAttrib
		push	ds
		push	es
		mov	ds,SegData
		ASSUME	ds:DGROUP
		mov	es,SegData
		ASSUME	es:DGROUP
CheckIfAny:
		mov	dx,offset Filename1	; check for matching files
		call	FindFirst
		jc	CheckIfDir		; none, check if dir
		call	FindNext
		mov	al,0
		adc	al,0
		xor	al,1
		mov     MoreThan1,al
		or	al,al
		jne	CheckIgnore
		mov	dx,offset Filename1	; Reload matching file
		call	FindFirst
		mov	si,offset Filename1	; replace wildcard with name
		call    FindFilename
		mov	si,offset DTA_Filename
		mov	cx,13
		repnz	movsb
CheckIgnore:
		mov	al,Command		; ignore outfile commands?
		cmp	al,'I'
		je	OnlyInfile
		cmp	al,'S'
		je	OnlyInfile
		cmp	FilenameCnt,1
		je	NoOutfile

		mov	si,offset Filename2	; outfile contains ? or *
		call	CheckWild
		jc	OutfileError

		mov	si,offset Filename1	; check if name1 = name 2
		mov	di,offset Filename3
		mov	ah,60h
		int	21h
		mov	di,offset Filename2
		cmp	byte ptr [Filename3],0
		je	CompareName
		mov	si,di
		mov	di,offset Filename5
		mov	ah,60h
		int	21h
		mov	si,offset Filename3
CompareName:
		cmpsb
		jne	HaveOutfile
		cmp	byte ptr [si-1],0
		jne	CompareName
		mov	si,offset WAR_SameName	; delete outfile
		call	Warning
		dec	FilenameCnt
NoOutfile:
		cmp	Command,'O'		; no outfile
		je	No2Names
		cmp	Command,'M'		; markexe
		jne	BNConflict
No2Names:
		mov	si,offset TwoNamesReq
		call	WriteLnASCIIZ
		mov	al,ECINVALIDCL
		jmp	Quit

HaveOutfile:
		cmp	MoreThan1,1
		je	ManyInOne
		cmp	SwitchB,FALSE
		je	BNConflict
		mov	si,offset WAR_IgnoreB
		call	Warning
		mov	SwitchB,FALSE
		jmp	BNConflict

CheckIfDir:
		mov	si,offset Filename1
		call	CheckWild
		jc	CheckExec
		mov	ax,AT_ARCHIVE+AT_READONLY + AT_DIRECTORY
		call	SetSrchAttrib
		mov	dx,offset Filename1
		call	FindFirst
		pushf
		mov	ax,AT_ARCHIVE+AT_READONLY
		call	SetSrchAttrib
		popf
		jc	CheckExec
		mov	di,offset Filename1
		mov	cx,-1
		mov	al,0
		repnz	scasb
		dec	di
		mov	ax,'*\'
		stosw
		mov	ax,'*.'
		stosw
		mov	al,0
		stosb
		jmp	CheckIfAny

CheckExec:
		mov	si,offset Filename1
		call	FindExtention
		cmp	byte ptr [di-1],':'
		je	IsPath
		cmp	byte ptr [di-1],'\'
		je	IsPath
		cmp	byte ptr [di],'.'
		je	NoFilesFound
		mov	ax,'*.'
		stosw
		mov	al,0
		stosb
		mov	al,TRUE
		call	SetExecOnly		; set STDIOs ExecOnly flag
		jmp	CheckIfAny
IsPath:
		mov	ax,'.*'
		stosw
		mov	ah,0
		stosw
		jmp	CheckIfAny

NoFilesFound:
		mov	si,offset NoFiles
		call	WriteASCIIZ
		mov	si,offset Filename1
		call	WriteLnASCIIZ
		mov	al,ECINVALIDCL
		jmp	Quit


ManyInOne:
		mov	si,offset ManyFiles
		call	WriteLnASCIIZ
		mov	al,ECINVALIDCL
		jmp	Quit

OutfileError:
		mov	si,offset WildcardErr
		call	WriteLnASCIIZ
		mov	al,ECINVALIDCL
		jmp	Quit

OnlyInfile:
		mov	FilenameCnt,1
BNConflict:
		cmp     SwitchB,FALSE
		je	OutfileOk
		cmp	SwitchN,FALSE
		je	OutfileOk
		mov	si,offset WAR_BNconflict
		call	Warning
		mov	SwitchB,FALSE
OutfileOk:
		pop	es
		ASSUME	es:NOTHING
		pop	ds
		ASSUME	ds:NOTHING
		ret

CheckWild:
		lodsb
		cmp	al,0
		je	NoWildCards
		cmp	al,'*'
		je	GotWildcards
		cmp	al,'?'
		jne	CheckWild
GotWildcards:
		stc
		ret
NoWildCards:
		clc
		ret

.data
Filename5	db	128 dup (0)
MoreThan1	db	FALSE
NoFiles 	db	'FATAL ERROR - No files found matching ',0
WAR_SameName	db	'Infile and Outfile are same, Outfile ignored.',0
WAR_IgnoreB 	db	'Outfile specified, -B option ignored.',0
WAR_BNconflict	db	'-N option overrules -B option, -B option ignored',0
ManyFiles	db	'FATAL ERROR - Decompressing many files into one.',0
WildcardErr	db	'FATAL ERROR - Output path/file must not contain ''*'' or ''?''.',0
TwoNamesReq	db	'FATAL ERROR - Outfile required for specified command.',0
NoNamesReq	db	'FATAL ERROR - Specified command does not require filenames.',0
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
.code
SetDefCmmnd:	ASSUME	ds:NOTHING, es:NOTHING
		push	ds
		mov	ds,SegData
		ASSUME	ds:DGROUP
		cmp	Command,0
		jne	GotSomething
		cmp	FilenameCnt,0
		je      Help
		mov	Command,'E'
GotSomething:
		pop	ds
		ASSUME	ds:NOTHING
		ret
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
.code
SetupMemory:	ASSUME	ds:NOTHING, es:NOTHING, ss:NOTHING
		push	ds
		mov	ds,SegData
		ASSUME	ds:DGROUP

		call	GetUMBState		; get UMB chain state
		mov	ah,1
		mov	UMBState,ax

		call	GetMemStrategy		; get mem allocation strategy
		mov	ah,1h
		mov	MemStrategy,ax

		mov	bl,01h			; inlude UMB in memory chain
		call	SetUMBState

		mov	bl,MSHLBestFit		; set new allocation strategy
		call	SetMemStrategy

		call    GetFreeMem
		call    AllocateMem
		add     bx,ax
		mov     SegHMAStart,bx
		push    es
		mov     es,ax
		call    FreeMem
		pop     es
		pop	ds
		ret
.data
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
.code
BuildTempfile:	ASSUME	ds:NOTHING, es:NOTHING, ss:NOTHING
		push	ds			; save DS
		push	es

		mov	ax,cs
		sub	ax,10h
		mov	es,ax
		ASSUME	es:NOTHING
		mov	es,word ptr es:[002Ch]
		ASSUME	es:NOTHING

		mov	ds,SegData
		xor	di,di
		mov	al,0
CheckEnv:
		cmp	es:[di],al		; end of environment ?
		je	NoTempEnv
		mov	cx,VarTempSz		; check if "TEMP=" found
		mov	si,offset VarTemp
		repz	cmpsb
		je	CopyTempEnv
		mov	ch,10h
		repnz	scasb			; go to next variable
		jmp	CheckEnv

CopyTempEnv:
		push	es
		pop	ds			; DS=environment segment
		ASSUME	ds:NOTHING
		mov	es,SegData
		ASSUME	es:DGROUP
		mov	si,di
		mov	di,offset Filename4	; ES:DI=filename location
CopyTempChar:
		call	ReadUpCase
		or	al,al
		je	AppendName
		stosb
		jmp	CopyTempChar

NoTempEnv:
		mov	es,SegData
		ASSUME	es:DGROUP
		mov	di,offset Filename4	; ES:DI=filename location
		jmp	CopyTempName
AppendName:
		cmp	byte ptr es:[di-1],';'	; special code for
		jne	TempOk			; the ; guy
		dec	di			; allow trailing ";"s in
		jmp	AppendName		; TEMP variable
TempOk:
		mov	al,'\'
		cmp	byte ptr es:[di-1],al
		je	CopyTempName
		cmp	byte ptr es:[di-1],':'
		je	CopyTempName
		stosb
CopyTempName:
		mov	ds,SegData
		ASSUME	ds:DGROUP
		mov	si,offset TempName
		mov	cx,TempNameSz
		repnz	movsb
		mov	ax,cs
		sub	ax,10h
		mov	es,ax
		ASSUME	es:NOTHING
		mov	es,word ptr es:[002Ch]
		ASSUME	es:NOTHING
		call	FreeMem			; release environment
		pop	es
		ASSUME	es:NOTHING
		pop	ds			; restore DS
		ASSUME	ds:NOTHING
		ret

.data
VarTemp 	db	'TEMP='
VarTempSz	equ	$ - offset VarTemp

TempName	db	TMPFile
TempNameSz	equ	$ - offset TempName
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
.code
FreeConvMem:	ASSUME	ds:NOTHING, es:NOTHING, ss:NOTHING
		push	es
		mov	ax,SegData
		mov	bx,cs
		sub	bx,10h
		mov	es,bx
		ASSUME	es:NOTHING
		sub	ax,bx
		mov	bx,offset EndInitData
		shr	bx,4
		add	bx,ax
		inc	bx
		call	ResizeMem
		pop	es
		ASSUME	es:NOTHING
		ret
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
.code
ReadFilenames:	ASSUME	ds:NOTHING, es:NOTHING, ss:NOTHING
		push	ds
		push	es
		mov	bx,1000h
		mov	si,offset MemFiles
		call	AllocateMem
		mov	ds,SegData
		ASSUME	ds:DGROUP
		mov	es,ax
		ASSUME	es:NOTHING
		xor	di,di
		mov	SegFiles.A,ax
		mov	dx,offset Filename1
		call	FindFirst
		xor	bp,bp
StoreName:
		inc	bp
		call	FindNext
		jc	FilesSegAdj
		mov	si,offset DTA_Filename
		mov	cx,12
CopyChar:
		lodsb
		stosb
		or	al,al
		loopne	CopyChar
		jmp	StoreName
FilesSegAdj:
		mov	ax,di
		mov	bx,ax
		shr	bx,4
		and	ax,0Fh
		cmp	ah,al
		adc	bx,0
		mov	SegFiles.S,bx
		call	ResizeMem
		mov	FilesFound,bp

		pop	es
		ASSUME	es:NOTHING
		pop	ds
		ASSUME	ds:NOTHING
		ret
.data
MemFiles	db	'to store filenames.',0
DataSegSz	dw	0
ProgSegSz	dw	0
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
.code
RelocateMem:	ASSUME	ds:NOTHING, es:NOTHING, ss:NOTHING
		push	ds
		push	es
		mov	ds,SegData
		ASSUME	ds:DGROUP

		mov	ax,offset DataEnd	; get data size
		mov	bx,ax
		shr	bx,4
		and	ax,0Fh
		cmp	ah,al
		adc	bx,0
		mov	DataSegSz,bx
		mov	ax,SegData
		call	FindMem
		mov	NewSegData,ax

		mov	cx,offset Init
		mov	bx,cx
		shr	bx,4
		and	cx,0Fh
		cmp	ch,cl
		adc	bx,0
		cmp	ax,SegData		; no move ?
		jne	CalcSize
		mov	NewSegData,bx
		mov	ax,cs
		add	NewSegData,ax
		add	bx,DataSegSz
CalcSize:
		add	bx,10h			; size PSP in paragraphs
		mov	ProgSegSz,bx
		mov	bx,SegFiles.S
		mov	ax,SegFiles.A
		call	FindMem
		cmp	ax,SegFiles.A
		je	NoFilesMove
		mov	es,ax
		ASSUME	es:NOTHING
		mov	cx,SegFiles.S
		mov	ds,SegFiles.A
		ASSUME	ds:NOTHING
		shl	cx,3
		xor	si,si
		xor	di,di
		repnz	movsw
		mov	ds,SegData
		ASSUME	ds:DGROUP
		mov	es,SegFiles.A
		mov	SegFiles.A,ax
		call	FreeMem
NoFilesMove:
		pop	es
		ASSUME	es:NOTHING
		pop	ds
		ASSUME	ds:NOTHING
		ret

FindMem:	ASSUME	ds:NOTHING, es:NOTHING
		mov	ds,SegData
		ASSUME	ds:DGROUP
		mov	cx,ax
		mov	si,offset ME_BasicOp
		call	AllocateMem
		cmp	ax,SegHMAStart
		ja	EndReloc
		mov	dx,cs
		cmp	ax,dx
		jb	EndReloc
		push	es
		mov	es,ax
		ASSUME	es:NOTHING
		call	FreeMem
		pop	es
		mov	ax,cx
EndReloc:
		ret

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
.code
Specials:	ASSUME	ds:NOTHING, es:NOTHING
		push	ds
		push	es

		mov	es,SegData
		ASSUME	es:DGROUP

		mov	ah,30h			; get dos version
		int	21h
		mov	RealDosVersion,ax
IFDEF NOHACK
		xor	ax,ax
		mov	ds,ax
		mov	ax,ds:[046Ch]
		mov	ds,SegPSP
		sub	ax,ds:[007Eh]
		jnc	AnalyzeHack
		neg	ax
AnalyzeHack:
		mov	TimerTicks,ax
IFDEF DEBUG
		mov	si,offset INF_HackTime
		call	WriteASCIIZ
		xor	dx,dx
		call	WriteLongInt
		call	WriteLn
.data
INF_HackTime	db	'HACK - Timerticks passed : ',0
ENDIF ;DEBUG

.data
TimerTicks	dw	0
.code
ENDIF ;NOHACK
		pop	es
		pop	ds

IFDEF TBAV
.code
		mov	cl,FALSE
		cmp	SwitchS,cl
		je	EndTBAV
		mov	ax,0CA00h
		mov	bx,'TB'
		int	2Fh
		cmp	al,0FFh
		jne	EndTBAV
		cmp	bx,'tb'
		jne	EndTBAV
		mov	cl,TRUE
EndTBAV:
		mov	SwitchS,cl		; SwitchS=1 (use scanner)
ENDIF ;TBAV
		ret

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
.code
DebugInfo:	ASSUME	ds:NOTHING, es:NOTHING, ss:NOTHING
		push	ds
		mov	ds,SegData
		ASSUME	ds:DGROUP
		mov	es,SegData
		ASSUME	es:DGROUP
		cmp	SwitchV,FALSE
		je	EndInfo
		mov	ax,RealDosVersion
		or	al,30h
		mov	MajorVersion,al
		mov	al,ah
		aam
		or	ax,3030h
		xchg	ah,al
		mov	word ptr MinorVersion,ax
		mov	si,offset Info1
		call	Info

		mov	ax,1600h		; check for Windows
		int	2Fh
		cmp	al,0
		je	Wcheck2
		cmp	al,80h
		jne	IsWin
Wcheck2:
		mov	ax,1700h
		int	2Fh
		cmp	ax,1700h
		je	CheckTBAV
IsWin:
		mov	si,offset IsWinTxt
		call	WriteASCIIZ

CheckTBAV:
		call	WriteLn
IFDEF TBAV
		cmp	SwitchS,FALSE
		je	ShowCLI
		mov	si,offset INF_TBAV
		call	Info
		call	WriteLn
.data
INF_TBAV        db	'Anti-virus program TbScanX detected.',0
.code
ENDIF ;TBAV

ShowCLI:
		mov	al,Command
		mov	Cmmnd,al
		mov	si,offset Info2		; echo the commandline
		call	Info
		mov	cx,SwitchesCnt -1	; skip the '-' switch
		mov	di,offset Switches
		mov	si,offset SwitchHlp
NextSwitch:
		lodsb
		mov	ah,[di]
		inc	di
		or	al,al
		je	ToNextSwitch
		mov	SwitchChar,ah
		mov	SwitchSub,0
		cmp	ah,'K'
		je      ExtendedSwitch
IFDEF DEBUG
		cmp	ah,'V'
		je      ExtendedSwitch
ENDIF
		jne	WriteSwitch
ExtendedSwitch:
		mov	bl,al
		xor	bh,bh
		mov	bl,Swtch2Asc[bx]
		mov	SwitchSub,bl
WriteSwitch:
		push	si
		mov	si,offset Switch
		call	WriteASCIIZ
		pop	si
ToNextSwitch:
		loop	NextSwitch
		mov	SwitchSub,' '
		mov	si,offset SwitchSub
		call	WriteASCIIZ
		mov	si,offset Filename1
		call	WriteASCIIZ
		cmp	FilenameCnt,2
		jne	WriteLine2
		mov	si,offset SwitchSub
		call	WriteASCIIZ
		mov	si,offset Filename2
		call	WriteASCIIZ
WriteLine2:
		mov	si,offset EndLine2
		call	WriteLnASCIIZ
		push	ds
		mov	ds,SegPSP
		ASSUME	ds:NOTHING
		cmp	ds:[80h],0D00h
		je	WriteLine3
		mov	si,offset Info2b	; echo the commandline
		call	Info
		mov	si,81h
		mov	di,offset Filename3		; temp buffer
CopyCCL:
		lodsb
		cmp	al,0Dh
		je	EndCCL
		stosb
		jmp	CopyCCL
EndCCL:
		mov	al,0
		stosb
		mov	si,offset Filename3
		call	WriteASCIIZ
		mov	si,offset EndLine2
		call	WriteLnASCIIZ

WriteLine3:
		pop	ds
		ASSUME	ds:DGROUP
		mov	si,offset Info3
		call	Info
		mov	si,offset Filename4
		call	WriteASCIIZ
		mov	si,offset Info32
		call	WriteLnASCIIZ

		mov	si,offset Info4
		call	Info
		xor	dx,dx
		mov	ax,FilesFound
		call	WriteLongInt
		mov	si,offset Info42
		call	WriteASCIIZ
		mov	ax,SegFiles.A
		call	WriteHexWord
		mov	si,offset Info43
		call	WriteLnASCIIZ



		mov	si,offset Info5
		call	Info
		mov	ax,cs
		sub	ax,10h
		call	WriteHexWord
		mov	si,offset Info52
		call	WriteASCIIZ

EndInfo:
		pop	ds
		ret

.data
Swtch2Asc	db	'-+?? '
RealDosVersion	dw	0
NewSegData	dw	0
Info1		db	'DOS Version '
MajorVersion	db	' .'
MinorVersion	db	'  ',0
IsWinTxt	db	', running under Windows.',0
Info2		db	'Commandline = "'
Cmmnd		db	0,0
Info2b		db	'Program''s commandline = "',0
Switch		db	' -'
SwitchChar	db	0
SwitchSub	db	0,0
EndLine2	db	'".',0
Info3		db	'Using ',0
Info32		db	' as temp file.',0
Info4		db	'Wildcard matches ',0
Info42		db	' filename(s), stored at ',0
Info43		db	'h.',0
Info5		db	'Program loaded at ',0
Info52		db	'h, largest free memory block: ',0


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
.code
HookInts:	ASSUME	ds:NOTHING, es:NOTHING, ss:NOTHING
		push	ds			; save DS
		mov	ds,SegData
		ASSUME	ds:DGROUP
		mov	ah,35h
		mov	si,offset HookedInts
		xor	di,di
		mov	cx,HookedIntsCnt
GetInt:
		lodsb
		int	21h
		mov	[offset OldInts+di],bx
		mov	[offset OldInts+2+di],es
		add	di,4
		loop	GetInt
		mov	IntsCopied,TRUE
		push	cs
		pop	ds
		ASSUME	ds:NOTHING
		mov	ax,2500h + INTGS
		mov	dx,offset BreakGS	; Grab Size
		int	21h
		mov	ax,2500h + INTGI
		mov	dx,offset BreakGI	; Grab Item
		int	21h
		mov	ax,2500h + INTQT
		mov	dx,offset BreakQT	; Quit
		int	21h
		mov	ax,2500h + INTEP
		mov	dx,offset BreakEP	; Extra breakPoint
		int	21h
		mov	ax,2500h
		mov	dx,offset BreakDZ       ; Divide by Zero
		int	21h
		mov	ax,2523h
		mov	dx,offset BreakCC	; Ctrl-C
		int	21h
		mov	es,SegData
		ASSUME	es:DGROUP
		cmp	SwitchI,FALSE
		je	GotIntsHooked
		mov	dx,offset Break10
		mov	ax,2510h
		int	21h
		mov	dx,offset Break20
		mov	ax,2520h
		int	21h
		mov	dx,offset Break21
		mov	ax,2521h
		int	21h
GotIntsHooked:
		pop	ds			; restore DS
		ret
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
.code
GetInt21:	ASSUME	ds:NOTHING, es:NOTHING, ss:NOTHING
		push	ds			; save DS
		mov	ds,SegData
		ASSUME	ds:DGROUP
		mov	ax,3521h
		int	21h
		mov	OldInt21,bx
		mov	OldInt21+2,es
		pop	ds
		ret
.data
EndInitData	label
end Init