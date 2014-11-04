library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.std_logic_textio.all;

library std;
use std.textio.all;

library work;
use work.sramsim.all;
use work.zebius_alu_p.all;
use work.zebius_fpu_p.all;
use work.zebius_core_p.all;
use work.zebius_sram_controller_p.all;
use work.zebius_u232c_in_p.all;
use work.zebius_u232c_out_p.all;
use work.zebius_type_p.all;


entity tb_core is
end tb_core;


architecture testbench of tb_core is

  file ifile : text open read_mode is "input";
  signal cnt : unsigned(15 downto 0) := (others => '0');
  signal idx : integer range -1 to 8 := 8;
  signal data : unsigned(7 downto 0) := (others => '0');


  constant wtime : unsigned(15 downto 0) := x"0010";

  signal clk : std_logic;
  signal ci  : core_in_t;
  signal co  : core_out_t := (
    alu => (
      inst => ALU_INST_NOP,
      i1 => (others => '0'),
      i2 => (others => '0')),
    fpu => (
      inst => FPU_INST_NOP,
      i1 => (others => '0'),
      i2 => (others => '0')),
    sout => (
      data => (others => '0'),
      go => '0'),
    sram => (
      data => (others => '0'),
      addr => (others => '0'),
      dir => DIR_READ));

  signal rx : std_logic;
  signal tx : std_logic;

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
    generic map (
      enable_log => false)
    port map (
      clk => clk,
      ci  => ci,
      co  => co);

  alu : zebius_alu
    port map (
      din  => co.alu,
      dout => ci.alu);

  fpu : zebius_fpu
    port map (
      din  => co.fpu,
      dout => ci.fpu);

  sin : u232c_in
    generic map (
      wtime => wtime)
    port map (
      clk => clk,
      rx => rx,
      dout => ci.sin);

  sout : u232c_out
    generic map (
      report_write => true,
      wtime => wtime)
    port map (
      clk  => clk,
      tx   => tx,
      din  => co.sout,
      dout => ci.sout);

  controller : sram_controller
    port map (
      clk   => clk,

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

  sram_unit0 : GS8160Z18
    generic map (
      report_read => false,
      report_write => false)
    port map (
      a => za,
      ck => zclkma(0),
      xba => xzbe(0),
      xbb => xzbe(1),
      xw => xwa,
      xe1 => xe1,
      e2 => e2a,
      xe3 => xe3,
      xg => xga,
      adv => adva,
      xcke => xzcke,
      dqa => zd(7 downto 0),
      dqb => zd(15 downto 8),
      dqpa => zdp(0),
      dqpb => zdp(1),
      zz => zza,
      xft => xft,
      xlbo => xlbo);

  sram_unit1 : GS8160Z18
    port map (
      a => za,
      ck => zclkma(1),
      xba => xzbe(2),
      xbb => xzbe(3),
      xw => xwa,
      xe1 => xe1,
      e2 => e2a,
      xe3 => xe3,
      xg => xga,
      adv => adva,
      xcke => xzcke,
      dqa => zd(23 downto 16),
      dqb => zd(31 downto 24),
      dqpa => zdp(2),
      dqpb => zdp(3),
      zz => zza,
      xft => xft,
      xlbo => xlbo);

  readfile: process(clk)
    variable l : line;
    variable byte : std_logic_vector(7 downto 0);
  begin
    if rising_edge(clk) then
      if cnt = 0 then
        cnt <= wtime;

        case idx is
          when -1 =>
            rx <= '0';
            idx <= 0;
          when 8 =>
            if not endfile(ifile) then
              rx <= '1';
              idx <= -1;
              readline(ifile, l);
              hread(l, byte);
              data <= unsigned(byte);
            end if;
          when others =>
            rx <= data(idx);
            idx <= idx+1;
        end case;
      else
        cnt <= cnt - 1;
      end if;
    end if;
  end process;

  clockgen: process
  begin
    clk <= '0';
    wait for 5 ns;
    clk <= '1';
    wait for 5 ns;
  end process;

end testbench;
