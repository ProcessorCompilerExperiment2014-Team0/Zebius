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
    0 => x"E101E000", -- MOV     #0, R0    ;; .start : MOV     #1, R1
    1 => x"E303E20A", -- MOV     #10, R2 : MOV     #3, R3
    2 => x"442DE401", -- MOV     #1, R4 : SHLD    R2, R4
    3 => x"66076543", -- MOV     R4, R5 : NOT     R0, R6
    4 => x"0901E800", -- MOV     #0, R8 : READ    R9    ;; .loop
    5 => x"3030389C", -- ADD     R9, R8 : CMP/EQ  R3, R0
    6 => x"481D8902", -- BT      .write : SHLD    R1, R8
    7 => x"AFF873FF", -- ADD     #-1, R3 : BRA     .loop
    8 => x"89033960", -- CMP/EQ  R6, R9    ;; .write : BT      .run
    9 => x"75042592", -- MOV.L   R9, @R5 : ADD     #4, R5
    10 => x"AFF2E303", -- MOV     #3, R3 : BRA     .loop
    11 => x"0000442B", -- JMP     @R4    ;; .run
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
