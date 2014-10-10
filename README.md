# Zebius: Team0 first architecture
CPU実験

## 設計原則
小さくシンプルに。11月中に完動させることを目標にする。

## 設計方針
* 16bit固定長命令
* バイトマシン
* リトルエンディアン

## レジスタ
データ長は32bitの汎用レジスタ16個。ただしr0は特殊な値と見做すので実質15個。


## 命令フォーマット
命令は16bit固定長。

```
           | 4  | 4  | 4  | 4  |
	R-form | op | rs | rt | rd |
	M-form | op | rs |disp| r1 |
	U-form | UN | rs | op | rd |
	I-form | op | r  |   immd  |
	B-form | op |     addr     |
```

## 命令セット
### 一覧
* 整数演算
	- R add (rs)+(rt)->rd
	- U neg -(rs)->rd
	- R cmp cmp((rs),(rt))->rd
* ビット演算
	- R shl (rs)<<(rt)->rd
	- R and (rs)&(rt)->rd
	- R or  (rs)|(rt)->rd
	- R xor (rs)^(rt)->rd
	- U not ~(rs)->rd
* 浮動小数演算
	- R fadd (rs)+(rt)->rd
	- R fmul (rs)*(rt)->rd
	- U finv 1/(rs)->rd
	- U fneg -(rs)->rd
	- U fsqrt sqrt(rs)->rd
	- R fcmp cmp((rs),(rt)->rd
* メモリ命令
	- M ld *disp(rs)->r1
	- M st *disp(rs)<-r1
* IO命令
	- U read  read()->rd
	- U write write((rs))
* 分岐命令
	- I beq if(eq?(rs)) goto(addr)
	- I bgt if(gt?(rs)) goto(addr)
	- B jmp goto(addr)

### OPCODE表
#### Unary以外
| inst  | opcode |
|:------|:------:|
| add   |  0000  |
| cmp   |  0001  |
| shl   |  0010  |
| and   |  0011  |
| or    |  0100  |
| xor   |  0101  |
| unary |  0110  |
| fadd  |  0111  |
| fmul  |  1000  |
| fcmp  |  1001  |
| ld    |  1010  |
| st    |  1011  |
| beq   |  1100  |
| bgt   |  1101  |
| jmp   |  1110  |

#### Unary
| inst  | opcode |
|:------|:------:|
| neg   |  0000  |
| not   |  0001  |
| finv  |  0010  |
| fneg  |  0011  |
| fsqrt |  0100  |
| read  |  0101  |
| write |  0110  |
