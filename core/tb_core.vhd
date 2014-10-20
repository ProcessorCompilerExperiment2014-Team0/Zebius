library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library work;
use work.sramsim.all;
use work.zebius_p.all;
use work.zebius_component_p.all;

entity tb_core is
end tb_core;

architecture testbench of tb_core is

  signal clk : std_logic;
  signal ci  : core_in_t;
  signal co  : core_out_t;

  signal rs_tx : std_logic;

  signal zd    : std_logic_vector(31 downto 0);
  signal zdp   : std_logic_vector(3  downto 0);
  signal za    : std_logic_vector(19 downto 0);
  signal xe1   : std_logic;
  signal e2a   : std_logic;
  signal xe3   : std_logic;
  signal xzbe  : std_logic_vector(3 downto 0);
  signal xga   : std_logic;
  signal xwa   : std_logic;
  signal xzcke : std_logic;
  signal zclkma: std_logic_vector(1 downto 0);
  signal adva  : std_logic;
  signal xft   : std_logic;
  signal xlbo  : std_logic;
  signal zza   : std_logic;

begin

  core : zebius_core
    port map ( clk => clk,
               ci  => ci,
               co  => co);

  alu : zebius_alu
    port map ( din  => co.alu,
               dout => ci.alu);

  sout : u232c_out
    generic map ( wtime => x"0005" )
    port map ( clk  => clk,
               data => co.sout.data,
               go   => co.sout.go,
               busy => ci.sout.busy,
               tx   => rs_tx);

  controller : sram_controller
    port map ( clk   => clk,

               zd    => zd,
               zdp   => zdp,
               za    => za,
               xe1   => xe1,
               e2a   => e2a,
               xe3   => xe3,
               xzbe  => xzbe,
               xga   => xga,
               xwa   => xwa,
               xzcke => xzcke,
               zclkma=> zclkma,
               adva  => adva,
               xft   => xft,
               xlbo  => xlbo,
               zza   => zza,
               
               din   => co.sram,
               dout  => ci.sram);
  
  sram : GS8160Z18
    port map ( A => ZA,
               CK => ZCLKMA(1),
               XBA => XZBE(2),
               XBB => XZBE(3),
               XW => XWA,
               XE1 => XE1,
               E2 => E2A,
               XE3 => XE3,
               XG => XGA,
               ADV => ADVA,
               XCKE => XZCKE,
               DQA => ZD(23 downto 16),
               DQB => ZD(31 downto 24),
               DQPA => ZDP(2),
               DQPB => ZDP(3),
               ZZ => ZZA,
               XFT => XFT,
               XLBO => XLBO); -- Linear Byte Order

  clockgen: process
  begin
    clk <= '0';
    wait for 5 ns;
    clk <= '1';
    wait for 5 ns;
  end process;

end testbench;
