%{
  open AsmSyntax
%}

%token <int> R AT_R FR IMMD DISP_PC
%token <string> LABEL
%token WRITE READ MOV MOV_L STS ADD CMP_EQ CMP_GT SUB AND NOT OR XOR SHLD BF BT BRA JMP JSR RTS FLDI0 FLDI1 FMOV FMOV_S FADD FCMP_EQ FCMP_GT FDIV FMUL FNEG FSQRT FSUB LDS FLDS FSTS FTRC FLOAT DATA_L ALIGN PC FPUL PR
%token COMMA
%token EOL
%token EOF


%start insts
%type <AsmSyntax.inst list> insts

%%

insts:
| eols inst eols insts {$2::$4}
| inst eols insts {$1::$3}
| EOF {[]}
;

inst:
| mn args {(None,$1,$2)}
| LABEL mn args {(Some $1,$2,$3)}
| LABEL eols mn args {(Some $1,$3,$4)}
;

mn:
| WRITE {M_WRITE}
| READ {M_READ}
| MOV {M_MOV}
| MOV_L {M_MOV_L}
| STS {M_STS}
| ADD {M_ADD}
| CMP_EQ {M_CMP_EQ}
| CMP_GT {M_CMP_GT}
| SUB {M_SUB}
| AND {M_AND}
| NOT {M_NOT}
| OR {M_OR}
| XOR {M_XOR}
| SHLD {M_SHLD}
| BF {M_BF}
| BT {M_BT}
| BRA {M_BRA}
| JMP {M_JMP}
| JSR {M_JSR}
| RTS {M_RTS}
| FLDI0 {M_FLDI0}
| FLDI1 {M_FLDI1}
| FMOV {M_FMOV}
| FMOV_S {M_FMOV_S}
| FADD {M_FADD}
| FCMP_EQ {M_FCMP_EQ}
| FCMP_GT {M_FCMP_GT}
| FDIV {M_FDIV}
| FMUL {M_FMUL}
| FNEG {M_FNEG}
| FSQRT {M_FSQRT}
| FSUB {M_FSUB}
| LDS {M_LDS}
| FLDS {M_FLDS}
| FSTS {M_FSTS}
| FTRC {M_FTRC}
| FLOAT {M_FLOAT}
| DATA_L {M_DATA_L}
| ALIGN {M_ALIGN}
;

args:
| args1 {$1}
| {[]}
;

args1:
| arg {[$1]}
| arg COMMA args1 {$1::$3}
;

arg:
| IMMD {A_Immd $1}
| FR {A_FR $1}
| AT_R {A_At_R $1}
| R {A_R $1}
| PC {A_PC}
| FPUL {A_FPUL}
| PR {A_PR}
| DISP_PC {A_Disp_PC $1}
| LABEL {A_Label $1}
;

eols:
| EOL {()}
| EOL eols {()}
;
