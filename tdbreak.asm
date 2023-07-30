        	ASSUME	ds:NOTHING, es:NOTHING
		mov	ds,SegData
		ASSUME	ds:DGROUP
		in	al,21h
		and	al,0FDh
		out	21h,al
		cli
		mov     sp,RegSP
		mov     ss,RegSS
		sti	
		push	Flags
		push	RegCS
		mov	ax,RegIP
		inc	ax
		push	ax
		mov     si,RegSI
		mov     di,RegDI
		mov     bp,RegBP
		mov     ax,RegAX
		mov     bx,RegBX
		mov     dx,RegDX
		mov     cx,RegCX
		mov	es,RegES
		push	word ptr [OldInts+(OI3-HookedInts)*4+2]		
		push	word ptr [OldInts+(OI3-HookedInts)*4]
		mov	ds,RegDS
		retf