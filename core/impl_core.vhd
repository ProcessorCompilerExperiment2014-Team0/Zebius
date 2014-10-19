library ieee;
use ieee.std_logic_1164.all;

library unisim;
use unisim.vcomponents.all;

library work;
use work.zebius_p.all;
use work.zebius_component_p.all;

entity top is
    port ( mclk1 : in  std_logic;
           rs_rx : in  std_logic;
           rs_tx : out std_logic);
end top;

architecture behavior of top is

  signal clk : std_logic;
  signal ci  : core_in_t;
  signal co  : core_out_t;

  signal clk,iclk: std_logic;
  
begin
  ib: ibufg
  port map (
    i => mclk1,
    o => iclk);
  bg: bufg
  port map (
    i => iclk,
    o => clk);

  core : zebius_core
    port map ( clk => clk,
               ci   => ci,
               co   => co);

  alu : zebius_alu
    port map ( din  => co.alu,
               dout => ci.alu);

  sout : u232c_out
    generic map ( wtime => x"1ADB" )
    port map ( clk  => clk,
               data => co.sout.data,
               go   => co.sout.go,
               busy => ci.sout.busy,
               tx   => rs_tx);

end behavior;
