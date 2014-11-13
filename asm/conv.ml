open AsmSyntax
open Printf

exception Unbound_label of string list * int * mnemonic * arg list
exception Duplicative_label of string list * int * mnemonic * arg list
exception Unknown_instruction of string list * int * mnemonic * arg list
exception Immd_out_of_bounds of string list * int * mnemonic * arg list

let string_of_label = function
  | [] -> ""
  | ls ->
    let rec go = function
      | [] -> ""
      | [l] -> l
      | l::ls -> l ^ ", " ^ go ls in
    "    ;; " ^ go ls

let string_of_mn = function
  | M_WRITE   -> "WRITE  "
  | M_READ    -> "READ   "
  | M_MOV     -> "MOV    "
  | M_MOV_L   -> "MOV.L  "
  | M_STS     -> "STS    "
  | M_ADD     -> "ADD    "
  | M_CMP_EQ  -> "CMP/EQ "
  | M_CMP_GT  -> "CMP/GT "
  | M_SUB     -> "SUB    "
  | M_AND     -> "AND    "
  | M_NOT     -> "NOT    "
  | M_OR      -> "OR     "
  | M_XOR     -> "XOR    "
  | M_SHLD    -> "SHLD   "
  | M_BF      -> "BF     "
  | M_BT      -> "BT     "
  | M_BRA     -> "BRA    "
  | M_JMP     -> "JMP    "
  | M_JSR     -> "JSR    "
  | M_RTS     -> "RTS    "
  | M_FLDI0   -> "FLDI0  "
  | M_FLDI1   -> "FLDI1  "
  | M_FMOV    -> "FMOV   "
  | M_FMOV_S  -> "FMOV.S "
  | M_FADD    -> "FADD   "
  | M_FCMP_EQ -> "FCMP/EQ"
  | M_FCMP_GT -> "FCMP/GT"
  | M_FDIV    -> "FDIV   "
  | M_FMUL    -> "FMUL   "
  | M_FNEG    -> "FNEG   "
  | M_FSQRT   -> "FSQRT  "
  | M_FSUB    -> "FSUB   "
  | M_LDS     -> "LDS    "
  | M_FLDS    -> "FLDS   "
  | M_FSTS    -> "FSTS   "
  | M_FTRC    -> "FTRC   "
  | M_FLOAT   -> "FLOAT  "
  | M_DATA_L  -> ".data.l"
  | M_ALIGN   -> ".align "

let string_of_arg tbl = function
  | A_Immd (I_Dec i) -> "#"^string_of_int i
  | A_Immd (I_Hex i) -> sprintf "#H'%X" i
  | A_R n -> "R"^string_of_int n
  | A_At_R n -> "@R"^string_of_int n
  | A_FR n -> "FR"^string_of_int n
  | A_PC -> "PC"
  | A_FPUL -> "FPUL"
  | A_PR -> "PR"
  | A_Disp_PC n -> "@("^string_of_int n^",PC)"
  | A_Label s -> s

let rec string_of_args tbl = function
  | [] -> ""
  | [a] -> string_of_arg tbl a
  | a::aa -> string_of_arg tbl a ^ ", " ^ string_of_args tbl aa

let check_signed len n =
  if -1 lsl (len-1) <= n && n < 1 lsl (len-1)
  then ((1 lsl len) - 1) land n
  else failwith "Immd out of bounds"

let check_unsigned len n =
  if 0 <= n && n < 1 lsl len
  then n
  else failwith "Immd out of bounds"

let check_immd len sign = function
  | I_Dec n ->
    if sign
    then check_signed len n
    else check_unsigned len n
  | I_Hex n -> check_unsigned len n

let rec align res tbl n = function
  | [] ->
    if n mod 2 = 0 then res
    else ([],n,M_AND,[A_R 0; A_R 0])::res
  | (lbl,m,args)::is ->
    List.iter
      (fun l -> if Hashtbl.mem tbl l
        then raise (Duplicative_label ([l],n,m,args))
        else Hashtbl.add tbl l n) lbl;
    match m with
    | M_ALIGN ->
      if (n land 1) = 0 then align res tbl n is
      else align ((lbl,n,M_AND,[A_R 0; A_R 0])::res) tbl (n+1) is
    | M_DATA_L -> align ((lbl,n,m,args)::res) tbl (n+2) is
    | _ -> align ((lbl,n,m,args)::res) tbl (n+1) is

let enc_int1 a =
  [a land 0xFF;
   (a lsr 8) land 0xFF]

let enc_int2 a b =
  [b land 0xFF;
   ((a land 0xF) lsl 4) lor ((b lsr 8) land 0xF)]

let enc_int3 a b c =
  [c land 0xFF;
   ((a land 0xF) lsl 4) lor (b land 0xF)]

let enc_int4 a b c d =
  [((c land 0xF) lsl 4) lor (d land 0xF);
   ((a land 0xF) lsl 4) lor (b land 0xF)]

let get_disp tbl src lbl =
  let dst = Hashtbl.find tbl lbl in
  dst - src - 2

let get_disp_mov tbl src lbl =
  let dst = Hashtbl.find tbl lbl in
  (dst - src - 1) lsr 1

let encode tbl (lbl,place,mn,args) =
  try
    (match (mn,args) with
      | (M_WRITE, [A_R n]) -> enc_int3 0x0 n 0x00
      | (M_READ, [A_R n]) -> enc_int3 0x0 n 0x01
      | (M_MOV, [A_Immd i; A_R n]) -> enc_int3 0xE n (check_immd 8 true i)
      | (M_MOV_L, [A_Disp_PC d; A_R n]) -> enc_int3 0x9 n (check_unsigned 8 d)
      | (M_MOV_L, [A_Label l; A_R n]) -> let d = get_disp_mov tbl place l in
                                         enc_int3 0x9 n (check_unsigned 8 d)
      | (M_MOV, [A_R m; A_R n]) -> enc_int4 0x6 n m 0x3
      | (M_MOV_L, [A_R m; A_At_R n]) -> enc_int4 0x2 n m 0x2
      | (M_MOV_L, [A_At_R m; A_R n]) -> enc_int4 0x6 n m 0x2
      | (M_STS, [A_PR; A_R n]) -> enc_int3 0x0 n 0x2A
      | (M_ADD, [A_R m; A_R n]) -> enc_int4 0x3 n m 0xC
      | (M_ADD, [A_Immd i; A_R n]) -> enc_int3 0x7 n (check_immd 8 true i)
      | (M_CMP_EQ, [A_R m; A_R n]) -> enc_int4 0x3 n m 0x0
      | (M_CMP_GT, [A_R m; A_R n]) -> enc_int4 0x3 n m 0x7
      | (M_SUB, [A_R m; A_R n]) -> enc_int4 0x3 n m 0x8
      | (M_AND, [A_R m; A_R n]) -> enc_int4 0x2 n m 0x9
      | (M_NOT, [A_R m; A_R n]) -> enc_int4 0x6 n m 0x7
      | (M_OR, [A_R m; A_R n]) -> enc_int4 0x2 n m 0xB
      | (M_XOR, [A_R m; A_R n]) -> enc_int4 0x2 n m 0xA
      | (M_SHLD, [A_R m; A_R n]) -> enc_int4 0x4 n m 0xD
      | (M_BF, [A_Label l]) -> let d = get_disp tbl place l in
                               enc_int3 0x8 0xB (check_signed 8 d)
      | (M_BF, [A_Immd d]) -> enc_int3 0x8 0xB (check_immd 8 true d)
      | (M_BT, [A_Label l]) -> let d = get_disp tbl place l in
                               enc_int3 0x8 0x9 (check_signed 8 d)
      | (M_BT, [A_Immd d]) -> enc_int3 0x8 0x9 (check_immd 8 true d)
      | (M_BRA, [A_Label l]) -> let d = get_disp tbl place l in
                                enc_int2 0xA (check_signed 12 d)
      | (M_BRA, [A_Immd d]) -> enc_int2 0xA (check_immd 12 true d)
      | (M_JMP, [A_At_R n]) -> enc_int3 0x4 n 0x2B
      | (M_JSR, [A_At_R n]) -> enc_int3 0x4 n 0x0B
      | (M_RTS, []) -> enc_int1 0x000B
      | (M_FLDI0, [A_FR n]) -> enc_int3 0xF n 0x8D
      | (M_FLDI1, [A_FR n]) -> enc_int3 0xF n 0x9D
      | (M_FMOV, [A_FR m; A_FR n]) -> enc_int4 0xF n m 0xC
      | (M_FMOV_S, [A_At_R m; A_FR n]) -> enc_int4 0xF n m 0x8
      | (M_FMOV_S, [A_FR m; A_At_R n]) -> enc_int4 0xF n m 0xA
      | (M_FADD, [A_FR m; A_FR n]) -> enc_int4 0xF n m 0x0
      | (M_FCMP_EQ, [A_FR m; A_FR n]) -> enc_int4 0xF n m 0x4
      | (M_FCMP_GT, [A_FR m; A_FR n]) -> enc_int4 0xF n m 0x5
      | (M_FDIV, [A_FR m; A_FR n]) -> enc_int4 0xF n m 0x3
      | (M_FMUL, [A_FR m; A_FR n]) -> enc_int4 0xF n m 0x2
      | (M_FNEG, [A_FR n]) -> enc_int3 0xF n 0x4D
      | (M_FSQRT, [A_FR n]) -> enc_int3 0xF n 0x6D
      | (M_FSUB, [A_FR m; A_FR n]) -> enc_int4 0xF n m 0x1
      | (M_LDS, [A_R m; A_FPUL]) -> enc_int3 0x4 m 0x5A
      | (M_STS, [A_FPUL; A_R n]) -> enc_int3 0x0 n 0x5A
      | (M_FLDS, [A_FR m; A_FPUL]) -> enc_int3 0xF m 0x1D
      | (M_FSTS, [A_FPUL; A_FR n]) -> enc_int3 0xF n 0x0D
      | (M_FTRC, [A_FR m; A_FPUL]) -> enc_int3 0xF m 0x3D
      | (M_FLOAT, [A_FPUL; A_FR n]) -> enc_int3 0xF n 0x2D
      | (M_DATA_L, [A_Immd (I_Dec i)]) ->
        enc_int1 (i land 0xFFFF) @ enc_int1 (i lsr 16)
      | (M_DATA_L, [A_Immd (I_Hex i)]) ->
        enc_int1 (i land 0xFFFF) @ enc_int1 (i lsr 16)
      | (M_DATA_L, [A_Label l]) ->
        let i = (Hashtbl.find tbl l) lsl 1 in
        enc_int1 (i land 0xFFFF) @
          enc_int1 (i lsr 16)
      | _ -> raise (Unknown_instruction (lbl,place,mn,args)))
  with
    | Failure s -> raise (Immd_out_of_bounds (lbl,place,mn,args))
    | Not_found -> raise (Unbound_label (lbl,place,mn,args))
    | e -> raise e

let rec enc1 = function
  | [] -> 0
  | x::xs -> x lor (enc1 xs lsl 8)

let show ot tbl (lbl,place,mn,args) =
  match mn with
    | M_DATA_L ->
        fprintf ot "%08X: %08X = %s %s%s\n" (place*2)
          (enc1 (encode tbl (lbl,place,mn,args)))
          (string_of_mn mn) (string_of_args tbl args)
          (string_of_label lbl)
    | _ ->
        fprintf ot "%08X:     %04X = %s %s%s\n" (place*2)
          (enc1 (encode tbl (lbl,place,mn,args)))
          (string_of_mn mn) (string_of_args tbl args)
          (string_of_label lbl)

(* let show_vhdl ot tbl (lbl,place,mn,args) = *)
(*   match mn with *)
(*     | M_DATA_L -> *)
(*       let c = enc1 (encode tbl (lbl,place,mn,args)) in *)
(*       fprintf ot "      zebius_inst(x\"%04X\"), -- = %s %s%s\n" (c land 0xFFFF) *)
(*         (string_of_mn mn) (string_of_args tbl args) (string_of_label lbl); *)
(*       fprintf ot "      zebius_inst(x\"%04X\"),\n" *)
(*         ((c lsr 16) land 0xFFFF) *)
(*     | _ -> *)
(*         fprintf ot "      zebius_inst(x\"%04X\"), -- = %s %s%s\n" *)
(*           (enc1 (encode tbl (lbl,place,mn,args))) *)
(*           (string_of_mn mn) (string_of_args tbl args) *)
(*           (string_of_label lbl) *)

let rec show_vhdl ot tbl n = function
  | [] -> ()
  | (lbl,place,mn,args)::is ->
    (match mn with
      | M_DATA_L ->
        fprintf ot "    %d => x\"%08X\", -- %s %s%s\n" n
          (enc1 (encode tbl (lbl,place,mn,args)))
          (string_of_mn mn) (string_of_args tbl args) (string_of_label lbl);
        show_vhdl ot tbl (n+1) is
      | _ -> show_vhdl_go ot tbl n (lbl,place,mn,args) is)

and show_vhdl_go ot tbl n (l1,p1,m1,a1) = function
  | [] ->
    fprintf ot "    %d => x\"%04X%04X\", -- %s %s%s\n" n
      0 (enc1 (encode tbl (l1,p1,m1,a1)))
      (string_of_mn m1) (string_of_args tbl a1) (string_of_label l1)
  | (l2,p2,m2,a2)::is ->
    fprintf ot "    %d => x\"%04X%04X\", -- %s %s%s : %s %s%s\n" n
      (enc1 (encode tbl (l2,p2,m2,a2))) (enc1 (encode tbl (l1,p1,m1,a1)))
      (string_of_mn m1) (string_of_args tbl a1) (string_of_label l1)
      (string_of_mn m2) (string_of_args tbl a2) (string_of_label l2);
    show_vhdl ot tbl (n+1) is

let show_error ot tbl (lbl,place,mn,args) =
  match mn with
    | M_DATA_L ->
        fprintf ot "%08X: %s %s%s\n" (place*2)
          (string_of_mn mn) (string_of_args tbl args)
          (string_of_label lbl)
    | _ ->
        fprintf ot "%08X: %s %s%s\n" (place*2)
          (string_of_mn mn) (string_of_args tbl args)
          (string_of_label lbl)
