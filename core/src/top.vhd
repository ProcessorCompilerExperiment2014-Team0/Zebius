library ieee;
use ieee.std_logic_1164.all;

library unisim;
use unisim.vcomponents.all;

entity top is
    port (mclk1 : in  std_logic;
          rs_rx : in  std_logic;
          rs_tx : out std_logic);
end top;

architecture behavior of top is

  component zebius_core
    port ( clk : in  std_logic;
           rx  : in  std_logic;
           tx  : out std_logic);
  end component;

  signal clk,iclk: std_logic;
  signal hoge : std_logic;
  
begin
  ib: ibufg
  port map (
    i => mclk1,
    o => iclk);
  bg: bufg
  port map (
    i => iclk,
    o => clk);

  processor : zebius_core
    port map (clk   => clk,
              rx => rs_rx,
              tx => rs_tx);
end behavior;
