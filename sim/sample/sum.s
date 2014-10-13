        add 0,0,2
        not 0,4
        read 3
L1:
        add 3,2,2
        add 4,3,3
        cmp 3,0,5
        bgt 5,L1
        write 2
