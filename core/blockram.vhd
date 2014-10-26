library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

package blockram_p is

  component blockram is
    port (
      clk : in std_logic;
      we : in std_logic;
      en : in std_logic;
      addr : in unsigned(7 downto 0);
      di : in unsigned(31 downto 0);
      do : out unsigned(31 downto 0));
  end component;

end blockram_p;

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity blockram is
  port (
    clk : in std_logic;
    we : in std_logic;
    en : in std_logic;
    addr : in unsigned(7 downto 0);
    di : in unsigned(31 downto 0);
    do : out unsigned(31 downto 0));
end blockram;


architecture syn of blockram is
  type ram_type is array (255 downto 0) of unsigned(31 downto 0);
  signal RAM: ram_type := (
    0 => x"E100E00A", -- = MOV     #10, R0    ;; .start, MOV     #0, R1
    1 => x"E301E201", -- = MOV     #1, R2 MOV     #1, R3
    2 => x"62336423", -- = MOV     R2, R4    ;; .loop MOV     R3, R2
    3 => x"70FF334C", -- = ADD     R4, R3 ADD     #-1, R0
    4 => x"02003100", -- = CMP/EQ  R0, R1 WRITE   R2
    5 => x"AFF38BF8", -- = BF      .loop BRA     .start
    others => x"00000000");
begin

  process(clk)
  begin
    if rising_edge(clk) then
      if en = '1' then
        if we = '1' then
          RAM(to_integer(addr)) <= di;
        end if;
        do <= RAM(to_integer(addr));
      end if;
    end if;
  end process;

end syn;
