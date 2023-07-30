; CSLFD.ASM
; last update : 19-Apr-1994
;
; 21-Mar-1994: changed code to take advantage of final size overide code
; 19-Apr-1994: skipped first near jump (E9h)

.code
CSLFD_entry:
		ASSUME	ds:NOTHING,es:DGROUP
		mov	ax,RegIP
		mov	si,ax
		mov	di,offset CSLFDs
		mov	cx,CSLFDl
		repz	cmpsb
		jne	CSLFD_exit
		mov	dx,ax
		dec	ah			; set bp
		mov	RegBP,ax

		mov	si,offset CSLFD_ver
		call	WriteVersion

		mov	bx,dx
		add	bx,9082h-9000h
		mov	RegIP,bx
		add	bx,908Ch-9082h
		mov	ProgFinalOfs,dx
		dec	ProgFinalSeg
		mov	si,offset ACT_remavirus
		call	HandleCom
CSLFD_exit:
		ret

.data
CSLFDs label
		db	0E8h, 060h, 07h
		db	0E8h, 074h, 03h
		mov	byte ptr cs:[bp+09F8h],0
CSLFDl		equ	$ - offset CSLFDs

CSLFD_ver label
dw SELF_DISINFECT, _V0_90b, 0