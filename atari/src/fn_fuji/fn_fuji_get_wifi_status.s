        .export         _fn_fuji_get_wifi_status
        .import         copy_fuji_cmd_data, _bus

        .include        "zp.inc"
        .include        "macros.inc"
        .include        "device.inc"

; int fn_fuji_get_wifi_status()
;
; Return values are:
;  1: No SSID available
;  3: Connection Successful
;  4: Connect Failed
;  5: Connection lost
.proc _fn_fuji_get_wifi_status
        setax   #t_io_get_wifi_status
        jsr     copy_fuji_cmd_data
        mwa     #tmp9, IO_DCB::dbuflo
        jsr     _bus

        ldx     #$00
        lda     tmp9
        rts
.endproc

.rodata
t_io_get_wifi_status:
        .byte $fa, $40, $01, $00, $00, $00