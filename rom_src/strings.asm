    MACRO DEFSTR _string
    DB _string,0
@.end:
    ENDM
    DB 0

str_sizif:             DEFSTR "SIZIF-XXS"
str_pause:             DEFSTR " PAUSE "
str_exit:              DEFSTR "Exit"
str_exit_reboot:       DEFSTR "& reboot     "
str_exit_no_reboot:    DEFSTR "             "
str_on:                DEFSTR "   ON"
str_off:               DEFSTR "      OFF"
str_on_short:          DEFSTR " ON"
str_off_short:         DEFSTR "OFF"
str_machine:           DEFSTR "Machine"
str_machine_48:        DEFSTR "      48"
str_machine_128:       DEFSTR "     128"
str_machine_3e:        DEFSTR "     +3e"
str_machine_pentagon:  DEFSTR "Pentagon"
str_cpu:               DEFSTR "CPU freq"
str_cpu_35:            DEFSTR "3.5MHz"
str_cpu_44:            DEFSTR "4.4MHz"
str_cpu_52:            DEFSTR "5.2MHz"
str_cpu_7:             DEFSTR "  7MHz"
str_cpu_14:            DEFSTR " 14MHz"
str_panning:           DEFSTR "Panning"
str_panning_abc:       DEFSTR " ABC"
str_panning_acb:       DEFSTR " ACB"
str_panning_mono:      DEFSTR "Mono"
str_joystick:          DEFSTR "Joystick"
str_joystick_kempston: DEFSTR "Kempston"
str_joystick_sinclair: DEFSTR "Sinclair"
str_sd:                DEFSTR "SD card"
str_divmmc:            DEFSTR "DivMMC"
str_zc3e:              DEFSTR "ZC/+3e"
str_ulaplus:           DEFSTR "ULA+"
str_dac:               DEFSTR "DAC"
str_dac_covox:         DEFSTR "   Covox"
str_dac_sd:            DEFSTR "      SD"
str_dac_covoxsd:       DEFSTR "Covox+SD"
str_menuadv:           DEFSTR "Advanced..."
str_sd_indication:     DEFSTR "SD indication"
str_back:              DEFSTR "Go back..."
