open AsmSyntax
open AsmParser
open AsmLexer
open Conv

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
      let asm' = align tbl 0 asm in
      try
        write output tbl asm';
        List.iter (show stdout tbl) asm'
      with
        | Unknown_instruction (l,p,m,a) -> print_endline "Unknown instruction:";
          show_error stdout tbl (l,p,m,a)
        | Immd_out_of_bounds (l,p,m,a) -> print_endline "Immediate out of bounds:";
          show_error stdout tbl (l,p,m,a);
      close_in input; close_out output
    with
      | Sys_error e -> print_endline e
      | Parsing.Parse_error -> print_endline "Parse Error"
      | Failure s -> print_endline s

;;
main ()
