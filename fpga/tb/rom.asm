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
    ld bc, #09ff ; divmmc = 1
    ld a, 1      ; ...
    out (c), a   ; ...
    ld bc, #03ff ; cpu freq = 7mhz
    ld a, 3      ; ...
    out (c), a   ; ...
    ld bc, #0000
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
