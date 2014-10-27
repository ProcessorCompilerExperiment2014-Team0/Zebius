library ieee;
use ieee.std_logic_1164.all;

library unisim;
use unisim.vcomponents.all;

library work;
use work.zebius_alu_p.all;
use work.zebius_core_p.all;
use work.zebius_sram_controller_p.all;
use work.zebius_u232c_out_p.all;


entity cpu is
    port ( mclk1 : in  std_logic;

           rs_rx : in  std_logic;
           rs_tx : out std_logic;

           zd    : inout std_logic_vector(31 downto 0);
           zdp   : inout std_logic_vector(3  downto 0);
           za    : out std_logic_vector(19 downto 0);
           xe1   : out std_logic;
           e2a   : out std_logic;
           xe3   : out std_logic;
           xzbe  : out std_logic_vector(3 downto 0);
           xga   : out std_logic;
           xwa   : out std_logic;
           xzcke : out std_logic;
           zclkma: out std_logic_vector(1 downto 0);
           adva  : out std_logic;
           xft   : out std_logic;
           xlbo  : out std_logic;
           zza   : out std_logic);
end cpu;


architecture behavior of cpu is

  signal ci  : core_in_t;
  signal co  : core_out_t;

  signal clk,iclk: std_logic;
  
begin
  ib: ibufg
  port map (
    i => mclk1,
    o => iclk);

  bg: bufg
  port map (
    i => iclk,
    o => clk);

  core : zebius_core
    port map ( clk => clk,
               ci   => ci,
               co   => co);

  alu : zebius_alu
    port map ( din  => co.alu,
               dout => ci.alu);

  sout : u232c_out
    generic map ( wtime => x"1ADB" )
    port map ( clk  => clk,
               data => co.sout.data,
               go   => co.sout.go,
               busy => ci.sout.busy,
               tx   => rs_tx);

  sram : sram_controller
    port map ( clk => clk,

               zd     => zd,
               zdp    => zdp,
               za     => za,
               xe1    => xe1,
               e2a    => e2a,
               xe3    => xe3,
               xzbe   => xzbe,
               xga    => xga,
               xwa    => xwa,
               xzcke  => xzcke,
               zclkma => zclkma,
               adva   => adva,
               xft    => xft,
               xlbo   => xlbo,
               zza    => zza,

               din    => co.sram,
               dout   => ci.sram);

end behavior;
