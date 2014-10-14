library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;

entity u232c_out_tb is
end u232c_out_tb;

architecture test of u232c_out_tb is
  constant byte : std_logic_vector(7 downto 0) := "10110101";

  component u232c_out is
      generic (wtime: std_logic_vector(15 downto 0) := x"1ADB");
      port (clk  : in  std_logic;
            data : in  std_logic_vector (7 downto 0);
            go   : in  std_logic;
            busy : out std_logic;
            tx   : out std_logic);
  end component;

  signal tx, go, busy, clk : std_logic;
  signal data              : std_logic_vector(7 downto 0);
  signal cnt               : std_logic_vector(4 downto 0) := "00000";
begin
  rs232c_out : u232c_out generic map (wtime=>x"0000")
  port map (clk  => clk,
            data => data,
            go   => go,
            busy => busy,
            tx   => tx);

  read: process(clk)
  begin
    if rising_edge(clk) then
      if busy='0' and go='0' then
        data <= byte;
        go<='1';
      else
        go<='0';
      end if;
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
