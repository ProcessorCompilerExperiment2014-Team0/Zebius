open AsmSyntax
open AsmParser
open AsmLexer

;;

let write ot tbl asm =
  List.iter (output_byte ot) (List.concat (List.map (Conv.encode tbl) asm))

let main () =
  if Array.length Sys.argv < 2 then
    print_endline "usage: zsim <input file>"
  else
    try
      let input = open_in Sys.argv.(1) in
      let lexbuf = Lexing.from_channel input in
      let asm = insts token lexbuf in
      let ofile = String.sub Sys.argv.(1) 0 (String.length Sys.argv.(1) - 2) in
      let output = open_out_bin ofile in
      let tbl = Hashtbl.create (List.length asm) in
      let asm' = Conv.align tbl 0 asm in
      write output tbl asm';
      List.iter (Conv.show stdout tbl) asm';
      close_in input; close_out output
    with
      | Sys_error e -> print_endline e
      | Parsing.Parse_error -> print_endline "Parse Error"
      | Failure s -> print_endline s
      | _ -> print_endline "Error"

;;
main ()
