; /* dos attribute bits */
AT_READONLY	equ	1
AT_HIDDEN	equ	2
AT_SYSTEM	equ	4
AT_VOLLABEL	equ	8
AT_DIRECTORY	equ	16
AT_ARCHIVE	equ	32

; /* prototyping */
.code
extrn SetExecOnly: near
extrn SetSrchAttrib: near
extrn FindFirst: near
extrn FindNext: near
extrn OpenFile: near
extrn CreateFile: near
extrn ReadFile: near
extrn WriteFile: near
extrn CloseFile: near
extrn WriteLnASCIIZ: near
extrn WriteLn: near
extrn WriteASCIIZ: near
extrn WriteLongInt: near
extrn WriteLongIntAl: near
extrn WriteHexWord: near
extrn GetChar: near
extrn ReadStamp: near
extrn WriteStamp: near
extrn DeleteFile: near
extrn RenameFile: near
extrn MovePointer: near
extrn HomeCursor: near
extrn MoveFile: near
extrn CopyFile: near