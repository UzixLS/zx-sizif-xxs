    DEVICE ZXSPECTRUM48

    ORG #8000 // mapped #0000
Start:
    nop
    jp #1000

    ORG #8038
Int1:
	reti

    ORG #8066
Nmi:
    retn

    ORG #9000
Main:
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

    jp #1fff
Loop:
    halt
    jr Loop


    ORG #C000 // mapped #0000
DivROM_Start:
    nop
    ld bc, #3D00
    push bc
    jp #1FFF
    ORG #DFFF // mapped #1FFF
    nop
    ORG #1D00 // mapped #3D00
    jp #0000


    SAVEBIN "rom.bin",0,65536
