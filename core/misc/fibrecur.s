.start
	MOV #1, R15
    MOV #15, R14
    SHLD R14, R15
    MOV #12, R0
    MOV.L   .call_addr.24, R14
    JSR @R14
    AND R0, R0
    BRA .call_endp.25
    AND R0, R0
    .align
.call_addr.24
    .data.l fib.10
.call_endp.25
    MOV.L   .call_addr.26, R14
    JSR @R14
    AND R0, R0
    BRA .call_endp.27
    AND R0, R0
    .align
.call_addr.26
    .data.l min_caml_print_int
.call_endp.27
    BRA .end
fib.10
    STS PR, R14
    MOV.L   R14, @R15
    ADD #4, R15
    MOV #1, R14
    CMP/GT  R14, R0
    BT  .JLE_else.28
    ADD #-4, R15
    MOV.L   @R15, R14
    JMP @R14
    AND R0, R0
.JLE_else.28
    MOV R0, R1
    ADD #-1, R1
    MOV.L   R0, @R15
    MOV R1, R0
    ADD #8, R15
    MOV.L   .call_addr.29, R14
    JSR @R14
    AND R0, R0
    BRA .call_endp.30
    AND R0, R0
    .align
.call_addr.29
    .data.l fib.10
.call_endp.30
    ADD #-8, R15
    MOV.L   @R15, R1
    ADD #-2, R1
    ADD #4, R15
    MOV.L   R0, @R15
    ADD #-4, R15
    MOV R1, R0
    ADD #8, R15
    MOV.L   .call_addr.31, R14
    JSR @R14
    AND R0, R0
    BRA .call_endp.32
    AND R0, R0
    .align
.call_addr.31
    .data.l fib.10
.call_endp.32
    ADD #-8, R15
    ADD #4, R15
    MOV.L   @R15, R1
    ADD #-4, R15
    ADD R1, R0
    ADD #-4, R15
    MOV.L   @R15, R14
    JMP @R14
    AND R0, R0
min_caml_print_int
    RTS
    AND R0, R0
.align
min_caml_hp
    .data.l #65536
.end
	WRITE R0
	BRA .start
