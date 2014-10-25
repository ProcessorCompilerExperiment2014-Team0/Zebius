library std;
use std.textio.all;

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

entity u232c_out is
  generic (
    wtime: std_logic_vector(15 downto 0) := x"1ADB");
  port (
    clk  : in  STD_LOGIC;
    data : in  STD_LOGIC_VECTOR (7 downto 0);
    go   : in  STD_LOGIC;
    busy : out STD_LOGIC;
    tx   : out STD_LOGIC);
end u232c_out;

architecture blackbox of u232c_out is
  signal countdown : std_logic_vector(15 downto 0) := (others=>'0');
  signal sendbuf : std_logic_vector(8 downto 0) := (others=>'1');
  signal state : std_logic_vector(3 downto 0) := "1111";

  --file ofile : text is out "hoge.txt";
begin
  statemachine: process(clk)
    variable l : line;
  begin
    if rising_edge(clk) then
      case state is
        when "1011"=>
          if go='1' then
            --write(l, conv_integer(data));
            --writeline(ofile, l);
            sendbuf<=data&"0";
            state<=state-1;
            countdown<=wtime;
          end if;
        when others=>
          if countdown=0 then
            sendbuf<="1"&sendbuf(8 downto 1);
            countdown<=wtime;
            state<=state-1;
          else
            countdown<=countdown-1;
          end if;
      end case;
    end if;
  end process;
  tx<=sendbuf(0);
  busy<= '0' when state="1011" else '1';
end blackbox;
