open AsmSyntax
open AsmParser
open AsmLexer

;;

let rec align tbl n = function
  | [] -> []
  | (lbl,m,args)::is ->
    let _ = match lbl with
      | None -> ()
      | Some l -> Hashtbl.add tbl l n in
    (n,m,args)::align tbl (n+1) is

let put_int1 ot a =
  let l = [a land 0xFF;
           (a lsr 8) land 0xFF] in
  List.iter (output_byte ot) l

let put_int2 ot a b =
  let l = [b land 0xFF;
           ((a land 0xF) lsl 4) lor ((b lsr 8) land 0xF)] in
  List.iter (output_byte ot) l

let put_int3 ot a b c =
  let l = [c land 0xFF;
           ((a land 0xF) lsl 4) lor (b land 0xF)] in
  List.iter (output_byte ot) l

let put_int4 ot a b c d =
  let l = [((c land 0xF) lsl 4) lor (d land 0xF);
           ((a land 0xF) lsl 4) lor (b land 0xF)] in
  List.iter (output_byte ot) l

let get_disp tbl src lbl =
  let dst = Hashtbl.find tbl lbl in
  dst - src - 2

let rec write ot tbl = function
  | [] -> ()
  | (place,mn,args)::is ->
    let _ = match (mn,args) with
      | (M_MOV, [A_Immd i; A_R n]) -> put_int3 ot 0xE n i
      | (M_MOV_L, [A_Disp_PC d; A_R n]) -> put_int3 ot 0x9 n d
      | (M_MOV, [A_R m; A_R n]) -> put_int4 ot 0x6 n m 0x3
      | (M_MOV_L, [A_R m; A_At_R n]) -> put_int4 ot 0x2 n m 0x2
      | (M_MOV_L, [A_At_R m; A_R n]) -> put_int4 ot 0x3 n m 0x2
      | (M_STS, [A_PR; A_R n]) -> put_int3 ot 0x0 n 0x2A
      | (M_ADD, [A_R m; A_R n]) -> put_int4 ot 0x3 n m 0xC
      | (M_ADD, [A_Immd i; A_R n]) -> put_int3 ot 0x7 n i
      | (M_CMP_EQ, [A_R m; A_R n]) -> put_int4 ot 0x3 n m 0x0
      | (M_CMP_GT, [A_R m; A_R n]) -> put_int4 ot 0x3 n m 0x7
      | (M_SUB, [A_R m; A_R n]) -> put_int4 ot 0x3 n m 0x8
      | (M_AND, [A_R m; A_R n]) -> put_int4 ot 0x2 n m 0x9
      | (M_NOT, [A_R m; A_R n]) -> put_int4 ot 0x6 n m 0x7
      | (M_OR, [A_R m; A_R n]) -> put_int4 ot 0x2 n m 0xB
      | (M_XOR, [A_R m; A_R n]) -> put_int4 ot 0x2 n m 0xA
      | (M_SHLD, [A_R m; A_R n]) -> put_int4 ot 0x4 n m 0xD
      | (M_BF, [A_Label l]) -> put_int3 ot 0x8 0xB (get_disp tbl place l)
      | (M_BT, [A_Label l]) -> put_int3 ot 0x8 0x9 (get_disp tbl place l)
      | (M_BRA, [A_Label l]) -> put_int2 ot 0xA (get_disp tbl place l)
      | (M_JMP, [A_At_R n]) -> put_int3 ot 0x4 n 0x2B
      | (M_JSR, [A_At_R n]) -> put_int3 ot 0x4 n 0x0B
      | (M_RTS, []) -> put_int1 ot 0x000B
      | (M_FLDI0, [A_FR n]) -> put_int3 ot 0xF n 0x8D
      | (M_FLDI1, [A_FR n]) -> put_int3 ot 0xF n 0x9D
      | (M_FMOV, [A_FR m; A_FR n]) -> put_int4 ot 0xF n m 0xC
      | (M_FMOV_S, [A_At_R m; A_FR n]) -> put_int4 ot 0xF n m 0x8
      | (M_FMOV_S, [A_FR m; A_At_R n]) -> put_int4 ot 0xF n m 0xA
      | (M_FADD, [A_FR m; A_FR n]) -> put_int4 ot 0xF n m 0x0
      | (M_FCMP_EQ, [A_FR m; A_FR n]) -> put_int4 ot 0xF n m 0x4
      | (M_FCMP_GT, [A_FR m; A_FR n]) -> put_int4 ot 0xF n m 0x5
      | (M_FDIV, [A_FR m; A_FR n]) -> put_int4 ot 0xF n m 0x3
      | (M_FMUL, [A_FR m; A_FR n]) -> put_int4 ot 0xF n m 0x2
      | (M_FNEG, [A_FR n]) -> put_int3 ot 0xF n 0x4D
      | (M_FSQRT, [A_FR n]) -> put_int3 ot 0xF n 0x6D
      | (M_FSUB, [A_FR m; A_FR n]) -> put_int4 ot 0xF n m 0x1
      | (M_LDS, [A_R m; A_FPUL]) -> put_int3 ot 0x4 m 0x5A
      | (M_STS, [A_FPUL; A_R n]) -> put_int3 ot 0x0 n 0x5A
      | (M_FLDS, [A_FR m; A_FPUL]) -> put_int3 ot 0xF m 0x1D
      | (M_FSTS, [A_FPUL; A_FR n]) -> put_int3 ot 0xF n 0x0D
      | (M_FTRC, [A_FR m; A_FPUL]) -> put_int3 ot 0xF m 0x3D
      | (M_FLOAT, [A_FPUL; A_FR n]) -> put_int3 ot 0xF n 0x2D
      | _ -> print_endline "Unknown instruction" in
    write ot tbl is

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
      write output tbl asm';
      close_in input; close_out output
    with
      | Sys_error e -> print_endline e
      | Parsing.Parse_error -> print_endline "Parse Error"
      | Failure s -> print_endline s
      | _ -> print_endline "Error"

;;
main ()
