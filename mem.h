; /* memory allocation strategys */
MSLFirstFit	equ	00h		; first block low large enough
MSLBestFit	equ	01h		; smallest block low large enough
MSLLastFit	equ	02h		; block highest in low memory
MSHFirstFit	equ	40h		; same for high memory
MSHBestFit	equ	41h
MSHLastFit	equ	42h
MSHLFirstFit	equ	80h		; first high then low memory
MSHLBestFit	equ	81h
MSHLLastFit	equ	82h

; /* prototyping */
.code
extrn GetFreeMem: near
extrn AllocateMem: near
extrn FreeMem: near
extrn ResizeMem: near
extrn GetMemStrategy: near
extrn SetMemStrategy: near
extrn GetUMBState: near
extrn SetUMBState: near