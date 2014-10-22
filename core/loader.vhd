library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library work;
use work.zebius_p.all;


package zebius_loader_p is

constant array_bound :integer :=14;

type array_inst_t is array (0 to array_bound) of zebius_inst_t;
  constant array_inst : array_inst_t
    := (
      zebius_inst(x"E340"), -- = MOV     #64, R3    ;; .start
      zebius_inst(x"E040"), -- = MOV     #64, R0
      zebius_inst(x"E100"), -- = MOV     #0, R1
      zebius_inst(x"2012"), -- = MOV.L   R1, @R0    ;; .write
      zebius_inst(x"7004"), -- = ADD     #4, R0
      zebius_inst(x"7101"), -- = ADD     #1, R1
      zebius_inst(x"3310"), -- = CMP/EQ  R1, R3
      zebius_inst(x"8BFA"), -- = BF      .write
      zebius_inst(x"E100"), -- = MOV     #0, R1
      zebius_inst(x"70FC"), -- = ADD     #-4, R0    ;; .read
      zebius_inst(x"6202"), -- = MOV.L   @R0, R2
      zebius_inst(x"7101"), -- = ADD     #1, R1
      zebius_inst(x"3310"), -- = CMP/EQ  R1, R3
      zebius_inst(x"8BFA"), -- = BF      .read
      zebius_inst(x"AFF0") -- = BRA     .start
      );

end package;
