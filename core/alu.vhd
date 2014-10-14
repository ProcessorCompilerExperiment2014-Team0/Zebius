library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library work;
use work.zebius.all;

entity zebius_alu is
  port ( clk  : in std_logic;
         inst : in  std_logic_vector(3 downto 0);
         i1   : in  reg_data;
         i2   : in  reg_data;
         o    : out reg_data);
end zebius_alu;


architecture behavior of zebius_alu is

  function alu_add ( a: reg_data; b: reg_data) return reg_data is
  begin return a+b; end;

  function alu_sub ( a: reg_data; b: reg_data) return reg_data is
  begin return b-a; end;

  function alu_and ( a: reg_data; b: reg_data) return reg_data is
  begin return a and b; end;

  function alu_or ( a: reg_data; b: reg_data) return reg_data is
  begin return a or b; end;

  function alu_not ( a: reg_data; b: reg_data) return reg_data is
  begin return not a; end;

  function alu_xor ( a: reg_data; b: reg_data) return reg_data is
  begin return a or b; end;

  function alu_shld ( a: reg_data; b: reg_data) return reg_data is
    variable c: reg_data;
  begin
    if a(31) = '0' then
      c := shift_left(b, to_integer(a(30 downto 0)));
    else
      c := shift_right(b, to_integer(a(30 downto 0)));
    end if;

    return c;
  end;

  function alu_eq ( a: reg_data; b: reg_data) return reg_data is
  begin
    if a = b then
      return to_unsigned(1, 32);
    else
      return to_unsigned(0, 32);
    end if;
  end;

  function alu_gt ( a: reg_data; b: reg_data) return reg_data is
  begin
    if a > b then
      return to_unsigned(1, 32);
    else
      return to_unsigned(0, 32);
    end if;
  end;

  function alu_nop ( a: reg_data; b: reg_data) return reg_data is
  begin return to_unsigned(0, 32); end;
  
begin

  process(clk)
  begin
    if rising_edge(clk) then
      case inst is
        when "0001" => o <= alu_add(i1, i2);
        when "0010" => o <= alu_sub(i1, i2);
        -- when "0011" => o <= alu_neg(i1, i2);
        when "0100" => o <= alu_and(i1, i2);
        when "0101" => o <= alu_or(i1, i2);
        when "0110" => o <= alu_not(i1, i2);
        when "0111" => o <= alu_xor(i1, i2);
        when "1000" => o <= alu_shld(i1, i2);
        when "1001" => o <= alu_eq(i1, i2);
        when "1010" => o <= alu_gt(i1, i2);
        when others => o <= alu_nop(i1, i2);
      end case;
    end if;
  end process;

end behavior;
