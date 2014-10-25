library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library work;
use work.zebius_type_p.all;

package zebius_alu_p is

  subtype alu_inst_t is unsigned(3 downto 0);

  constant ALU_INST_NOP : alu_inst_t := "0000";
  constant ALU_INST_ADD : alu_inst_t := "0001";
  constant ALU_INST_SUB : alu_inst_t := "0010";
  constant ALU_INST_AND : alu_inst_t := "0100";
  constant ALU_INST_OR : alu_inst_t := "0101";
  constant ALU_INST_NOT : alu_inst_t := "0110";
  constant ALU_INST_XOR : alu_inst_t := "0111";
  constant ALU_INST_SHLD : alu_inst_t := "1000";
  constant ALU_INST_EQ : alu_inst_t := "1001";
  constant ALU_INST_GT : alu_inst_t := "1010";
  constant ALU_INST_INC_PC : alu_inst_t := "1011";
  constant ALU_INST_DISP_L : alu_inst_t := "1100";


  type alu_in_t is record
    inst : alu_inst_t;
    i1   : reg_data_t;
    i2   : reg_data_t;
  end record;

  type alu_out_t is record
    o : reg_data_t;
  end record;

  component zebius_alu
    port ( din  : in  alu_in_t;
           dout : out alu_out_t);
  end component;

end zebius_alu_p;



library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library work;
use work.zebius_alu_p.all;
use work.zebius_type_p.all;


entity zebius_alu is
  port ( din  : in  alu_in_t;
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

    if signed(a) > 0 then
      c := shift_left(b, to_integer(a(4 downto 0)));
    elsif a(4 downto 0) = "00000" then
      c := to_unsigned(0, 32);
    else
      c := shift_right(b, to_integer(-signed(a) and x"001f") + 1);
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


  function alu_inc_pc ( a: reg_data_t; disp: reg_data_t) return reg_data_t is
  begin
    return unsigned(signed(a+4)+signed(disp(11 downto 0))*2);
  end;

  function alu_disp_l ( a: reg_data_t; disp: reg_data_t) return reg_data_t is
  begin
    return unsigned(signed(a)+signed(disp(11 downto 0))*4);
  end;


begin

  process(din)
  begin
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
      when ALU_INST_INC_PC => dout.o <= alu_inc_pc(din.i1, din.i2);
      when ALU_INST_DISP_L => dout.o <= alu_disp_l(din.i1, din.i2);
      when others        => dout.o <= alu_nop(din.i1, din.i2);
    end case;
  end process;

end behavior;
