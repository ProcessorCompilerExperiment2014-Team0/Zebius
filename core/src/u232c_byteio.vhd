library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;

entity u232c_byteio is
  generic (wtime: std_logic_vector(15 downto 0) := x"1C06");
  port (clk   : in  std_logic;
        rs_rx : in  std_logic;
        rs_tx : out std_logic);
end u232c_byteio;

architecture structure of u232c_byteio is

  component u232c_in is
    generic (wtime: std_logic_vector(15 downto 0) := wtime);
    port (clk  : in  std_logic;
          data : out std_logic_vector (7 downto 0);
          go   : out std_logic;
          rx   : in  std_logic);
  end component;
  component u232c_out is
    generic (wtime: std_logic_vector(15 downto 0) := wtime);
    port (clk  : in  std_logic;
          data : in  std_logic_vector (7 downto 0);
          go   : in  std_logic;
          busy : out std_logic;
          tx   : out std_logic);    
  end component;

  signal in_go    : std_logic := '0';
  signal out_go   : std_logic := '0';
  signal out_busy : std_logic := '0';

  signal comflag : std_logic := '0';
  signal i, o   : std_logic_vector(7 downto 0);
  type state is (ready, wait1, wait2 ,busy);
  signal in_st  : state := ready;
  signal out_st : state := ready;

  signal debug_in_st  : std_logic_vector(1 downto 0);
  signal debug_out_st : std_logic_vector(1 downto 0);
begin
  rs232c_in : u232c_in generic map (wtime=>wtime)
  port map (
    clk  => clk,
    data => i,
    go   => in_go,
    rx   => rs_rx);
  rs232c_out : u232c_out generic map (wtime=>wtime)
  port map (
    clk  => clk,
    data => o,
    go   => out_go,
    busy => out_busy,
    tx   => rs_tx);

  send_msg: process(clk)
    begin
    if rising_edge(clk) then
      if in_go = '1' then
        comflag <= '1';
        o <= i+1;
      end if;
      if out_busy = '0' and out_go='0' and comflag = '1' then
        out_go  <='1';
        comflag <= '0';        
      else
        out_go<='0';
      end if;
    end if;
  end process;

  debug_in_st <= "00" when in_st = ready else
                 "10" when in_st = busy;
end structure;
