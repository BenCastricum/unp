; CPROT.ASM
; last update : 19-Apr-1994
;
; 18-Sep-1993 ; changed V3.0/V3.1 code to identify program before a part of
;	      ; it was executed
; 20-Sep-1993 ; same change as above to V2.0 code
; 13-Mar-1994 ; added V4.0
; 21-Mar-1994 ; changed code to take advantage of final size overide code
; 19-Apr-1994 ; skipped first near jump (E9h)

.code
CPROT_entry:	ASSUME	ds:NOTHING, es:NOTHING
		mov	es,SegData
		ASSUME	es:DGROUP
		mov	ds,RegCS
		ASSUME	ds:NOTHING
		mov	si,RegIP
		lodsb
		cmp	al,0B8h			; mov ax,XXXX ?
		jne	CPROT_check30

		lodsw				; V1.0 starts with a rather
		mov	di,offset CPROTs	; weird way to jump to the
		mov	cx,CPROTl		; main code
		repz	cmpsb
		jne	CPROT_check20
		mov	bx,ax
		add	bx,905Ch-903Fh
		push	bx
		mov	bx,1011h
		mov	ax,offset CPROTiid
		call	cIndexedId
		pop	bx
CPROT_go:
		mov	si,offset ACT_remencrypt
		jmp	HandleCom
CPROT_check20:
		mov	si,0101h
		lodsw				; V2.0 uses small extention
		mov	di,offset CPROT20s	; to the code of V1.0
		mov	cx,CPROT20l
		repz	cmpsb
		jne	CPROT_exit
		push	ax
		mov	bx,20h
		mov	ax,offset CPROTiid
		call	cIndexedId
		mov	bx,0178h
		call	Break
		pop	bx
		add	bx,909Ch-9079h
		jmp	CPROT_go

CPROT_check30:
		cmp	al,0E8h			; call XXXX ?
		jne	CPROT_exit
		lodsw
		add	si,ax			; call is relative so add si
		mov	ax,si
		mov	di,offset CPROT30S
		mov	cx,CPROT30l
		repz	cmpsb
		jne	CPROT_exit
		mov	bx,ax
		mov	bl,ds:[bx+015Fh]	; FF for V3.1, 00 for V3.0
		and	bl,1
		add	bl,30h
		mov	bh,0
		push	ax
		mov	ax,offset CPROTiid
		call	cIndexedId
		pop	bx
		push	bx
		add	bx,016Bh
		call	Break
		pop	bx
		add	bx,0B6h
		jmp	CPROT_go

CPROT_check40:	ASSUME	ds:NOTHING, es:NOTHING
		mov	es,SegData
		ASSUME	es:DGROUP
		mov	ds,RegCS
		ASSUME	ds:NOTHING

		mov	si,RegIP
		mov	ax,si
		mov	di,offset CPROT40S
		mov	cx,CPROT40l
		repz	cmpsb
		mov	bp,ax
		jne	CPROT_check50
		add	bp,3
		mov	bx,40h
		mov	ax,offset CPROTiid
		call	cIndexedId
		mov	ax,RegDS		; weird undocumented
		mov	RegDX,ax		; assumption by V4.0
		lea	bx,[bp+(-113h+2AEh)+1C8h-1A0h]
		call	Break
		sub	bx,91C8h-90CCh
		sub	bp,5
		mov	ProgFinalOfs,bp
		dec	ProgFinalSeg
		jmp	CPROT_go

comment /*

 The following message was received from Kemal Djakman (djakman@fwi.uva.nl) :

  Hi Ben,

  In your BETA.TXT, you spoke about still having problem with correctly
  recognizing .COM files processed with PROTECT! EXE COM v5.0

  As I know it, the problem is the 'false positives' reported by UNP.
  Probably because your current algorithm is not strict enough.

  Of course I don't know how does your current recognizer works, and I
  understand very little of assembly language, but I want to help and
  I happen to have here the shareware version of PROTECT! v5.0.

  So, after some testing, I thought I saw some pattern.  All .COM files
  processed with PROTECT! start like this:

	jmpn    start           ;three bytes instruction
	...
	(unknown bytes)
	...
  start:
	mov <reg>, <imm1>       ;mongword value into register
	<opr> <reg>, <imm2>

  The <reg> is one of the registers BX,DX,SI,DI, or BP.
  The <imm1> and <imm2> are immediate values.
  The <opr> is one of the operations ADD,SUB,XOR,ROL, or ROR.

  Mostly, all the immediate values are word (2 bytes) values, except when
  the operation <opr> is a ROL or a ROR, in which case it is always 1.

  Thus, I thought of the following recognition strategy to determine if
  a .COM file is processed with PROTECT EXE COM v5.0:

  (1) The first byte must be E9h, which is the 'jmp' code
  (2) Read the next 2 bytes and increase the file offset with that value
  (3) The first 5 bits of the byte in this position must be 10111 (mon word)
  (4) The last 3 bits must not be 100 or equal to or less than 001
  (5) Save those 3 bits value, because that is the register used
  (6) Skip over the 2 bytes which represent the <imm1> value
  (7) Current byte must be either one of the two possibilities:
      a) 81h (for ADD,SUB, or XOR)
      b) D1h (for ROL or ROR)
 (8a) The next byte must have bits which conform to this pattern:
      2 bits: 11                                                 [bits 7-6]
      3 bits: 000, 101 or 110 (ADD,SUB, or XOR)                  [bits 5-3]
      3 bits: equal to the saved register name on step (5)       [bits 2-0]
 (8b) *OR* The next byte must have this bits pattern:
      2 bits: 11                                                 [bits 7-6]
      3 bits: 000 (ROL) or 001 (ROR)                             [bits 5-3]
      3 bits: equal to the saved register name on step (5)       [bits 2-0]

  Please forgive me if my idea is too stupid to be implemented :-)


  ---kemal---

*/

CPROT_check50:					; At this point step (1) and
						; and (2) have already been
						; taken care of.
		mov	cx,29h
		mov	si,ax
		lodsb
		mov	ah,al                   ; (5)
		and	al,11111000b		; check first 5 bits (3)
		cmp	al,10111000b
		jne	CPROT_exit
		and	ah,00000111b            ; check last 3 bits (4)
		cmp	ah,00000100b
		je	CPROT_exit
		cmp	ah,00000001b
		jbe	CPROT_exit
		add	si,2                    ; (6)
		lodsb
		and	al,81h			; (7) more or less..
		cmp	al,81h
		jne	CPROT_exit
		lodsb
		or	ah,11000000b		; (8a+b) well.. kinda..
		and	al,11000111b
		cmp	ah,al
		jne	CPROT_exit

CPROT_scan:
		lodsw
		dec	si
		cmp	ax,01EBh		; jmp +1 ?
		je	CPROT_add1
		cmp	ax,04EBh		; jmp +4 ?
		je	CPROT_Sig2
		cmp	ax,0E450h		; push ax ; in al,
		je	CPROT_Sig3
		cmp	cx,15h
		jnl	CPROT_next
		cmp	ax,0274h
		je	CPROT_Is50
		cmp	al,75h
		jne	CPROT_next
		cmp	ah,80h
		ja	CPROT_Is50

CPROT_next:
		loop	CPROT_scan
		jmp	CPROT_exit

CPROT_Sig2:
		cmp	[si+2],ax		; jmp +4 ?
		je	CPROT_add8
		jmp	CPROT_next
CPROT_Sig3:
		cmp	[si+1],5021h		; 21h; push ax
		jne	CPROT_next
CPROT_add1A:
		add	si,12h
CPROT_add8:
		add	si,7
		dec	cx
CPROT_add1:
		inc	cx
		inc	si
		jmp	CPROT_scan

CPROT_Is50:
		sub	bp,2
		mov	ProgFinalOfs,bp
		dec	ProgFinalSeg

		mov	bx,50h
		mov	ax,offset CPROTiid
		inc	SwitchCforced
		call	cIndexedId
CPROT_trace:
		call	Trace
		mov	si,RegIP
		lodsw
		cmp	ax,274h			; jne +2 ?
		jne	CPROT_checkJe
		lodsw
CPROT_checkCall:
		lodsw
		cmp	ax,0E8h			; call +0 ?
		jne	CPROT_exit
		sub	si,2			; back to call +0
		jmp	CPROT_gotCall
CPROT_checkJe:
		cmp	al,75h			; je?
		jne	CPROT_trace
		cmp	ah,80h			; backwards je ?
		jb	CPROT_exit
		jmp	CPROT_checkCall

CPROT_gotCall:
		mov	bx,si
		call	Break
		add	bx,90h
		call	Break
		add	bx,152h
		jmp	CPROT_go


CPROT_exit:
		ret

.data
CPROTs label
;		db	0B8h			; 0100h mov  ax,
;		dw	?			; 0101h      <offset main>
		db	50h			; 0103h push ax
		db	0E9h, 01h, 00h		; 0104h jmp  0108h
		db	8Ch			; 0107h
		db	0C6h, 06h		; 0108h move byte ptr
		dw	0107h			; 010Ah      [0107h]
		db	0C3h			; 010Ch      0C3h (ret)
		db	0EBh, 0F8h		; 010Dh jmp  0107h
CPROTl		equ	$ - offset CPROTs

CPROT20s label
;		db	0B8h			; 0100h mov  ax,
;		dw	?			; 0101h      <offset main>
		db	50h			; 0103h push ax
		db	0B8h			; 0104h mov  ax,
		dw	0150h			; 0105h      0150h
		db	50h			; 0107h push ax
		db	0E9h, 01h, 00h		; 0108h jmp  010Ch
		db	8Ch			; 010Bh
		db	0C6h, 06h		; 0108h move byte ptr
		dw	010Bh			; 010Ah      [010Bh]
		db	0C3h			; 010Ch      0C3h (ret)
		db	0EBh, 0F8h		; 010Dh jmp  010Bh
CPROT20l	equ	$ - offset CPROT20s

CPROT30S label
		push	ax
		push	ds
		push	es
		push	cs
		push	bp
		push	cs
CPROT30l	equ	$ - offset CPROT30S

CPROT40S label
		db	0E8h,0,0		; call   +0
		db	5Dh			; pop    bp
		db	81h,0EDh,13h,01		; sub    bp,0113
		db	33h,0C0h		; xor    ax,ax
		db	8Eh,0D8h		; mov    ds,ax
		db	8Bh,0F0h		; mov    si,ax
		db	0BFh,70h,0		; mov    di,0070
		db	0B9h,8,0		; mov    cx,0008
		db	0FCh			; cld
		db	0F3h,0A5h		; rep movsw
		db	0FDh			; std
CPROT40l	equ	$ - offset CPROT40S

CPROTiid label
dw 0010h    , PROTECT, _V1_0		 , 0
dw 1011h    , PROTECT, _V1_0, _or, _V1_1 , 0
dw 0011h    , PROTECT, _V1_1             , 0
dw 0020h    , PROTECT, _V2_0             , 0
dw 0030h    , PROTECT, _V3_0             , 0
dw 0031h    , PROTECT, _V3_1             , 0
dw 0040h    , PROTECT, _V4_0             , 0
dw 0050h    , PROTECT, _V5_0             , 0
dw 0000h    , LB, PROTECT, RB            , 0
