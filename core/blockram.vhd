library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

package blockram_p is

  type blockram_in_t is record
    we : std_logic;
    en : std_logic;
    addr : unsigned(7 downto 0);
    data : unsigned(31 downto 0);
  end record;

  type blockram_out_t is record
    data : unsigned(31 downto 0);
  end record;

  component blockram is
    port (
      clk : in std_logic;
      din : in blockram_in_t;
      dout : out blockram_out_t);
  end component;

end blockram_p;

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library work;
use work.blockram_p.all;

entity blockram is
  port (
    clk : in std_logic;
    din : in blockram_in_t;
    dout : out blockram_out_t);
end blockram;


architecture syn of blockram is
  type ram_type is array (255 downto 0) of unsigned(31 downto 0);
  signal RAM: ram_type := (
    0 => x"01000101", -- READ    R1    ;; .start : WRITE   R1
    1 => x"0000AFFC", -- BRA     .start
    others => x"00000000");
begin

  process(clk)
  begin
    if rising_edge(clk) then
      if din.en = '1' then
        if din.we = '1' then
          RAM(to_integer(din.addr)) <= din.data;
        end if;
        dout.data <= RAM(to_integer(din.addr));
      end if;
    end if;
  end process;

end syn;
