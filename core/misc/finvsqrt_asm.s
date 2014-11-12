        FLDS FR0, FPUL
        STS FPUL, R0

        MOV.L sqrt_exp_mask, R3
        AND R0, R3              ; exp without LSB
        MOV #-1, R1
        SHLD R1, R3

        MOV.L sqrt_frac_mask, R4
        AND R0, R4              ; frac
        SHLD R1, R4

        MOV.L sqrt_exp_189, R5
        MOV #1, R6
        MOV #23, R1
        SHLD R1, R6             ; 1<<23
        ADD #-1, R6

        MOV #1, R1
        MOV #23, R2
        SHLD R2, R1
        AND R0, R1              ; LSB of exp
        MOV #0, R2
        CMP/EQ R1, R2
        BF sqrt_exp_odd
        AND R0, R0

        ;; exp is even
        MOV.L sqrt_exp_190, R5
        MOV #-1, R1
        SHLD R1, R6

sqrt_exp_odd
        SUB R3, R5

        SUB R4, R6
        OR R6, R5               ; init value

        FMOV FR0, FR1
        FNEG FR1                ; -A
        LDS R5, FPUL
        FSTS FPUL, FR0          ; init value

        MOV.L sqrt_const_half, R2
        LDS R2, FPUL
        FSTS FPUL, FR2
        MOV.L sqrt_const_3, R3
        LDS R3, FPUL
        FSTS FPUL, FR3
        MOV #4, R1
        MOV #0, R0
sqrt_newton_loop
        FMOV FR0, FR4           ; x
        FMUL FR0, FR4           ; x^2
        FMUL FR1, FR4           ; -Ax^2
        FADD FR3, FR4           ; 3-Ax^2
        FMUL FR4, FR0           ; x(3-Ax^2)
        FMUL FR2, FR0           ; next x
        ADD #-1, R1
        CMP/EQ R0, R1
        BF sqrt_newton_loop
        AND R0, R0              ; NOP
        RTS
        AND R0, R0              ; NOP

        .align
sqrt_exp_mask
        .data.l #H'7F000000
sqrt_frac_mask
        .data.l #H'007FFFFF
sqrt_exp_189
        .data.l #H'5E800000
sqrt_exp_190
        .data.l #H'5F000000
sqrt_const_half
        .data.l #H'3F000000
sqrt_const_3
        .data.l #H'40400000
