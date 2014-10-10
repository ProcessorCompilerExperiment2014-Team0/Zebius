zsim : Zebius simulator

opcodeの割り当てなど細かい部分は適当です。
詳細が決まったら随時変更します。

現在のところ命令はメモリ上には置かれず、
(コアから見て)外部の領域に置かれます

-opcode
0 add
1 shl
2 and
3 or
4 cmp
5 fadd
6 fmul
7 fcmp
8 unary
9 ld
A st
B beq
C bgt
D jmp

-unary opcode
0 neg
1 not
2 finv
3 fneg
4 fsqrt(未実装)
5 wr(未実装)
6 rd(未実装)

-未実装の命令
--fsqrt
---sqrtfが見つからないと言われるので誰か分かったら教えて下さい
   "-lm"オプションは試した
--wt
--rd
