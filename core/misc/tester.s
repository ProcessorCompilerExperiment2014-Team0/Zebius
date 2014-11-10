loop
	MOV #0, R0 ;; a
	MOV #0, R1 ;; i
	MOV #32, R2
begin1
	CMP/GT R1, R2
	BF cont1
	READ R3
	SHLD R1, R3 ;; read() << i
	ADD R3, R0
	ADD #8, R1
	BRA begin1
	AND R0, R0
cont1
	LDS R0, FPUL
	FSTS FPUL, FR0
	MOV #0, R0 ;; a
	MOV #0, R1 ;; i
begin2
	CMP/GT R1, R2
	BF cont2
	READ R3
	SHLD R1, R3
	ADD R3, R0
	ADD #8, R1
	BRA begin2
	AND R0, R0
cont2
	LDS R0, FPUL
	FSTS FPUL, FR1
	MOV #0, R0 ;; a
	MOV #0, R1 ;; i
begin3
	CMP/GT R1, R2
	BF cont3
	READ R3
	SHLD R1, R3
	ADD R3, R0
	ADD #8, R1
	BRA begin3
	AND R0, R0
cont3
	LDS R0, FPUL
	FSTS FPUL, FR2

;;; FR0=a, FR1=b, FR2=c
	FMOV FR0, FR3
	FDIV FR1, FR3 ;; d = a `op` b
	FCMP/EQ FR3, FR2
	BT ok
	;; not-equal, output a,b,c,d
	MOV.L iimm2, R5 ;; R5 = out_int
	BRA iend2
	AND R0, R0
iimm2
	.data.l out_int
iend2
	FLDS FR0, FPUL
	STS FPUL, R0
	JSR @R5
	AND R0, R0
	FLDS FR1, FPUL
	STS FPUL, R0
	JSR @R5
	AND R0, R0
	FLDS FR2, FPUL
	STS FPUL, R0
	JSR @R5
	AND R0, R0
	FLDS FR3, FPUL
	STS FPUL, R0
	JSR @R5
	AND R0, R0
ok
	BRA loop
	AND R0, R0
out_int ;; int -> unit
	MOV #4, R14
	MOV #0, R13
	MOV #-8, R12
oi_begin
	CMP/GT R13,R14
	BF oi_end
	WRITE R0
	SHLD R12, R0
	ADD #-1, R14
	BRA oi_begin
	AND R0, R0
oi_end
	RTS 
	AND R0, R0

