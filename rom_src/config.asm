POWERON_DELAY           EQU 40 ; *20ms, for ps/2 keyboard initialization

MENU_ENTER_DELAY        EQU 40 ; 400ms
MENU_LEAVE_DELAY        EQU 2  ; 20ms

INPUT_REPEAT            EQU 2
INPUT_REPEAT_FIRST      EQU 11
INPUT_BEEP_DELAY        EQU 255

MENU_HEADER_ATTR        EQU #47
MENU_BODY_ATTR          EQU #78
MENU_SELECT_ATTR        EQU #68

PAUSE_WIDTH             EQU 7
PAUSE_HEIGHT            EQU 3 ; see pause.asm to really change
PAUSE_X                 EQU (32-PAUSE_WIDTH)/2
PAUSE_Y                 EQU (24-PAUSE_HEIGHT)/2
PAUSE_BODY_ATTR         EQU #00
PAUSE_TEXT_ATTR         EQU #C7

    STRUCT CFG_T
_reserv0   DB 0
_reserv1   DB 0
machine    DB 3
clock      DB 0
panning    DB 1
_reserv2   DB 0
_reserv3   DB 0
joystick   DB 0
ay         DB 1
sd         DB 2
ulaplus    DB 1
dac        DB 3
sdind      DB 1
_reserv4   DB 0
autoturbo  DB 0
    ENDS

CFG_DEFAULT CFG_T
