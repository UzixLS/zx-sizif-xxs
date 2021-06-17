MENU_ENTER_DELAY        EQU 40 ; 400ms
MENU_LEAVE_DELAY        EQU 2  ; 20ms
MENU_HOLDCHECK_DELAY    EQU 7

MENU_WIDTH              EQU 20
MENU_HEIGHT             EQU MENU_ITEMS+2

MENU_HEADER_ATTR        EQU #47
MENU_BODY_ATTR          EQU #78
MENU_SELECT_ATTR        EQU #68

INPUT_REPEAT            EQU 2
INPUT_REPEAT_FIRST      EQU 11
INPUT_BEEP_DELAY        EQU 255


    STRUCT CFG_T
_reserv0 DB 0
_reserv1 DB 0
timings  DB 0
clock    DB 0
panning  DB 1
plus3    DB 0
rom48    DB 0
joystick DB 0
ram      DB 0
divmmc   DB 1
    ENDS

CFG_DEFAULT CFG_T
