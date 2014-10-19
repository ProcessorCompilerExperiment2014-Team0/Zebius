type arg =
  | A_Immd of int
  | A_R of int
  | A_At_R of int
  | A_FR of int
  | A_PC
  | A_FPUL
  | A_PR
  | A_Disp_PC of int
  | A_Label of string

type mnemonic =
  | M_MOV
  | M_MOV_L
  | M_STS
  | M_ADD
  | M_CMP_EQ
  | M_CMP_GT
  | M_SUB
  | M_AND
  | M_NOT
  | M_OR
  | M_XOR
  | M_SHLD
  | M_BF
  | M_BT
  | M_BRA
  | M_JMP
  | M_JSR
  | M_RTS
  | M_FLDI0
  | M_FLDI1
  | M_FMOV
  | M_FMOV_S
  | M_FADD
  | M_FCMP_EQ
  | M_FCMP_GT
  | M_FDIV
  | M_FMUL
  | M_FNEG
  | M_FSQRT
  | M_FSUB
  | M_LDS
  | M_FLDS
  | M_FSTS
  | M_FTRC
  | M_FLOAT
  | M_DATA_L
  | M_ALIGN


type inst = string option * mnemonic * arg list
