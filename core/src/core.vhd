library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library work;
use work.zebius.all;

entity zebius_core is
  port ( clk      : in  std_logic;
         sram_in  : out sram_in_t;
         sram_out : in  sram_out_t);
end zebius_core;

architecture behavior of zebius_core is

  type reg_file_t is array 0 to 48 of reg_data_t;
  --  0: Program Counter
  --  1: Procedure Register
  --  2: Global Base Register
  --  3: Status Register
  --  4: Floating-point Communication Register
  --  5: Floating-point Status/Control Register
  --  6-15: reserved
  -- 16-31: General Porpose Register
  -- 32-48: Floating-point Register

  type ratch_t is record
    reg_file : reg_file_t;
  end record;

  signal r, rin : ratch_t;
  
begin

  comb: process(sram_in, sram_out, r)
  begin
    -- fixme
  end process;

  ratch: process(clk)
  begin
    if rising_edge(clk) then
      r <= rin;
    end if;
  end process;
  
end behavior;
