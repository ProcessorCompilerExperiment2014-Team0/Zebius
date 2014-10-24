library ieee;
use ieee.std_logic_1164.all;

package zebius_u232c_out_p is

  type u232c_out_in_t is record
    data : std_logic_vector (7 downto 0);
    go   : std_logic;
  end record;

  type u232c_out_out_t is record
    busy : std_logic;
  end record;

  component u232c_out
    generic (
      report_write : boolean := false;
      wtime : std_logic_vector(15 downto 0));
    port (
      clk  : in  std_logic;
      data : in  std_logic_vector (7 downto 0);
      go   : in  std_logic;
      busy : out std_logic;
      tx   : out std_logic);
  end component;

end zebius_u232c_out_p;



library std;
use std.textio.all;

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;


entity u232c_out is
  generic (
    report_write : boolean;
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

  file ofile : text is out "output.txt";
begin
  statemachine: process(clk)
    variable l : line;
  begin
    if rising_edge(clk) then
      case state is
        when "1011"=>
          if go='1' then
            if report_write then
              write(l, conv_integer(data));
              writeline(ofile, l);
            end if;

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
