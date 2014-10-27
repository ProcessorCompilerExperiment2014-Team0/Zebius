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
      try
        let asm' = align tbl 0 asm in
        write output tbl asm';
        if Array.length Sys.argv > 2 && Sys.argv.(2) = "-v"
        then List.iter (show_vhdl stdout tbl) asm'
        else List.iter (show stdout tbl) asm'
      with
        | Unbound_label (l,p,m,a) -> print_endline "Unbound label:";
          show_error stdout tbl (l,p,m,a)
        | Duplicative_label (l,p,m,a) -> print_endline "Duplicative label:";
          show_error stdout tbl (l,p,m,a)
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
