# Zebius core
## TODO
| TASK | FPGA/SIM/YET |
| :--- | :------: |
| ALU | FPGA |
| IOコントローラ | FPGA(Output Only) |
| sramコントローラ | FPGA |
| 算術命令の実行 | FPGA |
| 浮動小数点数命令の実行 | YET |
| データ移動命令(reg)の実行 | FPGA |
| データ移動命令(sram)の実行 | FPGA |
| 分岐命令の実行 | FPGA |
| fibをループで動作させる | FPGA |
| fibを再帰で動作させる | FPGA |
| レイトレーサ | YET |

## 使い方
* 実行するプログラムはblockramの初期値として格納される。
	- zasm <programname>.s -v とすると標準出力にいい感じのコードの断片が吐き出されるので貼っつける
* 後はmakeすればシミュレーションが始まって出力がoutput.txtに出る
