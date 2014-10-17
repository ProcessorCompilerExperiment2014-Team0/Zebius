        MOV.L immd,R0
        BRA end
immd    .data.l #H'1234ABCD
end     MOV R0,R0
