library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library unisim;
use unisim.vcomponents.all;

entity sram_controller is
    port ( zd    : inout std_logic_vector(31 downto 0);
           zdp   : inout std_logic_vector(3  downto 0);
           za    : out    std_logic_vector(19 downto 0);
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

           input : in  std_logic_vector(35 downto 0);
           output: out std_logic_vector(35 downto 0);
           addr  : in  std_logic_vector(19 downto 0);
           wdir  : in  std_logic;
           go    : in  std_logic;
           busy  : out std_logic;
           clk   : in  std_logic);
end sram_controller;

architecture implementation of sram_controller is
  type sram_state is (sram_wait, sram_read, sram_write);
  signal state : sram_state := sram_wait;
  signal count : integer := 100;
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

  busy <= '0' when state = sram_wait else
          '1';
  
  process (clk)
  begin
    if (rising_edge(clk)) then
      case state is
        when sram_wait =>
          if go = '1' then
            za  <= addr;
            output <= "111100001111000011110000111100001111";
            if (wdir = '1') then
              xwa <= '0';
              zd  <= input(31 downto 0);
              zdp <= input(35 downto 32);
              state <= sram_write;
            else
              xwa <= '1';
              zd <= (others => 'Z');
              zdp <= (others => 'Z');
              state <= sram_read;
            end if;
          end if;

        when sram_read | sram_write =>
          if count = 0 then
            state <= sram_wait;
            count <= 100;
            if state = sram_read then
              output <= zdp & zd;
            end if;
          else
            count <= count-1;
          end if;
      end case;
    end if;
  end process;
end implementation;
