library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library work;
use work.zebius_p.all;
use work.zebius_component_p.all;

entity sram_controller is
    port ( clk   : in  std_logic;

           zd    : inout std_logic_vector(31 downto 0) := x"0f0f0f0f";
           zdp   : inout std_logic_vector(3  downto 0) := x"f";
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

  type ratch_t is record
    data_delay1 : sram_data_t;
    data_delay2 : sram_data_t;
  end record;

  signal r, rin : ratch_t;

begin

  xe1   <= '0';
  e2a   <= '1';
  xe3   <= '0';
  xzbe   <= "0000";
  xga   <= '0';
  xzcke <= '0';
  zclkma(0) <= clk;
  zclkma(1) <= clk;
  adva  <= '0';
  xft   <= '1';  
  zza   <= '0';
  xlbo  <= '1';
  
  process (din)
    variable v : ratch_t := r;
  begin
    case din.dir is
      when DIR_WRITE =>
        rin.data_delay1 := din.data;
        za <= din.addr;
        wa <= 
  
      when DIR_READ =>
        rin.data_delay1 := x"zzzzzzzzz";
        za <= din.addr;
        wa <= 

    end case;

    rin <= r;
  end process;

  process (clk)
  begin

  end process;

end implementation;
