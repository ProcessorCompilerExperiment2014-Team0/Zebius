library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;

entity u232c_byteio_tb is
end u232c_byteio_tb;

architecture test of u232c_byteio_tb is
  constant wave : std_logic_vector(19 downto 0) := "10101010101101010100";
  component u232c_byteio is
    generic (wtime : std_logic_vector(15 downto 0));
    port (clk   : in  std_logic;
          rs_rx : in  std_logic;
          rs_tx : out std_logic);
  end component;

  signal rx, tx  : std_logic;
  signal clk : std_logic;
  signal cnt     : std_logic_vector(8 downto 0) := "000000000";
begin
  rs232c : u232c_byteio generic map (wtime => x"000F")
  port map (clk => clk,
            rs_rx  => rx,
            rs_tx  => tx);

  read: process(clk)
  begin
    if rising_edge(clk) then
      if cnt = "100111111" then
        cnt <= "000000000";
      else
        cnt <= cnt+1;
      end if;
      rx <= wave(conv_integer(cnt(8 downto 4)));
    end if;
  end process;

  clockgen: process
  begin
    clk <= '0';
    wait for 5 ns;
    clk <= '1';
    wait for 5 ns;
  end process;
end test;
