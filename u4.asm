include compiler.h				; include standard settings
include version.h

include mem.h
include stdio.h
include find.h
include string.h

.code
extrn Init: near				; INIT.ASM
.data
extrn DataEnd
extrn Silent

public AskPassword
public Password
public SegData
public SetDTA
public Quit

public BreakCC
public BreakDZ
public BreakEP
public BreakGS
public BreakGI
public BreakQT
public Break10
public Break20
public Break21

public DefAlignSize
public ME_BasicOp
public Command
public Continue
public DTABlock
public DTA_Filename
public File1NmePtr
public Filename1
public Filename2
public Filename3
public Filename4
public FilenameCnt
public FilesFound
public HookedInts
public HookedIntsCnt
public Info
public IntsCopied
public MemStrategy
public OldInts
public OldInt21
public SegFiles
public SegHMAStart
public SegPSP
public Switches
public SwitchB
public SwitchI
public SwitchM
public SwitchN
public SwitchP
IFDEF TBAV
public SwitchS
ENDIF ;TBAV
public SwitchV
public SwitchesCnt
public SwitchHlp
public UMBState
public Warning

int21h macro
		pushf
		call	dword ptr OldInt21
endm

.code
EntryPoint:	ASSUME	ds:NOTHING, es:NOTHING, ss:NOTHING
		mov	ax,DGROUP		; segments values
		mov	SegData,ax
		mov	SegStack,ax
		cli
		mov	ss,SegStack
		mov	sp,offset StackLoc
		sti
		call	Init
		repnz	movsw
		ASSUME	ds:NOTHING, es:NOTHING
		mov	SegData,es
		mov	SegStack,es
		push	cs
		pop	ax
		sub	ax,10h
		mov	es,ax
		call	ResizeMem
		mov	ds,SegData
		ASSUME	ds:DGROUP
		cmp	SwitchV,FALSE
		je	SetSilent
		call	GetFreeMem
		mov	ax,bx
		mul	ParSize
		call	WriteLongInt
		mov	si,offset Info53
		call	WriteLnASCIIZ
		call	WriteLn
SetSilent:
		cmp	Command,'S'
		jne	ProcessFile
		mov	Silent,TRUE

ProcessFile:
		cli			    	; initialize
		mov	ss,SegStack
		mov	sp,offset StackLoc
		sti
		mov	ds,SegData
		ASSUME	ds:DGROUP
		mov	es,SegData
		ASSUME	es:DGROUP

IFDEF DEBUG
		cmp	SwitchV,ASK
		jne	Initialize

include mapmem.asm
		ASSUME	ds:DGROUP,es:DGROUP
Initialize:
ENDIF
		mov	ax,FALSE
		mov	di,offset InitArea
		mov	cx,InitSize
		repnz	stosb

		mov	ExpectedInts,offset NoInts
		mov	Int10Routine,offset Int10Def
		mov	Int20Routine,offset Int20Def
		mov	Int21Routine,offset Int21Def
		mov	GetProgSize,offset GS_ESDI
		mov	SetFixupRegs,offset GI_ESDI
		mov	HeaderBuild,offset HBCreate
		mov	ax,DefAlignSize
		mov	AlignmentSize,ax

		mov	dx,offset DTABlock	; set DTA
		call	SetDTA

		mov	dx,offset Filename1
		call	FindFirst
		mov	si,offset ProcessTxt
		call	WriteASCIIZ
		mov	si,offset Filename1
		call	WriteLnASCIIZ
		mov	si,offset SizeTxt
		call	WriteASCIIZ
		mov	ax,DTA_FileSize
		mov	dx,DTA_FileSize+2
		call	WriteLongInt
		mov	ax,DTA_FileTime
		mov	InfileTime,ax
		mov	ax,DTA_FileDate
		mov	InfileDate,ax
		call	WriteLn

IFDEF TBAV
		cmp	SwitchS,FALSE
		je	EndScan
		mov	ax,0CA04h
		mov	dx,offset Filename1
		int	2Fh
		ASSUME	es:NOTHING
		jnc	EndScan

		push	es			; offset name of virus found
		push	bx
		mov	si,offset WarningTxt
		call	WriteASCIIZ
		mov	si,offset HaveVirus
		call	WriteASCIIZ
		mov	es,SegData
		mov	di,offset Filename3
		pop	si
		pop	ds
		ASSUME	ds:NOTHING
		mov	cx,64
		repnz	movsw
		mov	ds,SegData
		ASSUME	ds:DGROUP
		mov	si,offset Filename3
		call	WriteLnASCIIZ
		mov	si,offset ASK_continue
		call    GetYorN
		jne	Continue

.data
HaveVirus	db	'TbScanX reports file infected with ',0
.code
EndScan:
ENDIF ;TBAV
		mov	bx,128/16 + 1		; create environment
		mov	si,offset ME_ChildEnv
		call	AllocateMem
		mov	SegProgEnv,ax
		mov	es,ax
		ASSUME	es:NOTHING
		mov	si,offset Filename1
		xor	di,di
		xor	ax,ax
		stosw
		inc	ax
		stosw
		mov	cx,128/2
		repnz	movsw

		mov	dx,offset Filename1	; read first 40h bytes
		call	OpenFile
		mov	Handle1,ax
		mov	si,offset FileStrucTxt
		call	WriteASCIIZ
		mov	dx,offset ORIG
		mov	cx,040h
		call	ReadFile
		mov	si,offset data_file$	; assume data file
		or	ax,ax
		je	WrongStruc		; if 0 bytes read > data file
		xor	ax,ax
		xor	dx,dx
		call	MovePointer
		cmp	word ptr [ORIG],'MZ'
		je	IsExe
		cmp	word ptr [ORIG],'ZM'
		je	IsExe

		mov	si,offset data_file$	; assume data file
		cmp	DTA_FileSize+2,0
		jne	WrongStruc
		cmp	DTA_FileSize,0FF00h
		ja	WrongStruc
		mov	si,offset BinaryTxt	; file is COM
		call	WriteLnASCIIZ

		call	GetFreeMem		; allocate largest block
		call	AllocateMem
		cmp	bx,0100h
		jae	SetPSP
LoadError:
		mov	bx,0FFFFh		; allocate block of impossible
		mov	si,offset ME_NoLoad	; size to force mem error
		call	AllocateMem
		jmp	Quit			; should not be necesary
SetPSP:
		mov	SegProgPSP,ax
		add	ax,010h
		call	CreatePSP		; size optimisation
		ASSUME	ds:NOTHING,es:DGROUP

		mov	bx,Handle1
		xor	dx,dx
		mov	cx,0FFFFh
		call	ReadFile
		mov	ProgFinalOfs,ax
		mov	ProgFinalSeg,ds
		push	ax
		call	CloseFile
		pop	ax
		mov	di,ax
		neg	ax
		mov	cx,ax
		push	es
		push	ds
		pop	es
		shr	cx,2
		shl	cx,1			; CPU optimisation
		repnz	stosw
		pop	es
		jmp	ComHandling

IsExe:          ASSUME  ds:DGROUP, es:NOTHING
                mov     si,offset ExecutableTxt
                cmp     [ORIG.RelocOffs],0040h
		jb      NormalExe
		mov	bx,Handle1
		mov     ax,word ptr [ORIG+3Ch]
		mov     dx,word ptr [ORIG+3Eh]
		call    MovePointer
		push    si
		mov     si,offset ORIG
		mov     dx,si
		mov     word ptr [si],0
		mov     cx,2
		call	ReadFile
;		call	CloseFile
		lodsw
		pop     si
		cmp     ax,'EN'
		je      NewExecutable
		cmp     ax,'EL'
		je      NewExecutable
		cmp     ax,'XL'
		je      NewExecutable
		cmp     ax,'3W'
		je      NewExecutable
		cmp     ax,'EP'
		jne     NormalExe

NewExecutable:
		mov     NESig,ax
		mov     si,offset New_Executable$

NormalExe:
		mov	ax,ORIG.SizeDiv512
		mov	dx,ORIG.SizeMod512
		call	ToNormal
		xchg	bx,ax
		xchg	cx,dx
		mov	ax,DTA_FileSize
		mov	dx,DTA_FileSize+2
		sub	ax,bx
		sbb	dx,cx
		mov 	ExeOverlaySz,ax
		mov 	ExeOverlaySz+2,dx

		cmp	ORIG.RelocItemsCnt,0	; no relocations
		jne	CheckLH
		cmp	ORIG.InitialCS,0FFF0h	; segment FFF0
		jne	CheckLH
		cmp	ORIG.InitialIP,0100h	; entrypoint 0100h
		jne	CheckLH

		mov	ax,ExeOverlaySz		; no overlay
		mov	dx,ExeOverlaySz+2
		or	dx,ax
		jne	CheckLH
		call	WriteASCIIZ
		mov	si,offset IsConvEXE$
CheckLH:
		cmp	ORIG.MinParMem,0 	; check if highload exe
		jne	CheckCommand
		cmp	ORIG.MaxParMem,0
		jne	CheckCommand
		call	WriteASCIIZ
		mov	si,offset IsLoadHigh$
		inc	HighloadEXE		; mov HighloadEXE,TRUE
CheckCommand:
		call	WriteLnASCIIZ
		mov     si,offset ExeSizes
		call    WriteASCIIZ
		mov     ax,ORIG.HeaderSz
		mov     bx,10h
		mul     bx
		mov	ExeHeaderSz,ax
		mov	ExeHeaderSz+2,dx
		push    ax
		push    dx
		call    WriteLongInt
		mov     si,offset ExeSizes2
		call    WriteASCIIZ

		mov     ax,ORIG.SizeDiv512
		mov     dx,ORIG.SizeMod512
		call	ToNormal
		pop     bx
		pop     cx
		sub     ax,cx
		sbb     dx,bx
		mov	ExeImageSz,ax
		mov	ExeImageSz+2,dx
		call    WriteLongInt
		mov     si,offset ExeSizes3
		call    WriteASCIIZ
		mov     ax,ExeOverlaySz
		mov     dx,ExeOverlaySz+2
		call    WriteLongInt
		mov     si,offset ExeSizes4
		call    WriteLnASCIIZ
		cmp	SwitchV,FALSE
		je	ExeHandling
		mov	si,offset ExeSizes5
		call	Info
		mov	ax,ORIG.RelocItemsCnt
		xor	dx,dx
		call	WriteLongInt
		mov	si,offset ExeSizes6
		call	WriteASCIIZ
		mov	si,offset ExeSizes7
		cmp	ORIG.RelocItemsCnt,1
		jne	WriteInfo7
		inc	si
WriteInfo7:
		call	WriteASCIIZ
		mov	ax,ORIG.MinParMem
		mov     bx,10h
		mul     bx
		add	ax,ExeImageSz
		adc	dx,ExeImageSz+2
		call	WriteLongInt
		mov	si,offset ExeSizes8
		call	WriteLnASCIIZ
		jmp	ExeHandling

WrongStruc:
		call	WriteLnASCIIZ
		mov	bx,Handle1
		call	CloseFile
		jmp	Continue

;/* --- handling of COM files --- */

ComHandling:	ASSUME	ds:NOTHING, es:NOTHING
		mov	ds,SegData
		ASSUME	ds:DGROUP
		cmp	Command,'C'		; convert to COM
		jne	ChckOCmd
		mov	si,offset TC_iscom
		call	Error
		jmp	Continue

ChckOCmd:	cmp	Command,'O'
		jne	ChckLCmd
		xor	ax,ax
		xor	dx,dx
		jmp	CmdOverlay

ChckLCmd:       cmp	Command,'L'
		jne	UnpackCom
		mov	es,SegProgram
		ASSUME	es:NOTHING
		mov	di,DTA_FileSize
		jmp	ComWrite


UnpackCom:      ASSUME	ds:DGROUP,es:NOTHING
		xor	ax,ax			; set up registers
		mov	RegAX,ax
		mov	RegBX,ax
		mov	RegCX,ax
		mov	RegDX,ax
		mov	RegSI,ax
		mov	RegDI,ax
		mov	RegBP,ax
		mov	RegSP,0FFFEh
		mov	ax,SegProgPSP
		mov	RegDS,ax
		mov	RegES,ax
		mov	RegSS,ax
		mov	RegCS,ax
		mov	RegIP,0100h
		pushf
		pop	Flags

		cmp     Command,'T'
		je	SingleStep

		cmp	Command,'X'
		jne	CheckCOM
		mov	si,offset ACT_toexe
		call	Action
		mov	TotalMem,EXTRAMEM
		mov	RegSP,0
		mov	si,offset ACT_done
		call	WriteLnASCIIZ
		jmp	HBCreate

CheckCOM:	ASSUME	ds:NOTHING,es:NOTHING
		mov	es,SegData
		ASSUME	es:DGROUP
		mov	ds,RegCS
		ASSUME	ds:NOTHING
		xor	ax,ax
		mov	ProgFinalOfs,ax
		mov	ProgFinalSeg,ax
		mov	word ptr ds:[0FFFEh],ax
		mov	si,RegIP
		lodsb
		cmp	al,0E9h
		jne	cNoInitJmp
		lodsw
		add	ax,si
		mov	RegIP,ax

		call	CCPAV_entry		; add on (anti-virus)
		call	CSLFD_entry		; add on (anti-virus)
		call	CNTBD_entry		; add on (anti-virus)
		call	CPOJC_entry		; add on (anti-virus)
		call	CBWFP_entry		; add on (encryption/pwd)
		call	CC2CR_entry		; add on (encryption)
		call	CCRCM_entry		; add on (encryption)
		call	CMCLK_entry		; add on (encryption)
		call	CTPCS_entry		; add on (encryption)
		call	CCRPT_entry		; add on (encryption)
		call	CUSRN_entry		; add on (encryption/pwd)
		call	CEPW_entry              ; add on (encryption/pwd)
		call	CCOML_entry
		call	CPROT_check40
		jmp	cNotFound

cNoInitJmp:
		call	CSCRM_entry		; add on (encryption)
		call	CNTCH_entry		; add on (intro)
		call	CXLCK_entry		; add on (anti-virus)
		call	CSYRN_entry		; add on (anti-virus)
		call	CSPRT_entry		; add on (password)
		call	CPKLT_entry
		call	CDIET_entry
		call	CSCRN_entry
		call	CCMPK_entry
		call	CPPCK_entry
		call	CICE_entry
		call	CSHRN_entry
		call	CPRCM_entry
		call	CPSWD_entry
		call	CPROT_entry		; V1.0 - V3.1
		call	CELIT_entry
		call	CSPCM_entry
IFDEF RARE
		call	CU173_entry
		call	CCMPR_entry
ENDIF
		call	CSCAN_entry		; data
cNotFound:
		jmp	Continue

SingleStep:
		mov	si,offset ACT_tracing
		call	Action
		push	cs
		pop	ds
		ASSUME	ds:NOTHING
		mov	dx,offset SS_int
		mov	ax,2501h
		int21h
		mov	bx,01h
		call	AllocateMem
		mov	es,ax
		xor	di,di
		xor	si,si
		mov	ds,si
		mov	cx,08
		repnz	movsw
		mov	ds,SegData
		ASSUME	ds:DGROUP
		mov	SegProgInts,ax

		or	Flags,TF		; set Trace Flag
		xor	ax,ax
		mov	LastDIValue,ax
		mov	HighestDI,ax
		mov	Counting,al
		mov	InstrCnt,ax
		mov	InstrCnt+2,ax
		mov	LowestIP,-1
		mov	Int10Routine,offset Int10Trc
		mov	Int21Routine,offset Int21Trc
		jmp	Execute


SS_int:		ASSUME	ds:NOTHING, es:NOTHING
		mov	wTemp,ds
		mov	ds,SegData
		ASSUME	ds:DGROUP
		pop	RegIP
		pop	RegCS
		pop	Flags
		mov	RegAX,ax
		mov	ax,wTemp
		mov	RegDS,ax
		mov	RegBX,bx
		mov	RegCX,cx
		mov	RegES,es
		add     InstrCnt,1
		jnc	SS_GetRegs

		push	dx
		push	si
		push	di
		push	bp
		mov	InProgram,FALSE
		inc	InstrCnt+2		; update screen
		mov	ax,InstrCnt
		mov	dx,InstrCnt+2
		call	WriteLongInt
		mov	si,offset CRAct
		call	WriteASCIIZ
		mov	si,offset ACT_tracing
		call	WriteASCIIZ
		mov	InProgram,TRUE
		pop	bp
		pop	di
		pop	si
		pop	dx

SS_GetRegs:
		mov	ax,RegCS
		push	es
		mov	es,ax
		mov	bx,RegIP
		mov	bx,es:[bx]		; get next instruction
		pop	es
		mov	ch,3
		cmp	bl,0CCh			; int 03 ?
		je	SS_FakeInt
		cmp	bl,0CDh			; is int?
		jne	SS_CalcReg
		mov	ch,bh
		cmp	ch,03h			; int 03 or lower ?
		ja	SS_CalcReg
SS_FakeInt:
		inc	RegIP
		and	bx,1
		add	RegIP,bx		; skip int!
		mov	bl,ch
		shl	bx,2
		push	Flags
		push	RegCS
		push	RegIP
		push	Flags			; fake int 01 call!
		mov	ds,SegProgInts
		ASSUME	ds:NOTHING
		push	ds:[bx+2]
		push	ds:[bx]
		mov	ds,SegData
		ASSUME	ds:DGROUP
		mov	ax,RegAX
		mov	bx,RegBX
		mov	cx,RegCX
		mov	es,RegES
		mov	ds,RegDS
		iret

SS_CalcReg:	ASSUME	ds:DGROUP
		sub	ax,SegProgram
		mov	cl,4
		shl	ax,cl
		add	ax,RegIP

		mov	bx,es
		sub	bx,SegProgram
		mov	cl,4
		shl	bx,cl
		add	bx,di

		cmp	Counting,FALSE		; are we counting ?
		je	SS_CountCheck
		mov	cx,bx			; continue counting ?
		sub	cx,LastDIValue
		je	SS_IPCheck		; (optimisation)
		cmp	cx,4
		jbe	SS_IPCheck
		cmp	cx,-1			; allow -1 (SCRNCH10)
		je	SS_IPCheck
		mov	Counting,FALSE
		mov	cx,LastDIValue
		cmp	cx,HighestDI
		jbe	SS_CountCheck
		mov	HighestDI,cx
SS_CountCheck:
		or	bx,bx
		je	SS_CheckES
		cmp	bx,HighestDI
		jne	SS_IPCheck
SS_CheckES:
		mov	cx,es			; check if ES too high
		cmp	cx,SegProgram
		ja	SS_IPCheck
		mov	Counting,TRUE
SS_IPCheck:
		or	ax,ax
		jne	SS_LowIPCheck
		mov	cx,RegCS
		cmp	cx,SegProgPSP
		je	SS_done
SS_LowIPCheck:
		cmp	ax,20h
		jbe	SS_Return
		cmp	ax,LowestIP
		jae	SS_Return
		mov	LowestIP,ax
SS_Return:
		mov	LastDIValue,bx
		mov	ax,RegES
		or	ax,ax
		jne	SS_SetRegs
		mov	ax,SegProgInts
SS_SetRegs:
		mov	es,ax
		mov	cx,RegCX
		mov	bx,RegBX
		mov	ax,RegAX
		push	Flags
		push	RegCS
		push	RegIP
		mov	ds,RegDS
		iret
SS_done:
		mov	RegSS,ss		; restore other registers
		mov	RegSP,sp
		cli
		mov	ss,SegStack
		mov	sp,MySP
		sti
		push	bx
		mov	InProgram,FALSE
		mov	Int10Routine,offset Int10Def
		mov	Int21Routine,offset Int21Def
		mov	si,offset ACT_done
		call	WriteASCIIZ
		mov	si,offset CmtOpen
		call	WriteASCIIZ
		mov	ax,InstrCnt
		mov	dx,InstrCnt+2
		call	WriteLongInt
		mov	si,offset CmtClose
		call	WriteLnASCIIZ

		pop	bx
		mov	di,HighestDI
		cmp     Counting,FALSE
		je	CheckSize
		cmp	di,bx
		ja 	CheckSize
		mov	HighestDI,bx
CheckSize:
		cmp	SwitchV,FALSE
		je	UseBest
		mov	si,offset SS_Result$
		call	Info
		mov	ax,LowestIP
		call	WriteHexWord
		mov	si,offset SS_Result2$
		call	WriteASCIIZ
		mov	ax,HighestDI
		call	WriteHexWord
		mov	si,offset SS_Result3$
		call	WriteLnASCIIZ
UseBest:
		mov	di,HighestDI
		add	di,0100h
		cmp	di,0120h
		jae	ComWrite
		mov	di,LowestIP
		add	di,0100h
		jmp	ComWrite

.data
InstrCnt	dw	0,0
LastDIValue	dw	0
HighestDI	dw	0
LowestIP	dw	0
Counting	db	FALSE
SS_Result$	db	'Trace results values are IP=',0
SS_Result2$	db	'h and DI=',0
SS_Result3$	db	'h.',0
ALF		db	LF,0
CmtOpen		db	' (',0
CmtClose	db	' instructions executed)',0

.code

HandleCom:	ASSUME	ds:NOTHING, es:NOTHING
		call	Action
		call	Break
		mov	si,offset ACT_done
		call	WriteLnASCIIZ
		mov	ds,SegData
		ASSUME	ds:DGROUP
		mov	di,RegDI		; default size
		mov	es,RegES
		mov	ax,ProgFinalSeg
		mov	bx,ProgFinalOfs
		mov	cx,ax
		or	cx,bx			; no size override ?
		je	ComWrite
		cmp	ax,-1
		je	NewSizeOfs
		or	ax,ax			; relative ?
		jne	NewSizeAbs
		add	di,bx
		jmp	ComWrite
NewSizeAbs:
		mov	es,ax
NewSizeOfs:
		mov	di,bx			; size absolute

ComWrite:	ASSUME	ds:NOTHING, es:NOTHING
		mov	ds,SegData
		ASSUME	ds:DGROUP
		mov	ax,es
		sub	ax,SegProgram
		imul	ParSize
		add	ax,di
		adc	dx,0
		mov	cx,ax
		mov	dx,offset TempFile
		push	cx
		call	CreateFile
		pop	cx
		mov	bx,ax
		mov	ds,SegProgram
		ASSUME	ds:NOTHING
		xor	dx,dx
		call	WriteFile
		call	CloseFile
		jmp	HandleFiles

cIndexedId:	ASSUME	ds:NOTHING, es:NOTHING
		push	ax
		push	cx
		push	si
		push	ds

		mov	ds,SegData
		ASSUME	ds:DGROUP
		mov	si,ax
CIID_check:
		lodsw
		cmp	ax,bx			; found id-nr ?
		je	CIID_haveit
		or	ax,ax			; end of table ?
IFDEF DEBUG
		jne	CIID_skip
		push	si
		push	bx
		mov	si,offset DebugCom1
		call	Debug
		mov	ax,bx
		call	WriteHexWord
		mov	si,offset DebugInt4
		call	WriteLnASCIIZ
		pop	bx
		pop	si
		jmp	CIID_haveit
ELSE
		je	CIID_haveit
ENDIF

CIID_skip:
		lodsw
		or	ax,ax
		jne	CIID_skip
		jmp	CIID_check
CIID_haveit:
		call	WriteVersion
CIID_exit:
		pop	ds
		ASSUME	ds:NOTHING
		pop	si
		pop	cx
		pop	ax
		ret

; /*************************************************************************/
; /* IndexedID, determines compressor by looking up breakpoint values	   */
; /*   Input:								   */
; /*		BX	  GS breakpoint location			   */
; /*		CX	  GI breakpoint location			   */
; /*		DX        QT breakpoint location			   */
; /*		DGROUP:SI breakpoint table				   */
; /*   Output:								   */
; /*									   */
; /* WriteVersion has been called with the name found.			   */
; /*************************************************************************/
eIndexedId:	ASSUME	ds:NOTHING, es:NOTHING
		push	ax
		push	ds

		mov	ds,SegData
		ASSUME	ds:DGROUP
EIID_check:
		lodsw
		add	si,4
		or	ax,ax			; end of table ?
IFDEF DEBUG
		jne	EIID_compare
		push	si
		push	bx
		push	cx
		mov	si,offset DebugExe1
		call	Debug
		mov	ax,bx
		call	WriteHexWord
		mov	si,offset DebugExe2
		call	WriteASCIIZ
		pop	ax
		push	ax
		call	WriteHexWord
		mov	si,offset DebugExe3
		call	WriteASCIIZ
		mov	ax,dx
		call	WriteHexWord
		mov	si,offset DebugInt4
		call	WriteLnASCIIZ
		pop	cx
		pop	bx
		pop	si
		jmp	EIID_haveit

EIID_compare:
ELSE
		je	EIID_haveit
ENDIF

		cmp	ax,bx
		jne	EIID_skip
		cmp	[si-4],cx
		jne	EIID_skip
		cmp	[si-2],dx
		je	EIID_haveit

EIID_skip:
		lodsw
		or	ax,ax
		jne	EIID_skip
		jmp	EIID_check
EIID_haveit:
		call	WriteVersion
EIID_exit:
		pop	ds
		ASSUME	ds:NOTHING
		pop	ax
		ret

include CBWFP.asm
include CC2CR.asm
include CCOML.asm
include CCMPK.asm
include CCPAV.asm
include CCRCM.asm
include	CCRPT.asm
include CDIET.asm
include CELIT.asm
include CEPW.asm
include CICE.asm
include CMCLK.asm
include CNTBD.asm
include CNTCH.asm
include	CPKLT.asm
include CPOJC.asm
include	CPPCK.asm
include CPRCM.asm
include CPROT.asm
include CPSWD.asm
include CSCAN.asm
include CSCRM.asm
include CSCRN.asm
include CSHRN.asm
include CSLFD.asm
include CSPCM.asm
include CSPRT.asm
include CSYRN.asm
include	CTPCS.asm
include CUSRN.asm
include CXLCK.asm
IFDEF RARE
include CCMPR.asm
include CU173.asm
ENDIF


;/* --- handling of EXE files --- */
.code
ExeHandling:    ASSUME	ds:NOTHING, es:NOTHING
		mov     ds,SegData
		ASSUME  ds:DGROUP
		mov     es,SegData
		ASSUME  es:DGROUP
		cmp	Command,'O'
		jne	LoadExe
		mov	ax,ExeImageSz
		mov	dx,ExeImageSz+2
		add	ax,ExeHeaderSz
		adc	dx,ExeHeaderSz+2
		jmp	CmdOverlay
LoadExe:
		mov	bx,2
		mov	si,offset ME_Header
		call	AllocateMem
		mov	cx,001Ch
		mov	SegEHInfo.A,ax
		mov	SegEHInfo.S,cx
		mov	ds,ax
		ASSUME	ds:NOTHING
		mov	bx,Handle1
		xor	ax,ax
		xor	dx,dx
		call	MovePointer
		call	ReadFile		; read 00h-1Ch
		mov	cx,01Ch
		mov	ax,ds:[RelocItemsCnt]
		or	ax,ax
		jne	ReadToItems
		jmp	ReadAfter
ReadToItems:
		push	ax			; push item count on stack
		mov	cx,ds:[RelocOffs]
		sub	cx,1Ch
		mov	bx,cx
		add	bx,0Fh
		shr	bx,4
		mov	si,offset ME_Header
		call	AllocateMem
		mov	SegEHToItems.A,ax
		mov	SegEHToItems.S,cx
		mov	ds,ax
		ASSUME	ds:NOTHING
		mov	bx,Handle1
		call	ReadFile		; read 1Ch-Items
		mov	ds,SegData

CheckItems:	ASSUME	es:NOTHING, ds:DGROUP
		pop	ax
		or	ax,ax
		je	EndItems
		push	ax
		mov	cx,128/4
		cmp	ax,cx
		jae	ReadItems
		mov	cx,ax
ReadItems:
		pop	ax
		sub	ax,cx
		push	ax
		mov	dx,offset Filename3
		shl	cx,2
		mov	bx,Handle1
		call	ReadFile
		shr	cx,2
		mov	si,offset Filename3
StoreItem:
		lodsw
		mov	di,ax
		lodsw
		add	ax,SegProgram
		mov	es,ax
		int	INTGI
		loop	StoreItem
		jmp	CheckItems
EndItems:
		call	GIShrink
		mov	ds,SegEHInfo.A
		ASSUME	ds:NOTHING
		mov     es,SegData
		ASSUME  es:DGROUP
		mov	cx,ds:[RelocItemsCnt]
		shl	cx,2
		add	cx,SegEHToItems.S
		add	cx,01Ch

ReadAfter:	ASSUME	ds:NOTHING, es:NOTHING
		mov     es,SegData
		ASSUME  es:DGROUP
		mov	ax,ExeHeaderSz		; headersize to bytes
		sub	ax,cx			; substract bytes read
		jnc	MoreStrucInfo
		mov	si,offset WAR_FixupInImg
		push	ds
		mov     ds,SegData
		ASSUME  ds:DGROUP
		call	Warning
		pop	ds
		ASSUME  ds:NOTHING
		mov	ax,0

MoreStrucInfo:
		mov	SegEHAfter.S,ax
		mov	bx,ax
		add	bx,0Fh
		shr	bx,4
		mov	si,offset ME_Header
		call	AllocateMem
		mov	SegEHAfter.A,ax
		mov	cx,SegEHAfter.S
		mov	bx,Handle1
		mov	ds,ax
		ASSUME	ds:NOTHING
		xor	dx,dx
		call	ReadFile
		mov	SegEHAlign.S,0
		mov	SegEHAlign.A,0

		mov	ds,SegEHInfo.A
		ASSUME	ds:NOTHING
		mov	ax,ExeImageSz
		mov	dx,ExeImageSz+2
		div	ParSize
		xor	dx,dx
		add	ax,EXTRAMEM
		adc	dl,0
		add	ax,ds:[MinParMem]
		adc	dl,0
		or	dx,dx			; size above 1Mb ?
		jne	LoadError
		cmp	ax,01000h		; 64K?
		jae	UseMem
		mov	ax,01000h
UseMem:
		mov	TotalMem,ax
		push	ax
		call	GetFreeMem
		pop	di
		cmp	bx,di
		jb	LoadError
		mov	bl,MSLFirstFit
		call	SetMemStrategy
		mov	bx,di
		call	AllocateMem
		cmp	ax,01000h
		jae	LoadSegOk
		mov	bx,0FFFh		; calc memory for loadfix
		sub	bx,ax
		mov	es,ax
		ASSUME	es:NOTHING
		call	ResizeMem
		mov	bx,di
		xor	si,si			; no error check
		call	AllocateMem
		jc	NoLoadFix
		push	ax
		push	bx
		call	FreeMem			; release lower memory
		pop	bx
		pop	ax
		jmp	LoadSegOk
NoLoadFix:
		call	FreeMem			; release lower memory
		mov	bx,di
		call	AllocateMem
LoadSegOk:
		mov	es,SegData
		ASSUME	es:DGROUP
		mov	SegProgPSP,ax
		add	ax,010h
		cmp	HighloadEXE,FALSE
		je	WriteInfo
		sub	ax,010h
		push	ax
		mov	bx,0FFFFh
		mov	es,ax
		ASSUME	es:NOTHING
		call	ResizeMem		; get largest size block
		mov	ax,bx                   ; substrac 1/16 for items
		mov	cl,4
		shr	ax,cl
		sub	bx,ax
		call	ResizeMem
		mov	es,SegData
		ASSUME	es:DGROUP
		mov	ax,ExeImageSz
		mov	dx,ExeImageSz+2
		div	ParSize
		mov	dx,ax
		pop	ax
		add	ax,bx
		sub	ax,dx
		dec	ax

WriteInfo:
		cmp	SwitchV,FALSE
		je	LoadFile
		push	ds
		push	ax
		push	bx
		mov	si,offset Info50
		call	Info
		call	WriteHexWord
		mov	si,offset Info51
		call	WriteASCIIZ
		pop	bx
		push	bx
		mov	ax,10h
		mul	bx
		call	WriteLongInt
		mov	si,offset Info53
		call	WriteLnASCIIZ

		mov	si,offset Info60
		call	Info
		mov	ds,SegEHInfo.A
		ASSUME	ds:NOTHING
		mov	ax,ds:[MinParMem]
		call	WriteHexWord
		mov	si,offset Info61
		call	WriteASCIIZ
		mov	ax,ds:[MaxParMem]
		call	WriteHexWord
		mov	si,offset Info62
		call	WriteASCIIZ
		mov	ax,ds:[HeaderSz]
		mov	bx,4
		mul	bx
		sub	ax,ORIG.RelocItemsCnt
		shl	ax,2
		sub	ax,1Ch
		xor	dx,dx
		call	WriteLongInt
		mov	si,offset Info53
		call	WriteLnASCIIZ
		pop	bx
		pop	ax
		pop	ds
LoadFile:
		mov	ds,SegData
		ASSUME	ds:DGROUP
		call	CreatePSP		; optimisation
		ASSUME	ds:NOTHING,es:DGROUP
		mov	ax,ExeImageSz
		mov	dx,ExeImageSz+2
HowMuchRead:
		mov	cx,0FFF0h		; read in blocks of FFF0h bytes
		mov	bx,Handle1
		or	dx,dx
		jne	ReadIt
		mov	cx,ax
ReadIt:
		push	ax
		push	dx
		xor	dx,dx
		call	ReadFile
		mov	ax,ds
		add	ax,0FFFh
		mov	ds,ax
		pop	dx
		pop	ax
		sub	ax,cx
		sbb	dx,0
		or	dx,dx
		jne	HowMuchRead
		or	ax,ax
		jne	HowMuchRead
		call	CloseFile
		mov	bl,MSHLBestFit
		call	SetMemStrategy

		cmp	Command,'L'		; load and save only?
		je	ApplyExeOptions
IFDEF MARKEXE
		cmp	Command,'M'
		je      CmdMarkExe
ENDIF

		mov	RegAX,0
		mov	RegBX,0
		mov	RegCX,0
		mov	RegDX,0
		mov	RegSI,0
		mov	RegDI,0
		mov	RegBP,0
		mov	ds,SegEHInfo.A
		ASSUME	ds:NOTHING
		mov	ax,ds:[InitialIP]
		mov	RegIP,ax
		mov	ax,ds:[InitialCS]
		add	ax,SegProgram
		mov	RegCS,ax
		mov	ax,ds:[InitialSP]
		mov	RegSP,ax
		mov	ax,ds:[InitialSS]
		add	ax,SegProgram
		mov	RegSS,ax
		mov	ax,SegProgPSP
		mov	RegDS,ax
		mov	RegES,ax

		cmp	Command,'C'		; convert to COM ?
		je	CmdToCom

		call	ESCAN_entry
		call	EXLCK_entry

		call	SetFixups
		mov	TempDouble,0

CheckExe:
		call	EPKSG_entry
		call	ECMPK_entry
		call	EPKTN_entry
		call	ETINY_entry
		call	EPKLT_entry
		call	EGNRC_entry
		call	EEXPK_entry
		call	EDIET_entry
		call	EPKEX_entry
		call	ECPAV_entry		; immunize code
		call	EUCEX_entry
		call	ESAXE_entry
		call	EPGMP_entry
		call	EOPTL_entry
		call	ESCRN_entry
		call	EWWPP_entry
		call	EAINX_entry
		call	EDELT_entry
		call	EELIT_entry
		call	EEPW_entry
IFDEF RARE
		call	ECRPT_entry
		call	ECMPR_entry
		call	EMKS_entry
		call	ESCRM_entry
		call	ECOM2_entry
ENDIF
		call	EPROT_entry		; mutation engine

		ASSUME	ds:NOTHING, es:NOTHING
		mov	ds,SegData
		ASSUME	ds:DGROUP

		cmp	Command,'T'
		jne     EXENotFound

		call	Trace
IFDEF DEBUG
		cmp	SwitchV,ASK
		jne	NormalTrace

		mov	ax,RegCS
		call	WriteHexWord
		mov	si,offset DebugInt2
		call	WriteASCIIZ
		mov	ax,RegIP
		call	WriteHexWord
		mov	si,offset DebugCR
		call	WriteASCIIZ
		jmp	CheckExe
.data
DebugCR		db	CR,0
.code
NormalTrace:
ENDIF
		inc	byte ptr Filename3
		jne	CheckExe
		inc	byte ptr Filename3+1
		mov	al,byte ptr Filename3+1
		and	al,3
		mov	byte ptr Filename3+1,al
		mov	ah,0
		shl	ax,1
		shl	ax,1
		add	ax,offset Indicator
		mov	si,ax
		call	WriteASCIIZ
		jmp	CheckExe
.data
Indicator	db	'-',CR,0,0
		db	'\',CR,0,0
		db	'|',CR,0,0
		db	'/',CR,0,0
.code

EXENotFound:
		call	FreeExeMem
		jmp	CheckCOM


HBCreate:	ASSUME	ds:NOTHING,es:NOTHING
		mov	ds,SegData
		ASSUME	ds:DGROUP
		inc	SwitchHforced
		mov	ax,SegEHInfo.A
		mov	es,ax
		ASSUME	es:NOTHING
		cmp	SegEHInfo.S,0
		jne	UpdateHeader
		mov	si,offset ME_Header
		mov	bx,2
		call	AllocateMem
		mov	SegEHInfo.A,ax
		mov	SegEHInfo.S,1Ch
		mov     es,ax
		ASSUME	es:NOTHING
		mov	es:[OverlayNr],0
		mov	es:[RelocOffs],1Ch
		mov	es:[MaxParMem],0FFFFh
		mov	es:[MZSignature],'ZM'
		mov	es:[Checksum],0

UpdateHeader:   ASSUME	ds:NOTHING,es:NOTHING
		mov	ds,SegData
		ASSUME	ds:DGROUP
		mov	es,SegProgPSP
		mov	ax,es:[005Ch]
		mov     es,SegEHInfo.A
		ASSUME	es:NOTHING
		or	ax,ax
		je	CalcSize
		cmp	SwitchK,FALSE
		je	CalcSize
		cmp     SwitchK,TRUE
		je	ShowPKInfo
		mov	si,offset ASK_pksig
		call	GetYorN
		je	AddPKSig
		jmp	CalcSize
ShowPKInfo:
		cmp	SwitchV,FALSE
		je	AddPKSig
		mov	_pksig,ax
		mov	si,offset INF_pksig
		call	Info
AddPKSig:
		mov	ax,ProgFinalOfs
		push	es
		push	ax
		mov	cl,4
		shr	ax,cl
		add	ax,ProgFinalSeg
		mov	es,ax
		ASSUME	es:NOTHING
		pop	ax
		and	ax,0Fh
		mov	di,ax
		push	di

		mov	si,offset FakePkSig
		movsw				; mov word ptr
		movsw				; [005Ch]
		lodsw
		push	ds
		mov	ds,SegProgPSP
		mov	ax,ds:[005Ch]
		pop	ds
		stosw
		movsw				; mov ax,ds
		movsb				; add ax,
		lodsw
		mov	ax,RegCS
		sub	ax,SegProgPSP
		stosw
		movsw				; push ax ; mov ax,
		lodsw
		mov	ax,RegIP
		stosw
		movsw				; push ax ; retf

		mov	RegCS,es
		pop 	RegIP
		mov	ax,FakePkSigl
		add	ExeSizeAdjust,ax
		pop	es

CalcSize:
		mov	ax,ProgFinalSeg		; calculate new image size
		xor	dx,dx
		sub	ax,SegProgram
		sbb	dx,0
		mov	cx,4
LongMul16:
		shl	ax,1
		rcl	dx,1
		loop	LongMul16

		add	ax,ProgFinalOfs
		adc	dx,0
		add	ax,ExeSizeAdjust
		adc	dx,[ExeSizeAdjust+2]
		mov	ExeImageSz,ax
		mov	ExeImageSz+2,dx

		div	ParSize
		xchg	ax,bx
		mov	ax,TotalMem
		sub	ax,EXTRAMEM
		sub	ax,bx
		cmp	ax,0A000h
		jb	MinMemOk
		xor	ax,ax			; no minimal memory
MinMemOk:
		cmp	HeaderStored,0
		jne	_label01
		mov	es:[MinParMem],ax

_label01:       ASSUME	es:NOTHING, ds:DGROUP	; es=SegEHInfo.A
		mov	ax,RegCS
		sub	ax,SegProgram
		mov	es:[InitialCS],ax
		mov	ax,RegIP
		mov	es:[InitialIP],ax
		mov	ax,RegSS
		sub	ax,SegProgram
		mov	es:[InitialSS],ax
		mov	ax,RegSP
		mov	es:[InitialSP],ax
		mov	ax,NrRelocFound
		mov	es:[RelocItemsCnt],ax
		or	ax,ax
		je	ApplyExeOptions
		mov	ax,1Ch
		add	ax,SegEHToItems.S
		mov	es:[RelocOffs],ax


ApplyExeOptions:ASSUME	ds:NOTHING,es:NOTHING
		mov	ds,SegData
		ASSUME	ds:DGROUP
		mov     al,SwitchH
		or	al,SwitchHforced
		je	CalcHeader

		xor	ax,ax
		mov	SegEHToItems.S,ax
		xchg	SegEHToItems.A,ax
		mov	es,ax
		ASSUME	es:NOTHING
		call	FreeMem

		xor	ax,ax
		mov	SegEHAfter.S,ax
		xchg	SegEHAfter.A,ax
		mov	es,ax
		ASSUME	es:NOTHING
		call	FreeMem

		mov	ds,SegEHInfo.A
		ASSUME	ds:NOTHING
		mov	ds:[RelocOffs],1Ch


CalcHeader:	ASSUME	ds:NOTHING, es:NOTHING
		mov	es,SegData
		ASSUME	es:DGROUP
		mov	ds,SegEHInfo.A
		ASSUME	ds:NOTHING
		mov	ax,ds:[RelocItemsCnt]	; calculate aligntment size
		shl	ax,2
		add	ax,SegEHInfo.S
		add	ax,SegEHToItems.S
		add	ax,SegEHAfter.S
		xor	dx,dx
		mov	cx,AlignmentSize
		div	cx
		or	dx,dx			; no alignment necessary?
		jne	SetAlignSize
		xor	cx,cx
SetAlignSize:
		sub	cx,dx
		mov	SegEHAlign.S,cx
		xor	bx,bx
		cmp	bx,dx
		adc	ax,0
		mul	AlignmentSize
		mov	ExeHeaderSz,ax
		mov	ExeHeaderSz+2,dx

		div	ParSize			; calculate new header size
		cmp	bx,dx
		adc	ax,0
		mov	ds:[HeaderSz],ax

		mov	ax,ExeHeaderSz          ; calculate new total size
		mov	dx,ExeHeaderSz+2
		add	ax,ExeImageSz
		adc	dx,ExeImageSz+2
		mov	cl,SwitchG
		or	cl,SwitchGforced
		je	NoInclude
		add	ax,ExeOverlaySz
		adc	dx,ExeOverlaySz+2
NoInclude:
		mov	cx,512
		div	cx
		cmp	bx,dx
		adc	ax,0
		mov	ds:[SizeMod512],dx
		mov	ds:[SizeDiv512],ax

		mov	bx,SegEHAlign.S
		add	bx,0Fh
		mov	cl,4
		shr	bx,cl
		mov	si,offset ME_Header
		call	AllocateMem
		mov	SegEHAlign.A,ax
		mov	cx,SegEHAlign.S
		xor	di,di
		mov	es,ax
		ASSUME	es:NOTHING
		mov	al,0
		repnz	stosb

ExeWrite:	ASSUME	ds:NOTHING, es:NOTHING
		mov	es,SegData
		ASSUME	es:DGROUP
		mov	dx,offset TempFile
		call	CreateFile
		mov	Handle4,ax
		xchg	bx,ax
		xor	dx,dx
		mov	ds,SegEHInfo.A
		mov	cx,SegEHInfo.S
		call	WriteFile
		mov	ds,SegEHToItems.A
		mov	cx,SegEHToItems.S
		call	WriteFile

		call	WriteItems

		mov	ds,SegEHAfter.A
		mov	cx,SegEHAfter.S
		call	WriteFile
		mov	ds,SegEHAlign.A
		mov	cx,SegEHAlign.S
		call	WriteFile

		mov	ax,ExeImageSz
		mov	dx,ExeImageSz+2
		mov	ds,SegProgram

HowMuchWrite:
		mov	cx,0FFF0h		; write in blocks of FFF0h bytes
		or	dx,dx
		jne	WriteIt
		mov	cx,ax
WriteIt:
		push	ax
		push	dx
		xor	dx,dx
		call	WriteFile
		mov	ax,ds
		add	ax,0FFFh
		mov	ds,ax
		pop	dx
		pop	ax
		sub	ax,cx
		sbb	dx,0
		or	dx,dx
		jne	HowMuchWrite
		or	ax,ax
		jne	HowMuchWrite


		mov	ds,SegData
		ASSUME	ds:DGROUP
		mov	al,SwitchR
		or	al,SwitchRforced
		jne	CloseExe
		mov	ax,ExeOverlaySz
		or	ax,ExeOverlaySz+2
		je	CloseExe
		mov	dx,offset Filename1
		call	OpenFile
		mov	Handle1,ax
		mov	dx,offset Filename3
		mov	cx,6
		call	ReadFile
		mov     ax,word ptr Filename3[SizeDiv512]
		mov     dx,word ptr Filename3[SizeMod512]
		call	ToNormal
		mov	bx,Handle1
		call	MovePointer

		mov	bx,0FFFh
		xor	si,si
		call	AllocateMem
		jnc	SizeToBytes
		mov	si,offset ME_CopyOvrly
		call	AllocateMem
SizeToBytes:
		mov	es,ax
		ASSUME	es:NOTHING
		mov	di,bx
		shl	di,4
		push	es
		pop	ds
		ASSUME	ds:NOTHING
		mov	es,SegData
		ASSUME	es:DGROUP
		xor	dx,dx
CopyOverlay:
		mov	cx,di
		mov	bx,Handle1
		call	ReadFile
		mov	cx,ax
		mov	bx,Handle4
		call	WriteFile
		or	ax,ax
		jne	CopyOverlay
		push	ds
		pop	es
		ASSUME	es:NOTHING
		call	FreeMem
		mov	ds,SegData
		ASSUME	ds:DGROUP
		mov	bx,Handle1
		call	CloseFile
CloseExe:
		mov	bx,Handle4
		call	CloseFile
		call	FreeExeMem
		jmp     HandleFiles

IFDEF MARKEXE
CmdMarkExe:     ASSUME	ds:NOTHING,es:NOTHING
		mov	ds,SegData
		ASSUME	ds:DGROUP
		mov	es,SegEHToItems.A
		ASSUME	es:NOTHING
		call	FreeMem
		mov	es,SegEHAfter.A
		call	FreeMem
		mov	SegEHAfter.S,0
		mov	es,SegData
		ASSUME	es:DGROUP
		mov	bx,01000h
		mov	si,offset ME_MarkFile
		call	AllocateMem
		mov	ds,ax
		ASSUME	ds:NOTHING
		mov	SegEHToItems.A,ax
		mov	dx,offset Filename2
		call	OpenFile
		mov	Handle2,ax
		xor	dx,dx
		mov	cx,-1
		call	ReadFile
		mov     SegEHToItems.S,ax
		call	CloseFile
		mov	ds,SegData
		ASSUME	ds:DGROUP
		mov	es,SegEHInfo.A
		ASSUME	es:NOTHING
		cmp	es:[RelocItemsCnt],0
		je	X_Tja
		mov	ax,1Ch
		add	ax,SegEHToItems.S
		mov	es:[RelocOffs],ax
X_Tja:
		dec	FilenameCnt		; 2nd name is not destination
		jmp	ApplyExeOptions
ENDIF ; MARKEXE

FreeExeMem:     ASSUME	ds:NOTHING, es:NOTHING
		push	ds
		push	es
		mov     ds,SegData
		ASSUME  ds:DGROUP

		mov	es,SegEHInfo.A
		call	FreeMem

		mov	es,SegEHToItems.A
		call	FreeMem

		mov	es,SegEHAfter.A
		call	FreeMem

		mov	es,SegEHAlign.A
		call	FreeMem

		xor	ax,ax
		mov	SegEHInfo.A,ax
		mov	SegEHInfo.S,ax
		mov	SegEHToItems.A,ax
		mov	SegEHToItems.S,ax
		mov	SegEHAfter.A,ax
		mov	SegEHAfter.S,ax
		mov	SegEHAlign.A,ax
		mov	SegEHAlign.S,ax

		pop	es
		pop	ds
		ret


include eainx.asm
include ecmpk.asm
include ecpav.asm
include escrn.asm
include edelt.asm
include	ediet.asm
include eelit.asm
include	eepw.asm
include egnrc.asm
include	epkex.asm
include epktn.asm
include epklt.asm
include epksg.asm
include epgmp.asm
include eprot.asm
include	esaxe.asm
include escan.asm
include etiny.asm
include eucex.asm
include ewwpp.asm
include	eexpk.asm
include eoptl.asm
include exlck.asm
IFDEF RARE
include ecmpr.asm
include ecom2.asm
include ecrpt.asm
include emks.asm
include escrm.asm
ENDIF

include gi.asm
include gs.asm

;---------------------------------------------------------------------------;
.code
CmdToCom:	ASSUME	ds:NOTHING, es:NOTHING
		mov     ds,SegData
		ASSUME  ds:DGROUP
		mov     es,SegData
		ASSUME  es:DGROUP
		mov	si,offset ACT_tocom
		call	Action

		call	FreeExeMem		; release header memory

		mov	si,offset TC_reloc
		cmp	NrRelocFound,0
		jne	TC_error
		mov	si,offset TC_csip
		cmp	RegIP,0100h
		jne	TC_error
		mov	ax,RegCS
		cmp	ax,SegProgPSP
		jne	TC_error
		mov	si,offset TC_toolarge
		cmp	ExeImageSz+2,0
		jne	TC_error
		mov	si,offset TC_overlay
		mov    	ax,ExeOverlaySz
		or	ax,ExeOverlaySz+2
		jne	TC_error
		mov	di,ExeImageSz
		mov	es,SegProgram
		mov	si,offset ACT_done
		call	WriteLnASCIIZ
		jmp	ComWrite
TC_error:
		call	Error
		jmp	Continue

;---------------------------------------------------------------------------;
CmdOverlay:	ASSUME	ds:NOTHING, es:NOTHING
		mov     ds,SegData
		ASSUME  ds:DGROUP
		mov     es,SegData
		ASSUME  es:DGROUP

		push	ax
		push	dx

		mov	si,offset ACT_overlay
		call	Action

		push	es
		mov	es,SegProgPSP
		call	FreeMem
		pop	es

		mov	bx,01000h
		mov	si,offset ME_BasicOp
		call	AllocateMem
		mov	SegProgPSP,ax

		mov	dx,offset TempFile	; open temp file
		call	CreateFile
		mov	Handle4,ax
		mov	di,ax

		mov	ds,SegProgPSP
		ASSUME	ds:NOTHING

		mov	dx,offset Filename2
		call	FindFirst
		jc	OV_append

		mov	dx,offset Filename2	; source file
		call	OpenFile
		mov	Handle2,ax
		mov	si,ax

OV_copyblock:
		mov	bx,si			; read from file
		mov	cx,0FFFFh
		xor	dx,dx
		call	ReadFile
		mov	bx,di			; write to file
		mov	cx,ax
		call	WriteFile
		cmp	ax,0FFFFh		; full buffer written ?
		je	OV_copyblock

		mov	bx,si
		call	CloseFile

OV_append:
		mov	dx,offset Filename1	; open source file
		call	OpenFile
		mov	si,bx
		pop	dx
		pop	ax
		call	MovePointer

OV_copyblock2:
		mov	bx,si			; read from file
		mov	cx,0FFFFh
		xor	dx,dx
		call	ReadFile
		mov	bx,di			; write to file
		mov	cx,ax
		call	WriteFile
		cmp	ax,0FFFFh		; full buffer written ?
		je	OV_copyblock2

		mov	bx,si
		call	CloseFile
		mov	bx,di
		call	CloseFile

		mov	si,offset ACT_done
		call	WriteLnASCIIZ

		jmp	HandleFiles

;---------------------------------------------------------------------------;
SetBreakpoints: ASSUME	ds:NOTHING, es:NOTHING
; place interrupts in program and executes
;   DGROUP:AX action string
;   DS:BX     GrabSize
;   DS:CX     GrabItem
;   DS:DX     Quit

		mov	es,SegData
		ASSUME	es:DGROUP
		mov	al,SwitchLforced
		or	al,SwitchL
		je	PrintAction
		call	IncreaseMem
PrintAction:
		or	si,si
		je	NoAction
		call	Action
NoAction:
		push	bx
		cmp	cx,-1
		je	SkipGI
		mov	bx,cx
		call	SetGI			; set GI on ds:bx
SkipGI:
		mov	bx,dx
		call	SetQT			; set QT on ds:bx
		pop	bx
		call 	SetGS		  	; set GS on ds:bx

		jmp	Execute

;---------------------------------------------------------------------------;

.code
HandleFiles:	ASSUME	ds:NOTHING, es:NOTHING
		mov	ds,SegData
		ASSUME	ds:DGROUP
		mov	es,SegData
		ASSUME	es:DGROUP
		call	SetDTA
		mov	dx,offset TempFile
		call	FindFirst
		mov	si,offset NewSizeTxt
		call	WriteASCIIZ
		mov	ax,DTA_FileSize
		mov	dx,DTA_FileSize+2
		call	WriteLongInt
		call	WriteLn

		cmp	FilenameCnt,2		; do we have 1 or 2 names ?
		je	HF_havetwo
		mov	si,offset Filename1
		mov	di,offset Filename2
		mov	cx,size Filename1 /2
		repnz	movsw
		cmp	SwitchN,FALSE
		je	HV1_checkb
		mov	si,offset Filename2
		call	IncFilename
		jmp	HF_gotdest
HV1_checkb:
		cmp     SwitchB,FALSE
		je	HV1_nonewname
		mov	si,offset Filename2	; create .bak file
		call	FindExtention
		mov     ax,'B.'
		stosw
		mov	ax,'KA'
		stosw
		mov	al,0
		stosb
		mov	si,offset Filename1
		mov	di,offset Filename2
                mov	ax,SegProgPSP	
		call	MoveFile
		mov	si,offset Filename1
		mov	di,offset Filename2
		mov	cx,size Filename1 /2
		repnz	movsw
HV1_nonewname:
		mov	SwitchOforced,TRUE
		jmp	HF_gotdest

HF_havetwo:
		cmp     SwitchN,FALSE
		je	HF_gotdest
		mov	si,offset Filename2
		call	IncFilename
HF_gotdest:
		mov	si,offset ToDestTxt
		call	WriteASCIIZ
		mov	si,offset Filename2
		call	WriteLnASCIIZ
		mov	si,offset Filename2
		call	FileNotExist
		jc	HV_exit
		mov	si,offset TempFile
		mov	di,offset Filename2
		mov	ax,SegProgPSP
		call	MoveFile
		cmp	SwitchU,FALSE
		je	HV_exit
		mov	dx,offset Filename2
		call	OpenFile
		mov	cx,InfileTime
		mov	dx,InfileDate
		call	WriteStamp
		call	CloseFile
		mov	al,SwitchA
		or	al,SwitchAforced
		je	HV_exit
		mov	si,offset Filename2
		mov	di,offset Filename1
		mov	cx,size Filename1/2
		repnz	movsw
		mov     FilenameCnt,1
HV_exit:

Continue:	ASSUME	ds:NOTHING, es:NOTHING
		mov	ds,SegData
		ASSUME	ds:DGROUP
		mov	es,SegProgPSP
		call	FreeMem
		mov	es,SegProgEnv
		call	FreeMem
		mov	es,SegProgInts
		call	FreeMem
                call	FreeExeMem
		mov	es,SegData		; setup next file
		ASSUME	es:DGROUP
		mov	al,SwitchA
		or	al,SwitchAforced
		and	al,WasCompressed
		jne	ToNextFile
		dec	FilesFound
		cmp	FilesFound,0
		je	Quit
		mov	ds,SegFiles.A
		ASSUME	ds:NOTHING
		mov	si,FilePtr
		mov	di,File1NmePtr
		mov	cx,12
SetNewName:
		lodsb
		inc	FilePtr
		stosb
		or	al,al
		je	ToNextFile
		loop	SetNewName
ToNextFile:
		mov	al,0
		stosb
		call	WriteLn
		jmp	ProcessFile


Quit:		ASSUME	ds:NOTHING, es:NOTHING
		mov	ds,SegData
		ASSUME	ds:DGROUP
		push	ax

		mov	bx,UMBState
		or	bh,bh
		je	RestoreStrat
		call	SetUMBState

RestoreStrat:
		mov	bx,MemStrategy
		or	bh,bh
		je	RestoreInts
		call	SetMemStrategy

RestoreInts:
		cmp	IntsCopied,FALSE
		je	DOSQuit
		mov	cx,HookedIntsCnt
		xor	si,si
		xor	di,di
		mov	ah,25h

SetInts:
		push	ds
		mov	al,[HookedInts+si]
		mov	dx,[OldInts+di]
		mov	ds,[OldInts+2+di]
		int21h
		pop	ds
		inc	si
		add	di,4
		loop	SetInts
		cmp	SwitchI,FALSE
		je	DOSQuit
		mov	al,21h
		mov	dx,OldInt21
		mov	ds,OldInt21+2
		int21h
DOSQuit:
		pop	ax
		mov	ah,4Ch
		int	21h

;---------------------------------------------------------------------------;
Break10:	ASSUME	ds:NOTHING, es:NOTHING
		push	ds
		mov	ds,SegData
		ASSUME	ds:DGROUP
		pop	TempDS
		jmp	[Int10Routine]

Break20:	ASSUME	ds:NOTHING, es:NOTHING
		push	ds
		mov	ds,SegData
		ASSUME	ds:DGROUP
		pop	TempDS
		jmp	[Int20Routine]

Break21:	ASSUME	ds:NOTHING, es:NOTHING
		push	ds
		mov	ds,SegData
		ASSUME	ds:DGROUP
		pop	TempDS
		jmp	[Int21Routine]

BreakQT:	ASSUME	ds:NOTHING, es:NOTHING
		mov	wTemp,ds
		mov	ds,SegData
		ASSUME	ds:DGROUP
		mov	RegAX,ax
		mov	ax,wTemp
		mov	RegDS,ax
		pop	ax
		sub	ax,2
		mov	RegIP,ax
		pop	RegCS
		pop	Flags
		mov	RegSS,ss		; restore other registers
		mov	RegSP,sp
		cli
		mov	ss,SegStack
		mov	sp,MySP
		sti
		mov	RegBX,bx
		mov	RegCX,cx
		mov	RegDX,dx
		mov	RegES,es
		mov	RegSI,si
		mov	RegDI,di
		mov	RegBP,bp

		mov	ax,QTInst
		mov	bx,QTOffs
		mov	es,QTSegm
		cmp	es:[bx],INTQT*100h + 0CDh
		jne	QTMoved
		mov	es:[bx],ax
QTMoved:
		mov	bx,RegIP
		mov	es,RegCS
		cmp	es:[bx],INTQT*100h + 0CDh
		jne	TraceToEnd
		mov	es:[bx],ax
TraceToEnd:
		mov	ax,RegIP
		mov	bx,RegCS
		call	Trace
		cmp	bx,RegCS
		jne	WriteDone
		cmp	ax,RegIP
		jb	TraceToEnd
WriteDone:
		mov	es,RegSS
		ASSUME	es:NOTHING
		mov	di,RegSP
		sub	di,2
		std
		xor	ax,ax
		mov	cx,6
		repnz	stosw
		cld
		mov	InProgram,FALSE
		mov	si,offset ACT_done
		call	WriteLnASCIIZ
		call	GIShrink
		cmp	SwitchH,FALSE
		jne	HBCreate
		jmp     [HeaderBuild]


IntEPDef:	ASSUME	ds:DGROUP, es:NOTHING
		iret

Int10Def:	ASSUME	ds:DGROUP, es:NOTHING
		cmp	InProgram,FALSE
		je	NormalInt10
		mov	si,offset ERR_INT10
		jmp	WrongDosCall

Int10Trc:	ASSUME	ds:DGROUP, es:NOTHING
		cmp	InProgram,FALSE
		je	NormalInt10
		cmp	ah,0
		je	NormalInt10
		cmp 	ax,1A00h
		je	NormalInt10
		mov	si,offset ERR_INT10
		jmp	WrongDosCall

NormalInt10:
		pushf
		push	word ptr [OldInts+(OI10-HookedInts)*4+2]
		push	word ptr [OldInts+(OI10-HookedInts)*4]
I10_fail:
		mov	ds,TempDS
		iret


Int20Def:	ASSUME	ds:DGROUP, es:NOTHING
		mov	si,offset ERR_INT20
		jmp	WrongDosCall


Int21Def:       ASSUME	ds:DGROUP, es:NOTHING
		push	si
		cmp	InProgram,FALSE
		je	NormalInt21
		mov	si,ExpectedInts
CheckInt:
		cmp	ah,ds:[si]
		je	NormalInt21
		inc	si
		cmp	byte ptr ds:[si-1],0
		jne	CheckInt
		pop	si
		mov	si,offset ERR_INT21
WrongDosCall:					; entrypoint for INT 20h check
		mov	ds,SegData
		ASSUME	ds:DGROUP
		mov	RegAX,ax
		pop	ax
		sub	ax,2
		mov	RegIP,ax
		pop	RegCS
		push	si
		mov	InProgram,FALSE
		call	WriteLn
		pop	si
		call	Error
IFDEF DEBUG
		mov	si,offset DebugInt1
		call	Debug
		mov	ax,RegCS
		call	WriteHexWord
		mov	si,offset DebugInt2
		call	WriteASCIIZ
		mov	ax,RegIP
		call	WriteHexWord
		mov	si,offset DebugInt3
		call	WriteASCIIZ
		mov	ax,RegAX
		call	WriteHexWord
		mov	si,offset DebugInt4
		call	WriteLnASCIIZ
ENDIF
		mov	WasCompressed,FALSE
		jmp	Continue
NormalInt21:
		pop	si
NormInt21T:
		push	TempF
		push	word ptr OldInt21 +2
		push	word ptr OldInt21
I21_fail:
		mov	ds,TempDS
		iret

Int21Trc:	ASSUME	ds:DGROUP, es:NOTHING
		cmp	InProgram,FALSE
		je	NormInt21T
		cmp	ah,09h
		je	I21_fail
		cmp	ah,30h			; get dos version
		je	NormInt21T
		cmp	ah,3Dh			; open file
		je	NormInt21T
		cmp	ah,3Eh			; close file
		je	NormInt21T
		cmp	ah,3Fh			; read file
		je	NormInt21T
		cmp	ah,42h			; move filepointer
		je	NormInt21T
		cmp	ah,4Ah
		je	NormInt21T
		mov	si,offset ERR_INT21
		jmp	WrongDosCall

BreakCC:	ASSUME	ds:NOTHING, es:NOTHING
		mov	ds,SegData
		ASSUME	ds:DGROUP
		mov	InProgram,FALSE
		mov	si,offset ERR_INT23
		call	FatalError
		mov	al,ECCTRLCERROR
		jmp	Quit

BreakDZ:	ASSUME	ds:NOTHING, es:NOTHING
		mov	ds,SegData
		ASSUME	ds:DGROUP
		mov	InProgram,FALSE
		mov	si,offset ERR_INT00
		call	FatalError
		mov	al,ECDIVERROR
		jmp	Quit


;--------------------------------------------------------------------------;
FileNotExist:	ASSUME	ds:NOTHING, es:NOTHING
		push	ds
		mov	ds,SegData
		ASSUME	ds:DGROUP
		mov	dx,si
		mov	ax,4300h			; check if file exists
		int21h
		jc	FNE_NoFile			; jump if file exist

		mov	al,SwitchO			; delete file ok?
		or	al,SwitchOforced
		jne	FNE_delete
		push	si
		mov	si,offset FileExistTxt		; no, ask user
		call	WriteASCIIZ
		pop	si
		call	WriteASCIIZ
		mov	si,offset OverwriteTxt
		call	GetYorN
		jne	FNE_noover
FNE_delete:
		call	DeleteFile
FNE_NoFile:
		clc
		pop	ds
		ASSUME	ds:NOTHING
		ret
FNE_noover:
		pop	ds
		ASSUME	ds:NOTHING
		stc
		ret

.data
FileExistTxt	db	'File ',0
OverwriteTxt	db	' already exists.  Overwrite (y/n)? ',0
;--------------------------------------------------------------------------;
.code
IncFilename:	ASSUME	ds:NOTHING, es:NOTHING
		push	bx
		push	ds
		mov	ds,SegData
		ASSUME	ds:DGROUP
		mov	bx,si
		call	FindExtention
		mov	si,di
		lodsw				; push extention
		push	ax
		lodsw
		push	ax
		mov	si,bx
		call	FindFilename
		mov	cx,8
IF_scanname:
		mov	al,[si]
		cmp	al,0
		je	IF_endname
		cmp	al,'.'
		je	IF_endname
		inc	si
		loop	IF_scanname
IF_endname:
		jcxz	IF_addextention
		mov	al,'_'
		mov	[si],al
		inc	si
		loop	IF_endname
IF_addextention:
		pop	ax
		mov	[si+2],ax
		pop	ax
		mov	[si],ax
		mov	di,si
		mov	si,bx
IF_checkdigit:
		dec	di
		cmp	si,di
		ja	IF_exit
		mov	al,[di]
		cmp	al,':'
		je	IF_exit
		cmp	al,'\'
		je	IF_exit
		cmp	al,'9'
		ja	IF_newdigit
		cmp	byte ptr [di],'0'
		jb	IF_newdigit
		inc	byte ptr [di]
		cmp	al,'9'
		jne	IF_exit
		mov	byte ptr [di],'0'
		jmp	IF_checkdigit
IF_newdigit:
		mov	byte ptr [di],'1'
IF_exit:
		pop	ds
		ASSUME	ds:NOTHING
		pop	bx
		ret
;--------------------------------------------------------------------------;
; input
;  AX = SegProgram
;  BX = size of ProgPSP block
;
; output
;  DS = SegProgram
;  ES = SegData

.code
CreatePSP:
		ASSUME	ds:NOTHING,es:NOTHING
		mov	ds,SegData
		ASSUME	ds:DGROUP
		mov	SegProgram,ax
		push	ax
		mov	ax,SegProgPSP
		add	bx,ax
		mov	es,ax
		ASSUME	es:NOTHING
		mov	ax,SegProgEnv		; set Environment addres
		mov	es:[002Ch],ax
		mov	es:[0002h],bx		; set top mem for child
		xor	ax,ax
		mov	es:[005Ch],ax
		mov	ds,SegPSP		; copy commandline
		ASSUME	ds:NOTHING
		mov	si,80h
		mov	di,si
		mov	cl,ds:[di]
		mov	ch,0
		inc	cx
		inc	cx
		repnz	movsb
		pop	ds
		mov	es,SegData
		ASSUME	es:DGROUP
		ret
;--------------------------------------------------------------------------;
Break:		ASSUME	ds:NOTHING, es:NOTHING
		push	ax			; save other registers
		push	bx
		push	cx
		push	dx
		push	si
		push	di
		push	ds
		push	es
		push	bp

		mov	es,SegData
		ASSUME	es:DGROUP
		mov	al,InProgram
		push	ax
		call	SetEP			; set EP at ds:bx

Execute:	ASSUME	ds:NOTHING, es:NOTHING
		mov	ds,SegData
		ASSUME	ds:DGROUP
		mov	MySP,sp
		mov	InProgram,TRUE
		mov	ax,RegAX
		mov	bx,RegBX
		mov	cx,RegCX
		mov	dx,RegDX
		mov	si,RegSI
		mov	di,RegDI
		mov	bp,RegBP
		mov	es,RegES
		ASSUME	es:NOTHING
		cli
		mov	ss,RegSS
		mov	sp,RegSP
		sti
		push	Flags
		push	RegCS
		push	RegIP
		mov	ds,RegDS
		ASSUME	ds:NOTHING
		iret

BreakEP:	ASSUME	ds:NOTHING, es:NOTHING
		mov	wTemp,ds
		mov	ds,SegData
		ASSUME	ds:DGROUP
		mov	RegAX,ax
		mov	ax,wTemp
		mov	RegDS,ax
		pop	ax
		sub	ax,2
		mov	RegIP,ax
		pop	RegCS
		pop	Flags

		mov	RegSS,ss		; restore other registers
		mov	RegSP,sp
		cli
		mov	ss,SegStack
		mov	sp,MySP
		sti
		mov	RegBX,bx
		mov	RegCX,cx
		mov	RegDX,dx
		mov	RegSI,si
		mov	RegDI,di
		mov	RegBP,bp
		mov	RegES,es
		call	UnsetEP			; remove EP when still there
		pop	ax
		mov	InProgram,al
		pop	bp
		pop	es
		ASSUME	es:NOTHING
		pop	ds
		ASSUME	ds:NOTHING
		pop	di
		pop	si
		pop	dx
		pop	cx
		pop	bx
		pop	ax
		ret

;--------------------------------------------------------------------------;
Trace:		ASSUME	ds:NOTHING, es:NOTHING
		push	ax			; save other registers
		push	bx
		push	cx
		push	dx
		push	si
		push	di
		push	ds
		push	es
		push	bp

		mov	es,SegData
		ASSUME	es:DGROUP
		mov	al,InProgram
		push	ax
		mov	InProgram,FALSE
IFDEF DEBUG
		mov	ax,3501h		; get int 01
		int21h
		ASSUME	es:NOTHING
		push	bx
		push	es
		mov	es,SegData
		ASSUME	es:DGROUP
ENDIF
		mov	dx,offset Break01	; hook int 01
		push	cs
		pop	ds
		ASSUME	ds:NOTHING
		mov	ax,2501h
		int21h

		or	Flags,TF		; set trace flag

; As an int instruction (temporary) clears the TF it might be usefull
; to check if the int does not point somewhere into the program itself.
; If this is the case then it is probably a debug trap and might it be
; better to trace the interrupt as well.
		mov	ds,RegCS
		ASSUME	ds:NOTHING
		mov	si,RegIP
		lodsb
		cmp	al,0CDh			; next instruction int?
		jne	TraceGo
		lodsb
		mov	ah,4
		mul	ah
		mov	bx,ax
		xor	ax,ax
		mov	ds,ax
		ASSUME	ds:NOTHING
		mov	cx,ds:[bx+2]		; get segment of int
		mov	ax,SegProgPSP
		cmp	cx,ax
		jb	TraceGo
		add	ax,TotalMem
		cmp	cx,ax
		ja	TraceGo
		cli                             ; dirty coding...
		mov	bp,sp
		mov	ss,RegSS
		mov	sp,RegSP
		push	Flags
		push	RegCS
		add	RegIP,2			; skip int
		push	RegIP
		mov	ax,ds:[bx]
		mov	RegIP,ax
		mov	ax,ds:[bx+2]
		mov	RegCS,ax
		mov	RegSP,sp
		mov	sp,bp

TraceGo:
		mov	ds,SegData
		ASSUME	ds:DGROUP
		mov	MySP,sp
		mov	InProgram,TRUE
		mov	ax,RegAX
		mov	bx,RegBX
		mov	cx,RegCX
		mov	dx,RegDX
		mov	si,RegSI
		mov	di,RegDI
		mov	bp,RegBP
		mov	es,RegES
		ASSUME	es:NOTHING
		cli
		mov	ss,RegSS
		mov	sp,RegSP
		sti
		push	Flags
		push	RegCS
		push	RegIP
		mov	ds,RegDS
		ASSUME	ds:NOTHING
		iret

Break01:	ASSUME	ds:NOTHING, es:NOTHING
		mov	wTemp,ds
		mov	ds,SegData
		ASSUME	ds:DGROUP
		pop	RegIP
		pop	RegCS
		pop	Flags

		mov	RegSS,ss		; restore other registers
		mov	RegSP,sp
		cli
		mov	ss,SegStack
		mov	sp,MySP
		sti
		mov	RegAX,ax
		mov	RegBX,bx
		mov	RegCX,cx
		mov	RegDX,dx
		mov	RegSI,si
		mov	RegDI,di
		mov	RegBP,bp
		mov	RegES,es
		xor	Flags,TF	        ; disable Trace flag
		mov	ax,wTemp
		mov	RegDS,ax
		mov	InProgram,FALSE

IFDEF DEBUG
		pop	ds
		ASSUME	ds:NOTHING
		pop	dx
		mov	ax,2501h
		int21h
		mov	ds,SegData
		ASSUME	ds:DGROUP
ENDIF
		pop	ax
		mov	InProgram,al
		pop	bp
		pop	es
		ASSUME	es:NOTHING
		pop	ds
		ASSUME	ds:NOTHING
		pop	di
		pop	si
		pop	dx
		pop	cx
		pop	bx
		pop	ax
		ret

;--------------------------------------------------------------------------;
.code
SetEP:		ASSUME	ds:NOTHING, es:NOTHING
		push	ax
		push	es
		mov	es,SegData
		ASSUME	es:DGROUP
		mov	ax,ds:[bx]
		mov	ds:[bx],INTEP*100h + 0CDh
		mov	EPSegm,ds
		mov	EPOffs,bx
		mov	EPInst,ax
		pop	es
		pop	ax
		ret

UnsetEP:	ASSUME	ds:NOTHING, es:NOTHING
		push	ax
		push	bx
		push	ds
		push	es
		mov	es,SegData
		ASSUME	es:DGROUP
		mov	ax,EPInst
		mov	bx,EPOffs
		mov	ds,EPSegm
		cmp	ds:[bx],INTEP*100h + 0CDh
		jne	EPMoved
		mov	ds:[bx],ax
EPMoved:
		mov	bx,RegIP
		mov	ds,RegCS
		cmp	ds:[bx],INTEP*100h + 0CDh
		jne	EPRemoved
		mov	ds:[bx],ax
EPRemoved:
		pop	es
		pop	ds
		pop	bx
		pop	ax
		ret

SetQT:		ASSUME	ds:NOTHING, es:NOTHING
		push	ax
		push	es
		mov	es,SegData
		ASSUME	es:DGROUP
		mov 	ax,INTQT*100h + 0CDh
		xchg	ax,ds:[bx]
		mov	QTSegm,ds
		mov	QTOffs,bx
		mov	QTInst,ax
		pop	es
		pop	ax
		ret


;--------------------------------------------------------------------------;
; convert a file size to a normal longint                                  ;
.code
ToNormal:	ASSUME	ds:NOTHING, es:NOTHING
		push	bx
		push	dx
		or	dx,dx			; no bytes in last page?
		je	_L01Multiply
		dec	ax
_L01Multiply:
		mov	bx,512
		mul	bx
		pop	bx
		add	ax,bx
		adc	dx,0
		pop	bx
		ret
;--------------------------------------------------------------------------;
Info:		ASSUME	ds:NOTHING, es:NOTHING
		push	si
		mov	si,offset InfoTxt
		call	WriteASCIIZ
		pop	si
		jmp	WriteASCIIZ
;--------------------------------------------------------------------------;
IFDEF DEBUG
Debug:		ASSUME	ds:NOTHING, es:NOTHING
		push	si
		mov	si,offset DebugTxt
		call	WriteASCIIZ
		pop	si
		jmp	WriteASCIIZ
.data
DebugTxt	db	'DEBUG - ',0
DebugInt1	db	'Interrupt occured at ',0
DebugInt2	db	':',0
DebugInt3	db	', AX=',0
DebugInt4	db	'h.',0

DebugCom1	db	'Unable to match .COM identify value: BX=',0
DebugExe1	db	'Unable to match .EXE identify values: BX=',0
DebugExe2	db	'h, CX=',0
DebugExe3	db	'h, DX=',0
ENDIF
;--------------------------------------------------------------------------;
.code
Action:		ASSUME	ds:NOTHING, es:NOTHING
		push	si
		mov	si,offset ACT_init
		call	WriteASCIIZ
		pop	si
		jmp	WriteASCIIZ
;--------------------------------------------------------------------------;
Warning:	ASSUME	ds:NOTHING, es:NOTHING
		call	HomeCursor
		push	si
		mov	si,offset WarningTxt
		call	WriteASCIIZ
		pop	si
		jmp	WriteLnASCIIZ
;--------------------------------------------------------------------------;
Error:		ASSUME	ds:NOTHING, es:NOTHING
		call	HomeCursor
		push	si
		mov	si,offset ErrorTxt
		call	WriteASCIIZ
		pop	si
		jmp	WriteLnASCIIZ
;--------------------------------------------------------------------------;
FatalError:	ASSUME	ds:NOTHING, es:NOTHING
		mov	ds,SegData
		ASSUME	ds:DGROUP
		mov	Silent,FALSE
		call	HomeCursor
		push	si
		mov	si,offset FatalErrorTxt
		call	WriteASCIIZ
		pop	si
		jmp	WriteLnASCIIZ
;--------------------------------------------------------------------------;
SetDTA:		ASSUME	ds:NOTHING, es:NOTHING
		push	ds
		mov	ds,SegData
		ASSUME	ds:DGROUP
		mov	dx,offset DTABlock
		mov	ah,1Ah
		int21h
		pop	ds
		ASSUME	ds:NOTHING
		ret
;---------------------------------------------------------------------------;
.code
IncreaseMem:
		ASSUME	ds:NOTHING,es:NOTHING
		push	bx
		push	cx
		push	dx
		push	si
		push	ds
		push	es
		mov	ds,SegData
		ASSUME	ds:DGROUP
		mov	bx,0FFFFh
		mov	dx,SegProgPSP
		mov	es,dx
		ASSUME	es:NOTHING
		call	ResizeMem		; get largest size block
		mov	ax,bx                   ; substrac 1/16 for items
		mov	cl,4
		shr	ax,cl
		sub	bx,ax
		call	ResizeMem
		add	dx,bx
		mov	es:[0002h],dx
		cmp	SwitchV,FALSE
		je	_EndIncrease
		mov	si,offset INF_IncMem
		call	Info
		mov	ax,16
		mul	bx
		call	WriteLongInt
		mov	si,offset Info53
		call	WriteLnASCIIZ
_EndIncrease:
		pop	es
		pop	ds
		pop	si
		pop	dx
		pop	cx
		pop	bx
		ret
;---------------------------------------------------------------------------;
.code
GetYorN:	ASSUME	ds:NOTHING, es:NOTHING
		call	WriteASCIIZ
GTYN_input:
		call	GetChar
		and	al,11011111b
		cmp	al,'N'
		je	GTYN_inputok
		cmp	al,'Y'
		jne	GTYN_input
GTYN_inputok:
		push	ax
		push	ds
		mov	ds,SegData
		ASSUME	ds:DGROUP
		mov	DOS_Key,al
		mov	si,offset DOS_Key
		call	WriteLnASCIIZ
		pop	ds
		ASSUME	ds:NOTHING
		pop	ax
		cmp	al,'Y'
		ret
.data
DOS_Key		db	0,0
;--------------------------------------------------------------------------;
.code
WriteVersion:	ASSUME	ds:NOTHING, es:NOTHING
		push	si
		push	ds
		push	bx
		mov	ds,SegData
		ASSUME	ds:DGROUP
		cmp	Command,'S'
		jne	WV_writetxt
		mov	Silent,FALSE
		push	cx
		push	si
		push	di
		push	es
		mov	si,offset Filename1
		call	FindFilename
		mov	si,di
		mov	cx,13
		mov	al,0
		push	ds
		pop	es
		repnz	scasb
		call	WriteASCIIZ
		mov	si,offset Sep2
		sub	si,cx
		call	WriteASCIIZ
		mov	ax,DTA_FileSize
		mov	dx,DTA_FileSize+2
		call	WriteLongIntAl
		mov	si,offset Sep2 -2
		call	WriteASCIIZ
		pop	es
		pop	di
		pop	si
		pop	cx
		jmp	WV_write
WV_writetxt:
		push	si
		mov	si,offset ProgVerTxt
		call	WriteASCIIZ
		pop	si
WV_write:
		lodsw
		or	ax,ax
		je	WV_endwrite
		xchg	si,ax
		call	WriteASCIIZ
		xchg	si,ax
		jmp	WV_write
WV_endwrite:
		call	WriteLn
		cmp	Command,'S'
		jne	WV_finnish
		mov	Silent,TRUE
		jmp	Continue
WV_finnish:
		cmp	Command,'I'
		je	Continue
		mov	al,SwitchC
		or	al,SwitchCforced
		je	WV_exit
		mov	si,offset ASK_confirm
		call    GetYorN
		je	WV_exit
		jmp	Continue
WV_exit:
		mov	WasCompressed,TRUE
		pop	bx
		pop	ds
		pop	si
		ret

.data
Sep1		db	'            '
Sep2		db     	0
;--------------------------------------------------------------------------;
.code
AskPassword:	ASSUME	ds:NOTHING, es:NOTHING
		push	ds
		push	es
		mov	si,offset AskPswTxt
		call	WriteASCIIZ
		mov	es,SegData
		ASSUME	es:DGROUP
		mov	ds,SegData
		ASSUME	ds:DGROUP
		mov	di,offset Password
AP_GetPassKey:
		mov	ah,7
		int21h
		cmp	al,0Dh
		je	AP_EndPassword
		cmp	al,08
		je	AP_IsBack
		stosb
		mov	dl,al
		mov	ah,2
		int21h
		jmp	AP_GetPassKey

AP_IsBack:
		cmp	di,offset Password
		je	AP_GetPassKey
		dec	di
		mov	ah,2
		mov	dl,08
		int21h
		mov	dl,32
		int21h
		mov	dl,08
		int21h
		jmp	AP_GetPassKey

AP_EndPassword:
		mov	al,0
		stosb
		call	WriteLn
		pop	es
		pop	ds
		ret
.data
Password	db	80 dup (0)
AskPswTxt	db	'Program is protected, please enter password: ',0
;--------------------------------------------------------------------------;
.code
CheckHeader:
		ASSUME	ds:NOTHING,es:NOTHING
		push	es
		mov	es,SegData
		ASSUME	es:DGROUP
		mov	ax,ds:[si+RelocItemsCnt]
		cmp	ax,NrRelocFound
		jne	InvalidHeader

		mov	ax,RegSS
		sub	ax,SegProgram
		cmp	ax,ds:[si+InitialSS]
		jne	InvalidHeader

		mov	ax,RegCS
		sub	ax,SegProgram
		cmp	ax,ds:[si+InitialCS]
		jne	InvalidHeader

		mov	ax,RegSP
		cmp	ax,ds:[si+InitialSP]
		jne	InvalidHeader

		mov	ax,RegIP
		cmp	ax,ds:[si+InitialIP]
		jne	InvalidHeader

InvalidHeader:
		pop	es
		ret
;--------------------------------------------------------------------------;
ForceAllign:	ASSUME	ds:NOTHING,es:NOTHING
		push	ds
		mov	ds,SegData
		ASSUME	ds:DGROUP
		cmp	SwitchP,FALSE
		jne	EndForce
		mov	AlignmentSize,ax
EndForce:
		pop	ds
		ret

;--------------------------------------------------------------------------;

.code                                           ; data in codesegment
SegData		dw	0
SegStack	dw	0
OldInt21	dw	0,0
wTemp		dw	0

.data

FakePkSig label
		mov	word ptr ds:[005Ch],0
		mov	ax,ds
		add	ax,0
		push	ax
		mov	ax,0
		push	ax
		retf
FakePkSigl	equ	$ - FakePkSig

RegAX		dw	0
RegBX		dw	0
RegCX		dw	0
RegDX		dw	0
RegSI		dw	0
RegDI		dw	0
RegSP		dw	0
RegBP		dw	0
RegDS		dw	0
RegES		dw	0
RegSS		dw	0
RegIP		dw	0
RegCS		dw	0
Flags		dw	0

MySP		dw	0


ParSize		dw	16

Switches	db	'?ABCFGHIKLMNOPR'
IFDEF TBAV
		db	'S'
ENDIF ;TBAV
		db	'UV-'
SwitchesCnt	equ	$ - offset Switches

ProcessTxt	db	'processing file : ',0
SizeTxt		db	'DOS file size   : ',0
FileStrucTxt	db	'file-structure  : ',0
ProgVerTxt	db	'processed with  : ',0
NewSizeTxt	db	'new file size   : ',0
ToDestTxt	db	'writing to file : ',0
BinaryTxt	db	'binary (COM)',0
ExecutableTxt	db	'executable (EXE)',0
data_file$	db	'data file',0
New_Executable$ db	'New Executable ("'
NESig           dw      0
		db      '"'
RH		db	')',0

ExeSizes        db      'EXE part sizes  : header ',0
ExeSizes2       db      ' bytes, image ',0
ExeSizes3       db      ' bytes, overlay ',0
ExeSizes4       db      ' bytes',0
ExeSizes5	db	'File uses ',0
ExeSizes6	db	' fixup',0
ExeSizes7	db	's and requires atleast ',0
ExeSizes8	db	' bytes to load.',0

IsConvEXE$	db	', convertable',0
IsLoadHigh$	db	', loads into high memory',0
CRAct		db	CR
ACT_init	db	'action          : ',0
ACT_decomp   	db	'decompressing... ',0
ACT_fixups	db	'restoring relocation table... ',0
ACT_overlay	db	'copying overlay... ',0
ACT_remavirus 	db	'removing anti-virus code... ',0
ACT_remencrypt  db	'removing encryption... ',0
ACT_removeintro	db	'removing intro... ',0
ACT_remimmunize db	'removing immunize code... ',0
ACT_rempassword db	'removing password... ',0
ACT_remvirdat	db	'removing anti-virus data... ',0
ACT_tracing   	db	'tracing... ',0
ACT_toexe	db	'converting to .EXE file-structure... ',0
ACT_tocom	db	'converting to .COM file-structure... ',0
ACT_done	db	'done',0


ERR_reloc	db	'Unknown GI instruction, aborting.',0
ERR_INT00 	db	'(INT 00h) Divide overflow generated by CPU.',0
ERR_INT10	db	'(INT 10h) Unexpected use of video interrupt, action failed.',0
ERR_INT20	db	'(INT 20h) Unexpected program termination, action failed.',0
ERR_INT21	db	'(INT 21h) Unexpected call to DOS, action failed.',0
ERR_INT23	db	'(INT 23h) Ctrl-C or Ctrl-Break pressed by user.',0
ERR_unable	db	'Unable to remove this routine.',0

ME_BasicOp   	db	'perform basic operations',0
ME_ChildEnv	db	'create environment for program.',0
ME_NoLoad	db	'load program.',0
ME_Header	db	'store .EXE header.',0
ME_Fixups	db	'store relocation items.',0
ME_CopyOvrly	db	'copy overlay to new file.',0
ME_MarkFile	db	'load file to be inserted for marking.',0

TC_iscom	db	'Cannot convert, file already is a COM file.',0
TC_reloc	db	'Cannot convert, file has relocation items.',0
TC_csip		db	'Cannot convert, initial CS:IP not FFF0:0100.',0
TC_toolarge	db	'Cannot convert, file is too large for COM.',0
TC_overlay	db	'Cannot convert, file contains internal overlay.',0

WAR_header	db	'Invalid or missing stored header information.',0
WAR_FixupInImg	db	'File is invalid (fixups stored in image).',0

WarningTxt	db	'WARNING - ',0
InfoTxt		db	'INFO - ',0
FatalErrorTxt	db	'FATAL '
ErrorTxt	db	'ERROR - ',0

Info50		db	'Loading program at ',0
Info51		db	'h, blocksize ',0
Info53		db	' bytes.',0
Info60		db	'Required mem. ',0
Info61		db	'h, desired mem. ',0
Info62		db	'h, header slack ',0

INF_IncMem	db	'Increasing program''s blocksize to ',0
INF_pksig	db	'Adding '''
_pksig		dw	0
		db	''' signature to fake PKLITE decompression.',0Dh,0Ah,0

ASK_confirm	db	'Remove this routine from file (y/n)? ',0
ASK_continue	db	'Continue (y/n)? ',0
ASK_pksig	db      'Add code to fake PKLITE decompression (y/n)?',0

ORIG		EXEFILESTRUC ?

DTABlock label
DTA_Reserved	db	15h dup (0)
DTA_Attribute	db	0
DTA_FileTime	dw	0
DTA_FileDate	dw	0
DTA_FileSize	dw	0,0
DTA_Filename	db	0Dh dup (0)


SwitchHlp	db	FALSE			; show helpscreen
SwitchA 	db	FALSE			; automatic retry
SwitchB 	db	FALSE			; create .BAK file
SwitchC 	db	FALSE			; ask for confirmation
SwitchF		db	FALSE			; optimize fixups (HDROPT.EXE)
SwitchG		db	FALSE			; merge overlay into image
SwitchH 	db	FALSE			; strip header information
SwitchI 	db	TRUE			; interception of I/O ints
SwitchK 	db	TRUE			; PKSig [-|+|?]
SwitchL		db	FALSE			; use large memoryblock
SwitchM		db	FALSE			; MORE alike output
SwitchN		db	FALSE			; number output files
SwitchO 	db	FALSE			; overwrite existing file
SwitchP 	db	FALSE			; align header on 512 bytes
SwitchR 	db	FALSE			; remove overlay
IFDEF TBAV
SwitchS		db	TRUE 			; Use TbScanX
ENDIF ;TBAV
SwitchU 	db	TRUE			; update date/time stamp
SwitchV 	db	FALSE			; verbose
SwitchMinus	db	4			; - switch, not used

TempDS		dw	0
TempF		dw	0

Command		db	0

; /* memory data */
MemStrategy	dw	0
UMBState	dw	0
SegPSP		dw	0
SegHMAStart     dw      0
SegProgPSP	dw	0
SegProgram	dw	0
SegProgEnv	dw	0

SegFiles	MEMBLOCK <>		; filenames

ExeHeaderSz	dw	0,0
ExeImageSz	dw	0,0
ExeOverlaySz	dw	0,0

DefAlignSize	dw	10h		; default value
AlignmentSize	dw	?		; value to align headersize to

TempDouble	dw	0

; /* interrupt data */
HookedInts	db	0			; divide error
OI01		db	1			; single step (debug)
OI03		db	3			; Breakpoint
OI10		db	10h			; video interrupt
		db	20h			; program termination
		db	23h			; Ctrl-C
OIGS		db	INTGS			; used for breakpoints
OIGI		db	INTGI
OIQT		db	INTQT
		db	INTEP
HookedIntsCnt	equ	$ - offset HookedInts

OldInts 	dw	HookedIntsCnt * 2 dup (0)
IntsCopied	db	FALSE
ExpectedInts	dw	0
NoInts		db	0
Int10Routine	dw	offset Int10Def
Int20Routine	dw	0
Int21Routine	dw	offset Int21Def

EPOffs		dw	0
EPSegm		dw	0
EPInst		dw	0
QTOffs		dw	0
QTSegm		dw	0
QTInst		dw	0

HeaderBuild	dw	0

InitArea label					; variables specified here
						; are initialized (set to 0)
						; for each file
; /* memory structs */
SegEHInfo	MEMBLOCK <>			; 00h-1Ch of .EXE file
SegEHToItems	MEMBLOCK <>			; 1Ch to relocation items
SegEHAfter	MEMBLOCK <>			; data behind relocation items
SegEHAlign	MEMBLOCK <>			; extra data to align header

; /* overrule switches */
SwitchCforced	db	FALSE
SwitchGforced	db	FALSE
SwitchHforced	db	FALSE
SwitchLforced	db	FALSE
SwitchOforced	db	FALSE
SwitchRforced	db	FALSE
SwitchAforced	db	FALSE

; /* overrule new programsize */
ProgFinalOfs	dw	0
ProgFinalSeg	dw	0

; /* memory allocated for program */
TotalMem	dw	0

; /* relocation items storage variables */
SegItemStart	dw	0			; segment of first item block
SegItemCur	dw	0			; segment of current block
NrRelocFound	dw	0			; number of items found so far

; /* segment containing interrupt vectors (trace) */
SegProgInts	dw	0

; /* in-program flag.. should be zero (read: FALSE) anyway */
InProgram	db	FALSE
InProgramStatus	db	FALSE

; /* used to allow files to be processed more than once */
WasCompressed	db	FALSE

; /* indicates if files needs to be loaded high */
HighloadEXE	db	FALSE

; /* indicates if header was stored inside program, prevents changes */
HeaderStored	db	FALSE

; /* constant to add to final exe program file size */
ExeSizeAdjust	dw	0,0

InitSize equ $ - offset InitArea		; end of Init area



; /* file data */
FilesFound	dw	0
FilenameCnt	db	0
File1NmePtr	dw	?
FilePtr		dw	?
InfileTime	dw	?
InfileDate	dw	?
Handle1		dw	?
Handle2		dw	?
Handle3		dw	?
Handle4		dw	?
Filename1	db	128 dup (?)		; source file
Filename2	db	128 dup (?)		; destination file
Filename3	db	128 dup (?)		; temp buffer
Filename4	db	128 dup (?)		; temp file
TempFile	equ	Filename4

		dw	60 dup (?)
StackLoc	dw	?

End EntryPoint
