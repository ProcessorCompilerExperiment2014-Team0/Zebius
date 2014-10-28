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

  signal bin : blockram_in_t := (
    en => '1',
    we => '0',
    addr => (others => '1'),
    data => (others => '1'));
  signal bout : blockram_out_t;

  type ratch_t is record
    -- common
    word_align0, word_align1, word_align2 : boolean;
    -- sram
    data0, data1, data2 : sram_data_t;
    dir0, dir1, dir2 : iodir_t;
    -- blockram
    be0, be1, be2 : boolean;
    bdata1, bdata2 : unsigned(31 downto 0);
  end record;

  signal r, rin : ratch_t;


  function is_blockram_addr (addr : sram_addr_t)
    return boolean is
  begin
    return to_integer(shift_right(addr, 10)) = 0;
  end function;

begin

  bram1 : blockram port map (
    clk => clk,
    din => bin,
    dout => bout);

  bin.en <= '1';
  bin.we <= '0';

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

  process (din, bout, r, zd, zdp)
    variable v : ratch_t;
    variable data : sram_data_t;
  begin
    v := r;
    v.word_align0 := din.addr(1) = '1';

    -- read/write operation
    if is_blockram_addr(din.addr) then
      assert din.dir = DIR_READ report "blockram is read-only" severity WARNING;
      v.be0 := true;
      bin.addr <= din.addr(9 downto 2);
    else
      v.be0 := false;
      za <= std_logic_vector(din.addr(21 downto 2));

      if din.dir = DIR_READ then
        xwa <= '1';
      else
        xwa <= '0';
      end if;

      v.dir0 := din.dir;
      v.data0 := din.data;
    end if;

    dout.data <= data;

    -- process memory output
    if v.be1 then
      v.bdata1 := bout.data;
    else
      v.bdata1 := (others => '1');
    end if;

    if v.be2 then
      data := "0000" & v.bdata2;
    elsif v.dir2 = DIR_READ then
      data := unsigned(zdp & zd);
    else
      data := (others => '1');
    end if;

    if v.word_align2 then
      data := resize(data(31 downto 16), 36);
    end if;

    dout.data <= data;

    rin <= v;
  end process;


  process (clk)
    variable v : ratch_t;
  begin
    if rising_edge(clk) then
      v := rin;

      v.be0 := false;
      v.dir0 := DIR_READ;
      v.data0 := (others => '1');
      v.word_align0 := false;

      v.word_align1 := rin.word_align0;
      v.word_align2 := rin.word_align1;

      -- blockram
      v.be1 := rin.be0;
      v.be2 := rin.be1;
      v.bdata2 := rin.bdata1;

      -- sram
      v.data1 := rin.data0;
      v.data2 := rin.data1;
      v.dir1 := rin.dir0;
      v.dir2 := rin.dir1;

      if v.dir2 = DIR_READ then
        zdp <= (others => 'Z');
        zd <= (others => 'Z');
      else
        zdp <= std_logic_vector(v.data2(35 downto 32));
        zd <= std_logic_vector(v.data2(31 downto 0));
      end if;

      r <= v;
    end if;
  end process;

end implementation;
