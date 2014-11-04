library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library work;
use work.zebius_type_p.all;

package zebius_fpu_p is

  type fpu_inst_t is (
    FPU_INST_NOP,

    FPU_INST_ADD,
    FPU_INST_SUB,
    FPU_INST_DIV,
    FPU_INST_MUL,
    FPU_INST_NEG,
    FPU_INST_EQ,
    FPU_INST_GT,
    FPU_INST_SQRT,
    FPU_INST_ITOF,
    FPU_INST_FTOI);

  type fpu_in_t is record
    inst : fpu_inst_t;
    i1   : reg_data_t;
    i2   : reg_data_t;
  end record;

  type fpu_out_t is record
    o : reg_data_t;
  end record;

  component zebius_fpu
    port ( din  : in  fpu_in_t;
           dout : out fpu_out_t);
  end component;

end zebius_fpu_p;



library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library work;
use work.fadd_p.all;
use work.finv_p.all;
use work.fmul_p.all;
use work.fsqrt_p.all;
use work.fsub_p.all;

use work.zebius_type_p.all;
use work.zebius_fpu_p.all;


entity zebius_fpu is
  port (
    din  : in  fpu_in_t;
    dout : out fpu_out_t);
end zebius_fpu;


architecture behavior of zebius_fpu is

  signal a: std_logic_vector(31 downto 0) := (others => '0');
  signal b: std_logic_vector(31 downto 0) := (others => '0');
  signal add_s: std_logic_vector(31 downto 0);
  signal inv_s: std_logic_vector(31 downto 0);
  signal mul_s: std_logic_vector(31 downto 0);
  signal neg_s: std_logic_vector(31 downto 0);
  signal sqrt_s: std_logic_vector(31 downto 0);
  signal sub_s: std_logic_vector(31 downto 0);
  signal inst: fpu_inst_t := FPU_INST_NOP;

begin

  add: fadd port map (
    a => a,
    b => b,
    s => add_s);

  inv: finv port map (
    a => a,
    s => sub_s);

  mul: fmul port map (
    a => a,
    b => b,
    s => mul_s);

  --neg: fneg port map (
  --  a => a,
  --  s => neg_s);

  sqrt: fsqrt port map (
    a => a,
    s => sqrt_s);

  sub: fsub port map (
    a => a,
    b => b,
    s => sub_s);


  process(din, add_s, sub_s, neg_s, sqrt_s)
  begin

    a <= std_logic_vector(din.i1);
    b <= std_logic_vector(din.i2);

    case din.inst is
      when FPU_INST_ADD => dout.o <= unsigned(add_s);
      when FPU_INST_SUB => dout.o <= unsigned(sub_s);
      when FPU_INST_DIV => dout.o <= unsigned(inv_s);
      when FPU_INST_MUL => dout.o <= unsigned(mul_s);
      when FPU_INST_NEG => assert false report "FNEG is not implemented" severity error;
      when FPU_INST_EQ => assert false report "FCMP/EQ is not implemented" severity error;
      when FPU_INST_GT => assert false report "FCMP/GT is not implemented" severity error;
      when FPU_INST_SQRT => dout.o <= unsigned(sqrt_s);
      when FPU_INST_ITOF => assert false report "ITOF is not implemented" severity error;
      when FPU_INST_FTOI => assert false report "FTOI is not implemented" severity error;
      when FPU_INST_NOP => dout.o <= (others => '0');
    end case;
  end process;

end behavior;
