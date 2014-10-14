library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;

entity u232c_in_tb is
end u232c_in_tb;

architecture test of u232c_in_tb is
  constant wave : std_logic_vector(19 downto 0) := "11111001101010000100";

  component u232c_in is
    generic (wtime: std_logic_vector(15 downto 0));
    port (clk  : in  std_logic;
          data : out std_logic_vector(7 downto 0);
          go   : out std_logic;
          rx   : in  std_logic);
  end component;

  signal rx, go, clk : std_logic;
  signal data        : std_logic_vector(7 downto 0);
  signal cnt         : std_logic_vector(4 downto 0) := "00000";
begin
  rs232c_in : u232c_in generic map (wtime=>x"0000")
  port map (clk=>clk,
            data=>data,
            go=>go,
            rx=>rx);

  read: process(clk)
  begin
    if rising_edge(clk) then
      if cnt="10011" then
        cnt<="00000";
      else
        cnt<=cnt+1;
      end if;
      rx<=wave(conv_integer(cnt));      
    end if;
  end process;
  
  clockgen: process
  begin
    clk<='0';
    wait for 5 ns;
    clk<='1';
    wait for 5 ns;
  end process;
end test;
