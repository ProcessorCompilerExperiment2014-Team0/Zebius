        FLDS FR0, FPUL
        STS FPUL, R0
        MOV.L exp_mask, R1
        MOV.L frac_mask, R2
        MOV.L sign_mask, R3
        AND R0, R1              ; exp
        AND R0, R2              ; frac
        AND R0, R3              ; sign
        MOV #0, R5
        CMP/EQ R2, R5
        BT frac0
        AND R0, R0              ; NOP
        
        MOV.L exp_253, R4
        SUB R1, R4              ; exp
        NOT R2, R2              ; frac
        MOV.L frac_mask, R1
        AND R1, R2
        OR R3, R4
        OR R2, R4
        LDS R4, FPUL
        FSTS FPUL, FR0
        LDS R0, FPUL
        FSTS FPUL, FR1
        FNEG FR1
        MOV #0, R0
        MOV #3, R1
        FLDI1 FR2
        FADD FR2, FR2           ; constant 2.0
newton_loop
        FMOV FR0, FR3
        FMUL FR1, FR3
        FADD FR2, FR3
        FMUL FR3, FR0
        ADD #-1, R1
        CMP/EQ R0, R1
        BF newton_loop
        AND R0, R0              ; NOP
        RTS
        AND R0, R0              ; NOP
frac0
        MOV.L exp_254, R4
        SUB R1, R4              ; exp
        OR R3, R4
        LDS R4, FPUL
        FSTS FPUL, FR0
        RTS
        AND R0, R0              ; NOP

        .align
exp_mask
        .data.l #H'7F800000
frac_mask
        .data.l #H'007FFFFF
sign_mask
        .data.l #H'80000000
exp_254
        .data.l #H'7F000000
exp_253
        .data.l #H'7E800000
