    STRUCT MENU_T
addr DW
items DB
height DB
y_row DB
y_pixel DB
width DB
x DB
x_logo DB
    ENDS

    STRUCT MENUENTRY_T
text_addr DW
value_cb_addr DW
callback DW
reserved DW
    ENDS

    MACRO MENU_DEF width
        MENU_T {
            ($+MENU_T)
            (((.end-$)/MENUENTRY_T-1))
            (((.end-$)/MENUENTRY_T-1)+2)
            ( (24-(((.end-$)/MENUENTRY_T-1)+2))/2)
            (((24-(((.end-$)/MENUENTRY_T-1)+2))/2)*8)
            (width)
            ( (32-width)/2)
            (((32-width)/2)+width-6)
        }
    ENDM

menudefault: MENU_DEF 20
    MENUENTRY_T str_cpu         menu_clock_value_cb       menu_clock_cb
    MENUENTRY_T str_machine     menu_machine_value_cb     menu_machine_cb
    MENUENTRY_T str_panning     menu_panning_value_cb     menu_panning_cb
    MENUENTRY_T str_joystick    menu_joystick_value_cb    menu_joystick_cb
    MENUENTRY_T str_sd          menu_sd_value_cb          menu_sd_cb
    MENUENTRY_T str_ulaplus     menu_ulaplus_value_cb     menu_ulaplus_cb
    MENUENTRY_T str_dac         menu_dac_value_cb         menu_dac_cb
    MENUENTRY_T str_exit        menu_exit_value_cb        menu_exit_cb
    MENUENTRY_T 0
.end:



menu_machine_value_cb:
    ld ix, .values_table
    ld a, (cfg.machine)
    jp menu_value_get
.values_table:
    DW str_machine_48_end-2
    DW str_machine_128_end-2
    DW str_machine_3e_end-2
    DW str_machine_pentagon_end-2

menu_clock_value_cb:
    ld ix, .values_table
    ld a, (cfg.clock)
    jp menu_value_get
.values_table:
    DW str_cpu_35_end-2
    DW str_cpu_44_end-2
    DW str_cpu_52_end-2
    DW str_cpu_7_end-2
    DW str_cpu_14_end-2

menu_panning_value_cb:
    ld ix, .values_table
    ld a, (cfg.panning)
    jp menu_value_get
.values_table:
    DW str_panning_mono_end-2
    DW str_panning_abc_end-2
    DW str_panning_acb_end-2

menu_joystick_value_cb:
    ld ix, .values_table
    ld a, (cfg.joystick)
    jp menu_value_get
.values_table:
    DW str_joystick_kempston_end-2
    DW str_joystick_sinclair_end-2

menu_sd_value_cb:
    ld ix, .values_table
    ld a, (cfg.sd)
    jp menu_value_get
.values_table:
    DW str_off_end-2
    DW str_divmmc_end-2
    DW str_zc3e_end-2

menu_ulaplus_value_cb:
    ld ix, .values_table
    ld a, (cfg.ulaplus)
    jp menu_value_get
.values_table:
    DW str_off_end-2
    DW str_on_end-2

menu_dac_value_cb:
    ld ix, .values_table
    ld a, (cfg.dac)
    jp menu_value_get
.values_table:
    DW str_off_end-2
    DW str_dac_covox_end-2
    DW str_dac_sd_end-2
    DW str_dac_covoxsd_end-2

menu_exit_value_cb:
    ld ix, .values_table
    ld a, (var_exit_reboot)
    jp menu_value_get
.values_table:
    DW str_exit_no_reboot_end-2
    DW str_exit_reboot_end-2

menu_value_get:
    sla a
    ld c, a
    ld b, 0
    add ix, bc
    ld l, (ix+0)
    ld h, (ix+1)
    ret



menu_machine_cb:
    ld a, (cfg.machine)
    ld c, 3
    call menu_handle_press
    ld (cfg.machine), a
    ld bc, #02ff
    out (c), a
    ret

menu_clock_cb:
    ld a, (cfg.clock)
    ld c, 4
    call menu_handle_press
    ld (cfg.clock), a
    ld bc, #03ff
    out (c), a
    ret

menu_panning_cb:
    ld a, (cfg.panning)
    ld c, 2
    call menu_handle_press
    ld (cfg.panning), a
    ld bc, #04ff
    out (c), a
    ret

menu_joystick_cb:
    ld a, (cfg.joystick)
    ld c, 1
    call menu_handle_press
    ld (cfg.joystick), a
    ld bc, #07ff
    out (c), a
    ret

menu_sd_cb:
    ld a, (cfg.sd)
    ld c, 2
    call menu_handle_press
    ld (cfg.sd), a
    ld bc, #09ff
    out (c), a
    ret

menu_ulaplus_cb:
    ld a, (cfg.ulaplus)
    ld c, 1
    call menu_handle_press
    ld (cfg.ulaplus), a
    ld bc, #0aff
    out (c), a
    ret

menu_dac_cb:
    ld a, (cfg.dac)
    ld c, 3
    call menu_handle_press
    ld (cfg.dac), a
    ld bc, #0bff
    out (c), a
    ret

menu_exit_cb:
    bit 4, d                ; action?
    jr nz, .exit
    ld a, (var_exit_reboot)
    ld c, 1
    call menu_handle_press
    ld (var_exit_reboot), a
    ret
.exit
    ld a, 1
    ld (var_exit_flag), a
    ret


; IN  -  A - variable to change
; IN  -  C - max value
; IN  -  D - pressed key
; OUT -  A - new variable value
menu_handle_press:
    bit 4, d                ; action?
    jr nz, .increment
    bit 0, d                ; right?
    jr nz, .increment
    bit 1, d                ; left?
    jr nz, .decrement
    ret
.increment:
    cp c                    ; if (value >= max) value = 0
    jr nc, .increment_roll  ; ...
    inc a                   ; else value++
    ret
.increment_roll:
    xor a                   ; value = 0
    ret
.decrement:
    or a                    ; if (value == 0) value = max
    jr z, .decrement_roll   ; ...
    dec a                   ; else value--
    ret
.decrement_roll:
    ld a, c                 ; value = max
    ret
