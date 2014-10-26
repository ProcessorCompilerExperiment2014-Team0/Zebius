library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library work;
use work.zebius_type_p.all;

package zebius_sram_controller_p is

  subtype sram_data_t is unsigned(35 downto 0);
  subtype sram_addr_t is unsigned(21 downto 0);

  type sram_controller_in_t is record
    data : sram_data_t;
    addr : sram_addr_t;
    dir  : iodir_t;
  end record;

  type sram_controller_out_t is record
    data : sram_data_t;
  end record;

  component sram_controller is
    port (
      clk   : in  std_logic;

      zd    : inout std_logic_vector(31 downto 0);
      zdp   : inout std_logic_vector(3  downto 0);
      za    : out   std_logic_vector(19 downto 0);
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
      zza   : out std_logic;

      din   : in  sram_controller_in_t;
      dout  : out sram_controller_out_t);
  end component;

end zebius_sram_controller_p;



library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library work;
use work.zebius_type_p.all;
use work.blockram_p.all;
use work.zebius_sram_controller_p.all;



entity sram_controller is
    port (
      clk   : in  std_logic;

      zd    : inout std_logic_vector(31 downto 0);
      zdp   : inout std_logic_vector(3  downto 0);
      za    : out   std_logic_vector(19 downto 0);
      xe1   : out std_logic;
      e2a   : out std_logic;
      xe3   : out std_logic;
      xzbe  : out std_logic_vector(3 downto 0);
      xga   : out std_logic;
      xwa   : out std_logic := '1';
      xzcke : out std_logic;
      zclkma: out std_logic_vector(1 downto 0);
      adva  : out std_logic;
      xft   : out std_logic;
      xlbo  : out std_logic;
      zza   : out std_logic;

      din   : in sram_controller_in_t;
      dout  : out sram_controller_out_t);
end sram_controller;


architecture implementation of sram_controller is

  signal data1, data2 : sram_data_t;
  signal dir1 : iodir_t := DIR_READ;
  signal dir2 : iodir_t := DIR_READ;

  signal bwe : std_logic := '0';
  signal ben : std_logic;
  signal baddr : unsigned(7 downto 0) := (others => '0');
  signal bdi : unsigned(31 downto 0) := (others => '0');
  signal bdo : unsigned(31 downto 0);

  signal word_align1 : std_logic;
  signal word_align2 : std_logic;

  signal bdata2 : unsigned(31 downto 0);
  signal bbram1, bbram2 : std_logic := '0';

begin

  bram1 : blockram port map (
    clk => clk,
    we => bwe,
    en => ben,
    addr => baddr,
    di => bdi,
    do => bdo);

  ben <= '1';
  bwe <= '1' when to_integer(din.addr(21 downto 8)) = 0 and din.dir = DIR_WRITE else
         '0';
  baddr <= din.addr(9 downto 2);
  bdi <= din.data(31 downto 0);

  xe1   <= '0';
  e2a   <= '1';
  xe3   <= '0';
  xzbe   <= (others => '0');
  xga   <= '0';
  xzcke <= '0';
  zclkma(0) <= clk;
  zclkma(1) <= clk;
  adva  <= '0';
  xft   <= '1';
  zza   <= '0';
  xlbo  <= '1';
  xwa   <= '0' when din.dir = DIR_WRITE else
           '1';
  za    <= std_logic_vector(din.addr(21 downto 2));
  zdp   <= std_logic_vector(data2(35 downto 32)) when dir2 = DIR_WRITE else
           (others => 'Z');
  zd    <= std_logic_vector(data2(31 downto 0)) when dir2 = DIR_WRITE else
           (others => 'Z');
  dout.data <= x"0" & bdata2 when bbram2 = '1' and word_align2 = '0' else
               x"00000" & bdata2(31 downto 16) when bbram2 = '1' and word_align2 = '1' else
               unsigned(zdp & zd) when bbram2 = '0' and word_align2 = '0' else
               x"00000" & unsigned(zd(31 downto 16));

  process (clk)
  begin
    if rising_edge(clk) then
      word_align1 <= din.addr(1);
      word_align2 <= word_align1;
      data1 <= din.data;
      data2 <= data1;
      dir1  <= din.dir;
      dir2  <= dir1;

      if to_integer(din.addr(21 downto 8)) = 0 then
        bbram1 <= '1';
      else
        bbram1 <= '0';
      end if;
      bbram2 <= bbram1;
      bdata2 <= bdi;
    end if;
  end process;

end implementation;
