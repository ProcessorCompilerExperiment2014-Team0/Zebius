{
  open AsmSyntax
  open AsmParser
  open String
  let suffix s n =
    sub s n (length s - n)
}

let space = ' ' | '\t'
let digit = ['0'-'9']
let hdigit = ['0'-'9' 'A'-'F' 'a'-'f']
let num = '-'?digit+
let hnum = "H'"hdigit+
let alpha = ['a'-'z' 'A'-'Z' '_' '.']
let ident = alpha (alpha | digit)*

rule token = parse
  | space+ {token lexbuf}
  | "WRITE" {WRITE}
  | "READ" {READ}
  | "MOV" {MOV}
  | "MOV.L" {MOV_L}
  | "STS" {STS}
  | "ADD" {ADD}
  | "CMP/EQ" {CMP_EQ}
  | "CMP/GT" {CMP_GT}
  | "SUB" {SUB}
  | "AND" {AND}
  | "NOT" {NOT}
  | "OR" {OR}
  | "XOR" {XOR}
  | "SHLD" {SHLD}
  | "BF" {BF}
  | "BT" {BT}
  | "BRA" {BRA}
  | "JMP" {JMP}
  | "JSR" {JSR}
  | "RTS" {RTS}
  | "FLDI0" {FLDI0}
  | "FLDI1" {FLDI1}
  | "FMOV" {FMOV}
  | "FMOV.S" {FMOV_S}
  | "FADD" {FADD}
  | "FCMP/EQ" {FCMP_EQ}
  | "FCMP/GT" {FCMP_GT}
  | "FDIV" {FDIV}
  | "FMUL" {FMUL}
  | "FNEG" {FNEG}
  | "FSQRT" {FSQRT}
  | "FSUB" {FSUB}
  | "LDS" {LDS}
  | "FLDS" {FLDS}
  | "FSTS" {FSTS}
  | "FTRC" {FTRC}
  | "FLOAT" {FLOAT}
  | "PC" {PC}
  | "FPUL" {FPUL}
  | "PR" {PR}
  | ".data.l" {DATA_L}
  | ".align" {ALIGN}
  | "@(" digit+ "*,PC)" as s {DISP_PC (int_of_string (sub s 2 (length s - index s '*' - 4)))}
  | ',' {COMMA}
  | ';'[^'\n']* {token lexbuf}
  | '#' num as s {IMMD_D (int_of_string (suffix s 1))}
  | '#' hnum as s {IMMD_H (int_of_string ("0x" ^ (suffix s 3)))}
  | "FR" digit+ as s {FR (int_of_string (suffix s 2))}
  | "@R" digit+ as s {AT_R (int_of_string (suffix s 2))}
  | 'R' digit+ as s {R (int_of_string (suffix s 1))}
  | '\n' {EOL}
  | eof {EOF}
  | ident as s {LABEL s}
  | _ {failwith ("unknown token: " ^ Lexing.lexeme lexbuf)}
