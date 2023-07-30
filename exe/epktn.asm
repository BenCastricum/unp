; /**/                                                                      ;
; /*                                                                        ;
;     PKTINY V1.0 and V1.4                                                  ;
;                                                                           ;
;     This routine merely changes the program to let it act like a          ;
;     normal Tinyprog'ed program.                                           ;
;	                                                                 */ ;
;	                                                               /**/ ;

.code


EPKTN_entry:	ASSUME	ds:NOTHING, es:NOTHING	; assume nothing on entry
		mov	es,SegData
		ASSUME	es:DGROUP
		mov	ds,RegCS
		ASSUME	ds:NOTHING
		xor	si,si
		mov	di,PKLITE+2
		mov	cx,2
		repz	cmpsw
		jne	EPKTN_exit

EPKTN_go:
		mov	bl,byte ptr ds:[107h]
		mov	bh,0
		mov	ax,offset EPKTN_iid
		call	cIndexedId
		xor	bx,bx
		mov	cx,20h
EPKTN_trace:
		call	Trace
		mov	si,RegIP
		lodsb
		dec	si
		cmp	al,72h			; JB ? (286+ check)
		jne	EPKTN_TrapSS
		mov	byte ptr ds:[si],0EBh
EPKTN_TrapSS:		
		cmp	al,83h			; add sp,2 (debug trap)
		jne	EPKTN_isDone
		add	RegIP,3
		add	bx,2
EPKTN_isDone:
		cmp	al,0FFh
		jne	EPKTN_normal
		add	RegSP,bx
		xor	bx,bx
EPKTN_normal:
		or	si,si
		je	EPKTN_exit
		loop	EPKTN_trace

EPKTN_exit:
		ret

.data
EPKTN_iid label
dw 0C6h, PKTINY, _V1_0, 0
dw 0E9h, PKTINY, _V1_4, 0
dw 0D2h, PKTINY, _V1_5, 0
dw 0C0h, PKTINY, _V1_5, 0
dw 0, LB, PKTINY, RB,0