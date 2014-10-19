library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity coretb is
end coretb;

architecture testbench of coretb is

  component zebius_core
    port ( clk : in  std_logic;
           i   : in  core_in_t;
           o   : out core_out_t);
  end component;

  component zebius_alu
    port ( clk  : in  std_logic;
           din  : in  alu_in_t;
           dout : out alu_out_t);
  end component;
  
  component u232c_out
    generic ( wtime: std_logic_vector(15 downto 0));
    port ( clk  : in  std_logic;
           data : in  std_logic_vector (7 downto 0);
           go   : in  std_logic;
           busy : out std_logic;
           tx   : out std_logic);
  end component;

  signal clk : std_logic;
  signal ci  : core_in_t;
  signal co  : core_out_t;

  signal rs_tx : std_logic;

begin

  core : zebius_core
    port map ( clk => clk,
               i   => ci,
               o   => co);

  alu : zebius_alu
    port map ( din  => co.alu,
               dout => ci.alu);

  sout : u232c_out
    generic map ( wtime => x"0005" )
    port map ( clk  => clk;
               data => co.sout.data;
               go   => co.sout.go;
               busy => ci.sout.busy;
               tx   => rs_tx;

  clockgen: process
  begin
    clk <= '0';
    wait for 5 ns;
    clk <= '1';
    wait for 5 ns;
  end process;

end testbench;
