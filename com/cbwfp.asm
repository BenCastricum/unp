; CBWFP.ASM
; last update : 19-Apr-1994
;
; 20-Mar-1994: changed code to take advantage of final size overide code
; 19-Apr-1994: skipped first near jump (E9h)

.code
CBWFP_entry:	ASSUME	ds:NOTHING,es:DGROUP
		mov	si,RegIP
		mov	dx,si			; program size in DX
		mov	di,offset CBWFPsa
		mov	cx,CBWFPla
		add	ax,0500h		; actually 400h
		call	FindCode
		je	CBWFP_found

		mov	si,dx
		mov	di,offset CBWFPsb
		call	FindCode
		jne	CBWFP_exit

CBWFP_found:
		cmp	byte ptr ds:[si-2],87h	; xchg [si],
		jne	CBWFP_exit
		mov	bx,DTA_FileSize
		sub	bx,si
		add	bx,0100h - 8
		mov	ax,offset CBWFP_iid
		call	cIndexedId

		mov	bx,si
		call	Break
		add	bx,90A0h-9098h
		call	Break
		cmp	[bx+3],0C62Eh
		je	CBWFP_IsPass
		add	bx,90C5h-90A0h
		call	Break
		add	bx,9111h-90C5h
CBWFP_go:
		dec	ProgFinalSeg
		mov	ProgFinalOfs,dx
		mov	si,offset ACT_remencrypt
		jmp	HandleCom

CBWFP_IsPass:
		mov	byte ptr [bx+917Bh-913Ah],0BBh
		mov	byte ptr [bx+91EDh-913Ah],0BEh
		mov	byte ptr [bx+91F1h-913Ah],0B6h
		mov	byte ptr [bx+91F8h-913Ah],0A4h
		mov	byte ptr [bx+923Dh-913Ah],0B2h
		add	bx,91A8h-913Ah
		call	Break
		add	bx,91B5h-91A8h
		jmp	CBWFP_go

CBWFP_exit:
		ret

.data
CBWFPsa label
;		xchg	[si],bx			; register used unsure
		inc	si
		inc	si
		dec	cx
		db	74h,3			; jmp +3
		db	0E9h			; jmp near
CBWFPla		equ	$ - offset CBWFPsa

CBWFPsb label
;		xchg	[di],bx			; register used unsure
		inc	di
		inc	di
		dec	cx
		db	74h,3			; jmp +3
		db	0E9h			; jmp near
CBWFPlb		equ	$ - offset CBWFPsb


CBWFP_iid label
dw 323, PASSCOM, _V2_0, 0
dw 207, ENCRCOM, _V2_0, 0
dw   0, LB, ENCRCOM, _or, _, PASSCOM, RB, 0