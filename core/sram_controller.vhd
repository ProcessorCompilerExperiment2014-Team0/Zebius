library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library work;
use work.zebius_type_p.all;

package zebius_sram_controller_p is

  subtype sram_data_t is unsigned(35 downto 0);
  subtype sram_addr_t is unsigned(19 downto 0);

  type sram_controller_in_t is record
    data : sram_data_t;
    addr : sram_addr_t;
    dir  : iodir_t;
  end record;

  type sram_controller_out_t is record
    data : sram_data_t;
  end record;

  component sram_controller is
    port ( clk   : in  std_logic;

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
use work.zebius_sram_controller_p.all;

use work.zebius_type_p.all;


entity sram_controller is
    port ( clk   : in  std_logic;

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

begin

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
  za    <= std_logic_vector(din.addr);
  zdp   <= std_logic_vector(data2(35 downto 32)) when dir2 = DIR_WRITE else
           (others => 'Z');
  zd    <= std_logic_vector(data2(31 downto 0)) when dir2 = DIR_WRITE else
           (others => 'Z');
  dout.data <= unsigned(zdp & zd);

  process (clk)
  begin
    if rising_edge(clk) then
      data1 <= din.data;
      data2 <= data1;
      dir1  <= din.dir;
      dir2  <= dir1;
    end if;
  end process;

end implementation;
