.start
		MOV #1,R0 				;R0 is constant 1024
		MOV #10,R1
		SHLD R1,R0
		MOV #0,R1				;R1 is constant 0
		MOV #4,R2				;R2 is constant 4
		MOV #8,R3				;R3 is constant 8
		MOV R0,R4				;R4 is addr
		;; R5 is b
		MOV #0,R6				;R6 is l
		;; R7 is d
		MOV #0,R8;; R8 is i
		;; R9 is k
.read_length
		CMP/GT R8,R2
		BF .read_program
		READ R5
		SHLD R3,R6
		OR R5,R6
		ADD #1,R8
		BRA .read_length
.read_program
		CMP/GT R1,R6
		BF .run_program
		MOV #0,R8
		MOV #0,R7
		MOV #0,R9
.read_data
		CMP/GT R8,R2
		BF .store_data
		READ R5
		SHLD R9,R5
		OR R5,R7
		ADD #8,R9
		ADD #1,R8
		BRA .read_data
.store_data
		MOV.L R7,@R4
		ADD #4,R4
		ADD #-4,R6
		BRA .read_program
.run_program
		MOV.L .exit_code,R7
		MOV.L R7,@R4
		JMP @R0
		.align
.exit_code
		.data.l #45054 			;affe
