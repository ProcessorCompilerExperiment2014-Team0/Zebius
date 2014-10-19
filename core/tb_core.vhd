library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library work;
use work.zebius_p.all;
use work.zebius_component_p.all;

entity tb_core is
end tb_core;

architecture testbench of tb_core is

  signal clk : std_logic;
  signal ci  : core_in_t;
  signal co  : core_out_t;

  signal rs_tx : std_logic;

begin

  core : zebius_core
    port map ( clk => clk,
               ci  => ci,
               co  => co);

  alu : zebius_alu
    port map ( din  => co.alu,
               dout => ci.alu);

  sout : u232c_out
    generic map ( wtime => x"0005" )
    port map ( clk  => clk,
               data => co.sout.data,
               go   => co.sout.go,
               busy => ci.sout.busy,
               tx   => rs_tx);

  clockgen: process
  begin
    clk <= '0';
    wait for 5 ns;
    clk <= '1';
    wait for 5 ns;
  end process;

end testbench;
