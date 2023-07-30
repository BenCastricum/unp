; CSCRM.ASM
; last update : 21-Mar-1994
;
; 21-Mar-1994 ; changed code to take advantage of final size overide code

.code
CSCRM_entry:	ASSUME	ds:NOTHING, es:NOTHING
		mov	es,SegData
		ASSUME	es:DGROUP
		mov	ds,RegCS
		ASSUME	ds:NOTHING
		mov	si,0100h
		lodsb
		cmp	al,0EBh
		jne	CSCRM_exit
		lodsb
		mov	ah,0
		add	si,ax
		mov	di,offset CSCRM4s
		mov	cx,CSCRM4l
		repz	cmpsb
		jne	CSCRM_exit
		mov	bx,4
		mov	si,offset CSCRMver
		call	WriteVersion
		mov	bx,016Ch
		call	Break
		mov	bx,0169h
		call	Break
		mov	bx,016Ch
		call	Break
		mov	bx,016Eh
		call	Break
		mov	bx,01D6h
		call	Break
		sub	byte ptr ds:[0104h],2		; size - 0100h
		mov	bx,01FBh
		mov	si,offset ACT_remencrypt
		jmp	HandleCom

CSCRM_exit:
		ret


.data
CSCRM4s label
		cli
		cld
		db	31h, 0FFh		;xor	di,di
		mov	es,di
		push	es:word ptr [0010h]
		push	es:word ptr [0012h]
		db	8Dh,36h,9,1		;lea	si,ds:[0109]
		mov	cx,13h
		rep	movsb
		mov	cx,7
		int	0
CSCRM4l		equ	$ - offset CSCRM4s

CSCRMver label
dw LB, SCRAMBLER, _V1_00, RB   , 0