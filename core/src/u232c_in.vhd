library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity u232c_in is
  generic (wtime: std_logic_vector(15 downto 0) := x"1ADB");
  port (clk   : in  std_logic;
        go    : out std_logic := '0';
        data  : out std_logic_vector (7 downto 0);
        rx    : in  std_logic);
end u232c_in;

architecture blackbox of u232c_in is
  signal buf       : std_logic_vector(7 downto 0)  := (others=>'1');
  signal countdown : unsigned(15 downto 0) := (others=>'0');

  type   state is (waiting, init, reading, done);
  signal st        : state := waiting;
  signal idx       : unsigned(2 downto 0) := "000";
  signal debug_st  : std_logic_vector(1 downto 0);
begin
  statemachine: process(clk)
  begin
    if rising_edge(clk) then
      case st is
        when waiting =>
          go <= '0';            
          if rx='0' and countdown = 0 then
            st  <= init;
            countdown <= shift_right(unsigned(wtime), 3);
          elsif countdown /= 0 then
            countdown <= countdown-1;
          end if;
        when init =>
          if countdown = 0 then
            if rx = '0' then
              st <= reading;
              idx <= "000";
              countdown <= unsigned(wtime);
            else
              st <= waiting;
            end if;
          elsif countdown /= 0 then
            countdown <= countdown-1;
          end if;
        when reading =>
          if countdown = 0 then
            buf <= rx & buf(7 downto 1);
            countdown <= unsigned(wtime);
            if idx /= 7 then
              idx <= idx+1;
            else
              st <= done;
            end if;
          else
            countdown <= countdown-1;
          end if;
        when done =>
          data <= buf;
          go   <= '1';
          st <= waiting;
      end case;
    end if;
  end process;

  debug_st <= "00" when st = waiting else
              "01" when st = init else
              "10" when st = reading else
              "11" when st = done;
end blackbox;
