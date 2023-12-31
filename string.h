.data

string Macro Itsname, It
Itsname&$	db	It,0
Itsname		equ	offset Itsname&$
endm

vstring Macro Itsname, It
Itsname&$	db	' V',It,0
Itsname		equ	offset Itsname&$
endm

dummy		db	0			; avoid 0 offset

string		AINEXE,		'AINEXE'
string		ANTIBODY,	'ANTIBODY'
string		ANTI_VIRUS,	'ANTI-VIRUS'
string		AVPACK,		'AVPACK'
string		AXE,		'AXE'
string		COM2CRP,	'COM2CRP'
string		COMLOCK,	'COMLOCK'
string 		COMPACK, 	'COMPACK'
string		COMPRESSOR,	'COMPRESSOR'
string		CENTRAL_POINT_,	'CENTRAL POINT '
string		CRYPT,		'CRYPT'
string		CRYPTA,		'CRYPTA'
string		CRYPTCOM,	'CRYPTCOM'
string		DELTAPACKER,	'DELTAPACKER'
string		DIET,		'DIET'
string		EXELITE,	'EXELITE'
string		ENCRCOM,	'ENCRCOM'
string		EPW,		'EPW'
string		EXEPACK,	'EXEPACK'
string		EXPAKFIX,	'EXPAKFIX'
string		F_XLOCK,	'F-XLOCK'
string		ICE,		'ICE'
string		IMPLODER,	'IMPLODER'
string		KVETCH,		'KVETCH'
string		LINK,		'LINK'
string		LZEXE,		'LZEXE'
string		MCLOCK,		'MCLOCK'
string		MEGALITE,	'MEGALITE'
string		MKS,		'MKS'
string		OPTLINK,	'OPTLINK'
string		PASSCOM,	'PASSCOM'
string		PKLITE,		'PKLITE'
string		PKTINY,		'PKTINY'
string		PGMPAK,		'PGMPAK'
string		POJCOM,		'POJCOM'
string		PROCOMP,	'PROCOMP'
string		PROTECT,	'PROTECT! EXE/COM'
string		PRO_PACK,	'PRO-PACK'
string		PAAI___PASSWORD,'PAAI - PASSWORD'
string		PACKEXE,	'PACKEXE'
string		PACKWIN,	'PACKWIN'
string		SCAN,		'SCAN'
string		SCRAMBLER,	'SCRAMBLER'
string		SCRNCH,		'SCRNCH'
string		SELF_DISINFECT, 'SELF-DISINFECTANT'
string		SHRINK,		'SHRINK'
string		SPACEMAKER,	'SPACEMAKER'
string		SUN_PROT	'SUN-PROT'
string		SYRINGE,	'SYRINGE'
string		TINYPROG,	'TINYPROG'
string		TPC_,		'TPC '
string		TURBO_,		'TURBO '
string		UCEXE,		'UCEXE'
string		UNTOUCHABLES,	'UNTOUCHABLES'
string		UNIT_173_,	'UNIT 173 '
string		USERNAME,	'USERNAME'
string		WWPACK,		'WWPACK'

vstring		_V0_1,		'0.1'
vstring		_V0_10,		'0.10'
vstring		_V0_13,		'0.13'
vstring		_V0_14,		'0.14'
vstring		_V0_15,		'0.15'
vstring		_V0_82		'0.82'
vstring		_V0_90		'0.90'
vstring		_V0_90b		'0.90�'
vstring		_V0_91		'0.91'
vstring		_V1,		'1'
vstring		_V1_0,		'1.0'
vstring		_V1_0a,		'1.0�'
vstring		_V1_00,		'1.00'
vstring		_V1_00a,	'1.00a'
vstring		_V1_00aF,	'1.00aF'
vstring		_V1_00B,	'1.00�'
vstring		_V1_00d,	'1.00d'
vstring		_V1_01,		'1.01'
vstring		_V1_02,		'1.02'
vstring		_V1_02b,	'1.02b'
vstring		_V1_02B,	'1.02�'
vstring		_V1_03,		'1.03'
vstring		_V1_05,		'1.05'
vstring		_V1_1,		'1.1'
vstring		_V1_10,		'1.10'
vstring		_V1_10a,	'1.10a'
vstring		_V1_12,		'1.12'
vstring		_V1_13,		'1.13'
vstring		_V1_14,		'1.14'
vstring		_V1_15,		'1.15'
vstring		_V1_16,		'1.16'
vstring		_V1_18a,	'1.18a'
vstring		_V1_2,		'1.2'
vstring		_V1_20,		'1.20'
vstring		_V1_20a,	'1.20a'
vstring		_V1_21,		'1.21'
vstring		_V1_3,		'1.3'
vstring		_V1_30,		'1.30'
vstring		_V1_4,		'1.4'
vstring		_V1_44,		'1.44'
vstring		_V1_45f,	'1.45f'
vstring		_V1_5,		'1.5'
vstring		_V1_50,		'1.50'
vstring		_V2_0,		'2.0'
vstring		_V2_00,		'2.00'
vstring		_V2_08,		'2.08'
vstring		_V2_1,		'2.1'
vstring		_V2_10,		'2.10'
vstring		_V2_14,		'2.14'
vstring		_V2_2,		'2.2'
vstring		_V2_3,		'2.3'
vstring		_V3_0,		'3.0'
vstring		_V3_00,		'3.00'
vstring		_V3_01,		'3.01'
vstring		_V3_02,		'3.02'
vstring		_V3_02a,	'3.02a'
vstring		_V3_1,		'3.1'
vstring		_V3_3,		'3.3'
vstring		_V3_6,		'3.6'
vstring		_V3_60,		'3.60'
vstring		_V3_64,		'3.64'
vstring		_V3_65,		'3.65'
vstring		_V3_69,		'3.69'
vstring		_V3_8,		'3.8'
vstring		_V3_9,		'3.9'
vstring		_V4_0,		'4.0'
vstring		_V4_00,		'4.00'
vstring		_V4_03,		'4.03'
vstring		_V4_05,		'4.05'
vstring		_V4_06,		'4.06'
vstring		_V4_4,		'4.4'
vstring		_V4_5,		'4.5'
vstring		_V5_0,		'5.0'
vstring		_V5_01_21,	'5.01.21'
vstring		_V7_02A,	'7.02A'
vstring		_V9_40,		'9.40'

string		_patched_with_,	' patched with '
string		_pass_1,	' pass 1'
string		_pass_2,	' pass 2'
string		_or,		' or'
string		_,		' '
string		C,		','
string		LB,		'['
string		RB,		']'
string		FwdS,		'/'

IFDEF DEBUG
string		__S_,		' <S>'
string		__L_,		' <L>'
string		__N_,		' <N>'
string		__SN_,		' <SN>'
string		__LN_,		' <LN>'
string		__SI_,		' <SI>'
string		__LI_,		' <LI>'
ELSE
string		__S_,		''
string		__L_,		''
string		__N_,		''
string		__SN_,		''
string		__LN_,		''
string		__SI_,		''
string		__LI_,		''
ENDIF

string	 	__m1, 		' -m1'
string		__m2,		' -m2'
string		__c,		' -c'
string		__e,		' -e'
string		__k,		' -k'
string		__v,		' -v'
string		_Alpha,		' Alpha'
string		__AV,		' /AV'
string		__AG,		' /AG'
string		__E,		' -E'
string		__G,		' -G'
string		__R,		' -R'
string		_P,		' P'
string		_PR,		' PR'
string		_RelocTxt,	' fixuptable'