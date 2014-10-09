# Zebius: Team0 first architecture
CPU実験

## 設計原則
小さくシンプルに。11月中に完動させることを目標にする。

## レジスタ
データ長は32bitの汎用レジスタ16個。ただしr0は特殊な値と見做すので実質15個。

## 命令フォーマット
命令は16bit固定長。

```
           | 4  | 4  | 4  | 4  |
	R-form | op | rs | rt | rd |
	M-form | op | rs |disp| rd |
	I-form | op | r  |   immd  |
	B-form | op |     addr     |
```

## 命令セット
* 整数演算
	- R add rs rt rd
	- R shl rs rt rd
	- R and rs rt rd
	- R or  rs rt rd
	- R cmp rs rt rd
* 浮動小数演算
	- R fadd rs rt rd
	- R fmul rs rt rd
	- R fneg rs rt rd
	- R fcmp rs rt td
* 単項演算
	- M mono rs op rd
		+ finv
		+ fneg
		+ fsqrt
		+ neg
		+ not
* メモリ命令
	- M ld rs disp rd
	- M st rs disp rd
	- I li rs immd
* 分岐命令
	- I beq rs addr
	- I bgt rs addr
	- B jmp addr
