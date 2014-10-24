library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library work;
use work.zebius_decode_p.all;


package zebius_loader_p is

constant array_bound :integer := 15;

type array_inst_t is array (0 to array_bound) of zebius_inst_t;
  constant array_inst : array_inst_t
    := (
      zebius_inst(x"E340"), -- = MOV     #64, R3    ,, .start
      zebius_inst(x"E040"), -- = MOV     #64, R0
      zebius_inst(x"E100"), -- = MOV     #0, R1
      zebius_inst(x"2012"), -- = MOV.L   R1, @R0    ,, .write
      zebius_inst(x"7004"), -- = ADD     #4, R0
      zebius_inst(x"7101"), -- = ADD     #1, R1
      zebius_inst(x"3310"), -- = CMP/EQ  R1, R3
      zebius_inst(x"8BFA"), -- = BF      .write
      zebius_inst(x"E100"), -- = MOV     #0, R1
      zebius_inst(x"70FC"), -- = ADD     #-4, R0    ,, .read
      zebius_inst(x"6202"), -- = MOV.L   @R0, R2
      zebius_inst(x"0200"), -- = WRITE   R2
      zebius_inst(x"7101"), -- = ADD     #1, R1
      zebius_inst(x"3310"), -- = CMP/EQ  R1, R3
      zebius_inst(x"8BF9"), -- = BF      .read
      zebius_inst(x"AFEF") -- = BRA     .start

      --zebius_inst(x"E00A"), -- = MOV     #10, R0    ;; .start
      --zebius_inst(x"E100"), -- = MOV     #0, R1
      --zebius_inst(x"E201"), -- = MOV     #1, R2
      --zebius_inst(x"E301"), -- = MOV     #1, R3
      --zebius_inst(x"6423"), -- = MOV     R2, R4    ;; .loop
      --zebius_inst(x"6233"), -- = MOV     R3, R2
      --zebius_inst(x"334C"), -- = ADD     R4, R3
      --zebius_inst(x"70FF"), -- = ADD     #-1, R0
      --zebius_inst(x"3100"), -- = CMP/EQ  R0, R1
      --zebius_inst(x"8BF9"), -- = BF      .loop
      --zebius_inst(x"0200"), -- = MOV     R2, R2
      --zebius_inst(x"AFF3") -- = BRA     .start
      );

end package;
