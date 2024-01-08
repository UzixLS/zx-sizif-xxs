    DEVICE ZXSPECTRUM48

    ORG #0000
Start:
    nop
    jp Main

    ORG #0038
Int1:
	reti

    ORG #0066
Nmi:
    retn

    ORG #1000
Main:
    jp #3D00

    im 2
    ei

    ld bc, #7ffd
    ld a, #83
    .200 out (c), a

    //.72 nop
    //ld a, 7
    //out (#fe), a

    //ld hl, #4000
    //ld de, #c000
    //ld bc, 100
    //ldir

    //ld c, #ff
    //ld b, #ff
    //ld hl, #4000
    //otir
Loop:
    halt
    jr Loop


    ORG #8000 // mapped #0000
MagicROM_Start:
    ld sp, #8000
    ld bc, #09ff ; divmmc = 1
    ld a, 1      ; ...
    out (c), a   ; ...
    ld bc, #02ff ; machine = 128
    ld a, 1      ; ...
    out (c), a   ; ...
    ld bc, #03ff ; cpu freq = 14mhz
    ld a, 4      ; ...
    out (c), a   ; ...
    .100 in a, (#fe)
    ld bc, #0000
    ld de, #5000
    ld hl, #6000
    ldir
    push bc
    jp #f008
    ORG #F000
MagicROM_ExitVector:
    ret
    ORG #F008
MagicROM_ReadoutVector:
    nop
    ret

    ORG #A000 // mapped #0000
DivROM_Start:
    nop
    ld bc, #1000
    push bc
    jp #1FFF
    ORG #BFFF // mapped #1FFF
DivROM_ExitVector:
    ret
    ORG #1D00 // mapped #3D00
DivROM_EnterVector_TRDOS:
    ld bc, #1000
    push bc
    jp #1FFF


    SAVEBIN "rom.bin",0,65536
