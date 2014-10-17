library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity coretb is
end coretb;

architecture testbench of coretb is

  component zebius_core
    port ( clk : in std_logic);
  end component;

  signal clk : std_logic;
  
begin
  processor : zebius_core port map (clk => clk);
  
  clockgen: process
  begin
    clk <= '0';
    wait for 5 ns;
    clk <= '1';
    wait for 5 ns;
  end process;
end testbench;
