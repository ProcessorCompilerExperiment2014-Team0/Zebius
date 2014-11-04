.start
    MOV #0,R0
    MOV #1,R1
    MOV #10,R2
    MOV #3,R3
    MOV #1,R4
    SHLD R2,R4
    MOV R4,R5
    NOT R0,R6
    MOV #0,R8
.loop
    READ R9
    ADD R9,R8
    CMP/EQ R3,R0
    BT .write
    SHLD R1,R8
    ADD #-1,R3
    BRA .loop
.write
    CMP/EQ R6,R9
    BT .run
    MOV.L R9,@R5
    ADD #4,R5
    MOV #3,R3
    BRA .loop
.run
    JMP @R4
