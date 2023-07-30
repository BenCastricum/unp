; CMCLK.ASM
; last update : 19-Apr-1994
;
; 21-Mar-1994: changed code to take advantage of final size overide code
; 19-Apr-1994: skipped first near jump (E9h)

.code
CMCLK_entry:	ASSUME	ds:NOTHING,es:DGROUP
		mov	si,RegIP
		mov	dx,si			; program size in dx
		lea	ax,[si+10h]
		mov	di,offset CMCLK2s
		mov	cx,CMCLK2l
		call	FindCode
		jne	CMCLK_exit
		push	si
		mov	si,offset CMCLKver
		call	WriteVersion
		pop	si
		lea	bx,[si+1640h-1611h]
		mov	ProgFinalOfs,dx
		dec	ProgFinalSeg
		mov	si,offset ACT_remencrypt
		jmp	HandleCom
CMCLK_exit:
		ret

.data
CMCLK2s label
		db	29h, 0C0h		; sub ax,ax
		mov	es,ax
		mov	byte ptr es:[0004h],49h
CMCLK2l		equ	$ - offset CMCLK2s -1	; 49 uncertain

CMCLKver label
dw MCLOCK, _V1_2, _or, _V1_3, 0
