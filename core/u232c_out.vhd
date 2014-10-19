library ieee;
use ieee.std_logic_1164.ALL;
use ieee.std_logic_unsigned.ALL;

entity u232c_out is
  generic (wtime: std_logic_vector(15 downto 0) := x"1ADB");
  port ( clk  : in  std_logic;
         data : in  std_logic_vector (7 downto 0);
         go   : in  std_logic;
         busy : out std_logic;
         tx   : out std_logic);
end u232c_out;

architecture blackbox of u232c_out is
  signal countdown: std_logic_vector(15 downto 0) := (others=>'0');
  signal sendbuf: std_logic_vector(8 downto 0) := (others=>'1');
  signal state: std_logic_vector(3 downto 0) := "1111";
begin
  statemachine: process(clk)
  begin
    if rising_edge(clk) then
      case state is
        when "1011"=>
          if go='1' then
            sendbuf<=data&"0";
            state<=state-1;
          end if;
        when others=>
          if countdown=0 then
            sendbuf<="1"&sendbuf(8 downto 1);
            if state="0010" then
              countdown<= '0' & wtime(15 downto 1) ;
            else
              countdown<=wtime;
            end if;
            if state = "0001" then
              state<="1011";
            else 
              state<=state-1;
            end if;
          else
            countdown<=countdown-1;
          end if;
      end case;
    end if;
  end process;
  tx<=sendbuf(0);
  busy<= '0' when state="1011" else '1';
end blackbox;
