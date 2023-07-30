; check if file adds a pklite signature into the PSP

.code
EPKSG_entry:	ASSUME	ds:NOTHING, es:NOTHING
		mov	es,SegData
		ASSUME	es:DGROUP
		mov	ds,RegCS
		ASSUME	ds:NOTHING
		mov	si,RegIP
		lodsw
		cmp	ax,06C7h
		jne	EPKSG_checkpop
		lodsw
		cmp	ax,005Ch
		jne	EPKSG_exit
EPKSG_trace:
		mov	ax,RegIP
		mov	bx,RegCS
		call	Trace
		cmp	bx,RegCS
		jne	EPKSG_exit
		cmp	ax,RegIP
		jb	EPKSG_trace

EPKSG_exit:
		ret

EPKSG_checkpop:
		cmp	ax,8F5Fh
		jne	EPKSG_exit
		lodsw
		cmp	ax,0C305h
		je	EPKSG_trace
		cmp	ax,0CB05h
		jne	EPKSG_exit
		mov	ds,RegSS
		mov	si,RegSP
		mov	ax,SegProgPSP
		cmp	ax,[si+6]
		jbe	EPKSG_trace
		sub	[si+8],ax
		add	[si+6],ax
		jmp	EPKSG_trace

