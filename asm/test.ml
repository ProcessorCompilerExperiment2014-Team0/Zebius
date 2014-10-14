#load "asmSyntax.cmo";;
#load "asmParser.cmo";;
#load "asmLexer.cmo";;

open AsmSyntax
open AsmParser

let stt str =
  let lexbuf = Lexing.from_string str in
  let rec conv buf =
    match AsmLexer.token lexbuf with
        AsmParser.EOL -> []
      | t -> t::conv buf in
  conv lexbuf
  (* AsmLexer.token lexbuf *)
