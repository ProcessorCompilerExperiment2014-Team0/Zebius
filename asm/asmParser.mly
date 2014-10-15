%{
  open AsmSyntax
%}

%token <int> R AT_R FR IMMD DISP_PC
%token <string> LABEL
%token MOV MOV_L STS ADD CMP_EQ CMP_GT SUB AND NOT OR XOR SHLD BF BT BRA JMP JSR RTS FLDI0 FLDI1 FMOV FMOV_S FADD FCMP_EQ FCMP_GT FDIV FMUL FNEG FSQRT FSUB LDS FLDS FSTS FTRC FLOAT PC FPUL PR
%token COMMA
%token EOL
%token EOF


%start main
%type <AsmSyntax.inst list> main

%%

main:
| inst EOL main {$1::$3}
| {[]}
;

inst:
| mn args {($1,$2)}
;

mn:
| {M_ADD}

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
| LABEL {A_Label $1}
| DISP_PC {A_Disp_PC $1}
;
