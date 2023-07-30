; CNTBD.ASM
; last update : 19-Apr-1994
;
; 19-Apr-1994: skipped first near jump (E9h)

.code
CNTBD_entry:	ASSUME	ds:NOTHING,es:DGROUP
		mov	si,RegIP
		lea	dx,[si-1]		; save possible COM length
		                                ; -1 > size adjustment
; ANTIBODY adds 1-16 bytes to program

		add	si,4
		mov	di,offset CNTBDs
		mov	cx,CNTBDl
		repz	cmpsb
		jne	CNTBD_exit

		mov	si,offset CNTBD_ver
		call	WriteVersion

		mov	bx,dx
		add	bx,11h
		call	Break
		add	bx,9070h-9020h
		call	Break
		add	bx,906Bh-9070h
		call	Break
		add	bx,9070h-906Bh
		call	Break
		add	bx,9073h-9070h
		call	Break

		mov	bx,0134h
		mov	ds,RegCS
		mov	RegDI,dx
		mov	RegIP,0126h
		mov	si,offset ACT_remavirus
		call	HandleCom
CNTBD_exit:
		ret

.data
CNTBDs label
		mov	cx,0109h
		mov	bx,[di-02h]
		xor    	[di],bx
		dec	di
		dec	di
CNTBDl		equ	$ - offset CNTBDs

CNTBD_ver label
dw ANTIBODY, 0
