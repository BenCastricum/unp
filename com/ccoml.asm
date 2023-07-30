; CCOML.ASM
; last update : 19-Apr-1994
;
; 19-Apr-1994: skipped first near jump (E9h)

.code
CCOML_entry:	ASSUME	ds:NOTHING,es:DGROUP
		mov	si,RegIP
		add	si,9013h-9000h
		mov	ax,si			; search only at 1 place
		mov	di,offset CCOMLs
		mov	cx,CCOMLl
		call	FindCode
		jne	CCOML_exit
		mov	bx,si
		add	si,9000h-9013h
		mov	ProgFinalOfs,si
		dec	ProgFinalSeg

		push	bx
		mov	si,offset CCOMLver
		call	WriteVersion
		pop	bx

		add	bx,9036h-9013h
		mov	si,offset ACT_remencrypt
		jmp	HandleCom

CCOML_exit:
		ret

.data
CCOMLs label
		db	0BEh,4,0		; mov	si,0004
		db	81h,0C6h,3,1		; add   si,0103
		db	3,0F3h			; add   si,bx
		db	0BFh,0,1		; mov   di,0100
		db	0B9h,3,0		; mov   cx,0003
		db	0F3h,0A4h		; rep	movsb
                db	2Eh,8Ah,87h,6,1     	; mov   al,cs:[bx+0106]
CCOMLl		equ	$ - offset CCOMLs

CCOMLver label
dw COMLOCK, _V0_10, 0