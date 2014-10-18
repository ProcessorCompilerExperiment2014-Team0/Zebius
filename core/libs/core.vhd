library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library work;
use work.zebius_p.all;

package zebius_core_p is

  type zebius_inst_mode_t is (MODE_NOP,
                              MODE_MOV_IMMEDIATE,
                              MODE_MOV_REGISTER,
                              MODE_ADD_IMMEDIATE,
                              MODE_ARITH);

  function zebius_inst_mode (zi : zebius_inst_t) return zebius_inst_mode_t;

end zebius_core_p;



package body zebius_core_p is

  function zebius_inst_mode (zi : zebius_inst_t)
    return zebius_inst_mode_t is
    variable m : zebius_inst_mode_t := MODE_NOP;
  begin

    if zi.a = "1110" then
      -- MOV #i Rn
      m := MODE_MOV_IMMEDIATE;
 
    elsif (zi.a = "0110" and zi.d = "0011") or
      (zi.a = "0000" and zi.c = "0010" and zi.d = "1010") then
      -- MOV Rm Rn / STS PR Rn
      m := MODE_MOV_REGISTER;

    elsif zi.a = "0111" then
      -- ADD #imm Rn
      m := MODE_ADD_IMMEDIATE;

    elsif  zi.a = "0011" or zi.a = "0010" or
      (zi.a = "0110" and zi.d = "0111") or
      (zi.a = "0100" and zi.d = "1101") then
      -- (Arith) Rm Rn
      m := MODE_ARITH;

    end if;

    return m;

  end;

end zebius_core_p;
