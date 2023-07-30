; checks for PGMPAK V0.14

.code
EPGMP_entry:	ASSUME	ds:NOTHING, es:DGROUP
		mov	es,SegData
		ASSUME	es:DGROUP
		mov	ds,RegCS
		ASSUME	ds:NOTHING

		mov	si,02DCh		; search Create child PSP
		mov	ax,02E4h
		mov	di,offset EPGMPs
		mov	cx,EPGMPl
		call	FindCode
		jne	EPGMP_exit

		lea	bx,[si+4]		; location of int 21

		mov	si,0359h		; search GI
		mov	ax,0367h
		mov	di,offset EPGMPs2
		mov	cx,EPGMPl2
		call	FindCode
		jne	EPGMP_exit
		mov	bp,si

		mov	si,038Dh		; search QT
		mov	ax,03A1h
		mov	di,offset EPGMPs3
		mov	cx,EPGMPl3
		call	FindCode
		jne	EPGMP_exit
		mov	dx,si

		mov	cx,bp

		mov	si,offset EPGMPid
		call	eIndexedId

		mov	ExpectedInts,offset EPGMP_ints

		call	Break
		add	RegIP,2			; skip creation of PSP
		add	bx,2
		mov	ax,RegDS
		mov	SegProgPSP,ax
		add	ax,10h
		mov	SegProgram,ax

		push	es
		mov	es,SegEHInfo.A
		mov	es:[MaxParMem],0FFFFh
		pop	es

		mov	si,offset ACT_decomp
		jmp	SetBreakpoints

EPGMP_exit:
		ret

.data
EPGMP_ints label
		db	1Ah			; Set Disk Transfer Address
		db	30h			; Get DOS version
		db	49h			; Free memory block
		db	4Ah			; Allocate memory
;		db	55h			; Create child PSP
		db	0

EPGMPs label
		db	8Eh,0DAh		; mov    ds,dx
		db	0B4h,55h		; mov    ah,55
		db	0CDh,21h		; int    21
EPGMPl		equ	$ - offset EPGMPs

EPGMPs2 label
		db	26h,87h,5		; xchg   es:[di],ax
EPGMPl2		equ	$ - offset EPGMPs2

EPGMPs3 label
		db	2Eh,0FFh,6Ch,0FAh	; jmp    cs:far [si-06]
EPGMPl3		equ	$ - offset EPGMPs3

EPGMPid label
dw 02E7h, 0359h, 038Dh, PGMPAK, _V0_13, 0
dw 02E8h, 0363h, 0396h, PGMPAK, _V0_14, 0
dw 02E8h, 0367h, 03A1h, PGMPAK, _V0_15, 0
dw    0h,    0h,    0h, LB, PGMPAK, RB, 0
