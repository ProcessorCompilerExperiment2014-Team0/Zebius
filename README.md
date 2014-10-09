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
	I-form | op | rs |disp| rd |
	M-form | op |   immd  | rd |
	B-form | op |     addr     |
```
