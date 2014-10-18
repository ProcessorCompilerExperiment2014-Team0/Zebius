library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library work;
use work.zebius_p.all;
use work.zebius_alu_p.all;

entity zebius_alu is
  port ( clk  : in  std_logic;
         din  : in  alu_in_t;
         dout : out alu_out_t);
end zebius_alu;

architecture behavior of zebius_alu is
  
  function alu_add ( a: reg_data_t; b: reg_data_t) return reg_data_t is
  begin return a+b; end;

  function alu_sub ( a: reg_data_t; b: reg_data_t) return reg_data_t is
  begin return b-a; end;

  function alu_and ( a: reg_data_t; b: reg_data_t) return reg_data_t is
  begin return a and b; end;

  function alu_or ( a: reg_data_t; b: reg_data_t) return reg_data_t is
  begin return a or b; end;

  function alu_not ( a: reg_data_t; b: reg_data_t) return reg_data_t is
  begin return not a; end;

  function alu_xor ( a: reg_data_t; b: reg_data_t) return reg_data_t is
  begin return a xor b; end;

  function alu_shld ( a: reg_data_t; b: reg_data_t) return reg_data_t is
    variable c: reg_data_t;
  begin
    if a(31) = '0' then
      c := shift_left(b, to_integer(a(30 downto 0)));
    else
      c := shift_right(b, to_integer(a(30 downto 0)));
    end if;

    return c;
  end;

  function alu_eq ( a: reg_data_t; b: reg_data_t) return reg_data_t is
  begin
    if a = b then
      return to_unsigned(1, 32);
    else
      return to_unsigned(0, 32);
    end if;
  end;

  function alu_gt ( a: reg_data_t; b: reg_data_t) return reg_data_t is
  begin
    if a > b then
      return to_unsigned(1, 32);
    else
      return to_unsigned(0, 32);
    end if;
  end;

  function alu_nop ( a: reg_data_t; b: reg_data_t) return reg_data_t is
  begin return to_unsigned(0, 32); end;
  
begin
  process(clk)
  begin
    if rising_edge(clk) then
      case din.inst is
        when ALU_INST_ADD  => dout.o <= alu_add(din.i1, din.i2);
        when ALU_INST_SUB  => dout.o <= alu_sub(din.i1, din.i2);
        when ALU_INST_AND  => dout.o <= alu_and(din.i1, din.i2);
        when ALU_INST_OR   => dout.o <= alu_or(din.i1, din.i2);
        when ALU_INST_NOT  => dout.o <= alu_not(din.i1, din.i2);
        when ALU_INST_XOR  => dout.o <= alu_xor(din.i1, din.i2);
        when ALU_INST_SHLD => dout.o <= alu_shld(din.i1, din.i2);
        when ALU_INST_EQ   => dout.o <= alu_eq(din.i1, din.i2);
        when ALU_INST_GT   => dout.o <= alu_gt(din.i1, din.i2);
        when others        => dout.o <= alu_nop(din.i1, din.i2);
      end case;
    end if;
  end process;

end behavior;
