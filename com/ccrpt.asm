; CCRPT.ASM
; last update : 19-Apr-1994
;
; 19-Apr-1994: skipped first near jump (E9h)

.code
CCRPT_entry:	ASSUME	ds:NOTHING,es:DGROUP
		mov	si,RegIP
		add	si,6
		mov	di,offset CCRPT1s
		mov	cx,CCRPT1l
		repz	cmpsb
		jne	CCRPT_exit
		lea	bx,[si+902Eh-901Ah]
		mov	si,offset CCRPTver
		call	WriteVersion
		mov	si,offset ACT_remencrypt
		jmp	HandleCom


CCRPT_exit:
		ret

.data
CCRPT1s label
		db	8Bh,0FEh		; mov    di,si
		db	8Bh,4Eh,34h		; mov    cx,[bp+34]
		db	90h			; nop
		db	32h,0E4h		; xor    ah,ah
		db	0ACh			; lodsb
		db	33h,0C1h		; xor    ax,cx
		db	33h,46h,18h		; xor    ax,[bp+18]
		db	90h			; nop
		db	32h,0C4h		; xor    al,ah
		db	32h,0E4h		; xor    ah,ah
		db	0CCh			; int    03
CCRPT1l		equ	$ - offset CCRPT1s


CCRPTver label
dw CRYPTA, _V1_00, 0