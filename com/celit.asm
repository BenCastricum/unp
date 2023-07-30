; CELIT.ASM
;
; Removes     :	ELITE V1.00aF
; created on  : 23-Okt-1994
; last update : 23-Okt-1994


.code
CELIT_entry:
		ASSUME	ds:NOTHING,es:DGROUP
		mov	si,RegIP
		mov	di,offset CELITs
		mov	cx,CELITl
		repz	cmpsb
		jne	CELIT_exit
		mov	ax,ds:[010Ch]
		add	ax,ds:[0117h]
		sub	ax,ds:[0109h]
		xchg	bx,ax
		add	bx,9C8Eh-9BB4h

		mov	si,offset CELIT_ver
		call	WriteVersion

		mov	si,offset ACT_remavirus
		call	HandleCom
CELIT_exit:
		ret

.data
CELITs label
		db	9Ch			; pushf
		db	6			; push   es
		db	1Eh			; push   ds
		db	60h			; pusha
		db	0FDh			; std
		db	0B9h       		; mov    cx,XXXX
CELITl		equ	$ - offset CELITs

CELIT_ver label
dw EXELITE, _V1_00aF, 0