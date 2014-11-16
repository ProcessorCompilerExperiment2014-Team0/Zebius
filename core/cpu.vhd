library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library unisim;
use unisim.vcomponents.all;

library work;
use work.zebius_alu_p.all;
use work.zebius_fpu_p.all;
use work.zebius_core_p.all;
use work.zebius_sram_controller_p.all;
use work.zebius_u232c_in_p.all;
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

--  constant wtime : unsigned(15 downto 0) := x"0d80";
  -- when 4800 and 33.33: 1ae8
  constant wtime : unsigned(15 downto 0) := x"0d80";

  signal ci  : core_in_t;
  signal co  : core_out_t;

  signal clk, iclk, dclk, iclkfd, clkfd: std_logic;
  signal rst: std_logic := '0';

begin
  ib: ibufg
  port map (
    i => mclk1,
    o => iclk);

  dcm: dcm_base
    generic map (
      clk_feedback => "1X",
      clkdv_divide => 2.0,
      clkdv_divide => false,
      duty_cycle_correction => true)
    port map (
      rst => rst,
      clkin => iclk,
      clkfb => clkfd,
      clk0 => iclkfd,
      clk90 => open,
      clk180 => open,
      clk270 => open,
      clk2x => open,
      clk2x180 => open,
      clkdv => dclk,
      clkfx => open,
      clkfx180 => open);

  bg: bufg port map (
    i => iclkfd,
    o => clkfd);

  ss: bufg port map (
    i => dclk,
    o => clk);


  core : zebius_core
    port map ( clk => clk,
               ci   => ci,
               co   => co);

  alu : zebius_alu
    port map ( din  => co.alu,
               dout => ci.alu);

  fpu : zebius_fpu
    port map (
      din  => co.fpu,
      dout => ci.fpu);

  sin : u232c_in
    generic map ( wtime => wtime)
    port map ( clk => clk,
               rx => rs_rx,
					din => co.sin,
               dout => ci.sin);

  sout : u232c_out
    generic map ( wtime => wtime)
    port map ( clk => clk,
               din => co.sout,
               dout => ci.sout,
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
