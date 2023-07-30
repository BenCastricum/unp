; /* user defineables */
TMPFile		equ	'UNPTEMP$.$$$',0	; Temp-filename
EXTRAMEM	equ	200h			; memory added for .EXE files

; /* special UNP constants */
INTGS		equ	0F4h
INTGI		equ	0F5h
INTQT		equ	0F6h
INTEP		equ	0F7h

; /* normal constants */
FALSE		equ	0
TRUE		equ	1
ASK		equ	2

; /* Trace Flag */
TF	EQU 0100h

; /* tasm options */
smart
model small
jumps
warn

; /* ASCII values */
TAB		equ	9
LF		equ	10
CR		equ	13
EOF		equ	26

; /* standerd device handlers */
STDIN		equ	0		; Standard input device
STDOUT		equ	1		; Standard output device
STDERR		equ	2		; Standard error device
STDAUX		equ	3		; Standard auxiliary device
STDPRN		equ	4		; Standard printer device

; /* exit codes */
ECNOERROR	equ	0		; no error occured
ECHELP		equ	1		; help text is displayed
ECNOFILES	equ	2		; no files found to process
ECINVALIDCL	equ	3		; invalid combination on CL
ECDOSERROR	equ	4		; some I/O error occured
ECMEMERROR	equ	5		; could not allocate enough memory
ECDIVERROR	equ	6		; CPU generated divide overflow
ECCTRLCERROR	equ	7		; user pressed ^C or ^Break
ECOPCODEERROR	equ	8		; attempt to execute invalid opcode

; /* EXE file header structure */
EXEFILESTRUC	STRUC
MZSignature	dw	?
SizeMod512	dw	?
SizeDiv512	dw	?
RelocItemsCnt	dw	?
HeaderSz	dw	?
MinParMem	dw	?
MaxParMem	dw	?
InitialSS	dw	?
InitialSP	dw	?
Checksum	dw	?
InitialIP	dw	?
InitialCS	dw	?
RelocOffs	dw	?
OverlayNr	dw	?
_nothing_	db 	24h dup (?)
EXEFILESTRUC ENDS

; /* stucture to ease the use of memory blocks */
MEMBLOCK	STRUC
A		dw	0		; segment of block
S		dw	0		; size of block (in bytes)
MEMBLOCK ENDS
