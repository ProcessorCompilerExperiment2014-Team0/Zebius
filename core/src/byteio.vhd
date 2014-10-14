library ieee;
use ieee.std_logic_1164.all;

library unisim;
use unisim.vcomponents.all;

entity serial_byte is
    port (mclk1 : in  std_logic;
          rs_rx : in  std_logic;
          rs_tx : out std_logic);
end serial_byte;

architecture test of serial_byte is
  signal clk,iclk: std_logic;
  
  component u232c_byteio is
    generic (wtime: std_logic_vector(15 downto 0));
    port (clk   : in  std_logic;
          rs_rx : in  std_logic;
          rs_tx : out std_logic);
  end component;

begin
  ib: ibufg port map (
    i => mclk1,
    o => iclk);
  bg: bufg port map (
    i => iclk,
    o => clk);
  
  rs232c : u232c_byteio generic map (wtime=>x"1c06")
  port map (
    clk   => clk,
    rs_rx => rs_rx,
    rs_tx => rs_tx);
end test;
