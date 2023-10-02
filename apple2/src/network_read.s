        .export     _network_read

        .import     _bad_unit
        .import     _fn_error
        .import     _sp_network
        .import     _sp_payload
        .import     _sp_read
        .import     _memcpy
        .import     incsp2
        .import     incsp4
        .import     popax
        .import     pusha
        .import     pushax
        .import     return0

        .include    "fujinet-network.inc"
        .include    "macros.inc"
        .include    "sp.inc"
        .include    "zp.inc"

; network_read(char* devicespec, uint8_t *buf, uint16_t len);
;
.proc _network_read
        axinto  tmp7            ; len into tmp7/8
        ora     tmp8            ; check len > 0
        bne     :+

        ; remove the function args we didn't read from the stack, save the real error, and return bad command
        jsr     incsp4
        lda     #SP_ERR_BAD_CMD
        jmp     _fn_error

        ; check network id is set
:       lda     _sp_network     ; get network id
        bne     :+

        ; remove the function args we didn't read from the stack, save the real error, and return bad command
        jsr     incsp4
        jmp     _bad_unit

        ; check the buffer is not null
:       popax   tmp9            ; buffer location into tmp9/10
        ora     tmp10           ; it's 0 if both bytes are 0
        bne     skip_devicespec

        ; bad buffer, remove 2 bytes from stack and return bad command
        jsr     incsp2
        lda     #SP_ERR_BAD_CMD
        jmp     _fn_error

skip_devicespec:
        ; remove parameter from call stack
        jsr     incsp2

while_len:
        ; push network id into stack for call to sp_read
        pusha   _sp_network

        ; use the minimum of MAX_READ_SIZE (512) or len
        lda     tmp8            ; hi byte of len (tmp7/8)
        cmp     #$2             ; 512 high byte
        bcc     @len_under_512
        ; len >= 512, so cap at max value of 512
        lda     #$00
        sta     tmp5
        ldx     #$02
        stx     tmp6
        bne     :+              ; always

@len_under_512:
        lda     tmp7
        ldx     tmp8
        sta     tmp5
        stx     tmp6

        ; A/X hold bytes to transfer, also in tmp5/6 to decrease len afterwards
:       jsr     _sp_read
        bne     read_err

        ; copy tmp5/6 bytes into buffer from sp_payload
        pushax  tmp9            ; dst tmp9/10 (memcpy trashes ptr1-3)
        pushax  #_sp_payload    ; src
        setax   tmp5            ; length in tmp5/6 (either 512, or lower if len is less)
        jsr     _memcpy

        ; move the buffer pointer on by len
        adw     tmp9, tmp5      ; tmp9/10 increased by tmp5/6

        ; decrease len by amount transferred
        sbw     tmp7, tmp5      ; tmp7/8 decreased by tmp5/6

        ; have we finished?
        lda     tmp7
        ora     tmp8
        bne     while_len

        ; no more data, no errors reported, return OK
        jmp     return0         ; FN_ERR_OK

read_err:
        ; convert device error to library error and return
        jmp     _fn_error

.endproc