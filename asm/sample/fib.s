        MOV #10,R0
        MOV #0,R1
        MOV #1,R2
        MOV #1,R3
.loop   MOV R2,R4
        MOV R3,R2
        ADD R4,R3
        ADD #-1,R0
        CMP/EQ R0,R1
        BF .loop
