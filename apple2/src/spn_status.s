        .export     _spn_status

        .import     _spn_count
        .import     _spn_error
        .import     popa
        .import     pusha
        .import     spn_setup

        .include    "sp.inc"
        .include    "macros.inc"
        .include    "zp.inc"

; int8_t _spn_status(uint8_t dest, uint8_t statcode)
;
; call smart port for status using given code for given destination
; this changes _spn_payload, and _spn_count
; returns any error code from dispatch call
.proc _spn_status
        sta     tmp1                    ; store statcode until we need it
        popa    tmp2                    ; store dest, popa trashes y, so need to store it now instead of later

        pusha   #SP_CMD_STATUS
        lda     #SP_CONTROL_PARAM_COUNT
        
        jsr     spn_setup

        ; X/Y contains count (of bytes transferred), A contains error
        stx     _spn_count
        sty     _spn_count+1
        sta     _spn_error

        ldx     #$00
        lda     _spn_error              ; forces Z flag based on error value
        rts

.endproc
