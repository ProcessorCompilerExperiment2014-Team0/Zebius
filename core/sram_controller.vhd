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

  dout.busy <= '0' when state = SRAM_WAIT else
               '1';
  
  process (clk)
  begin
    if rising_edge(clk) then
      case state is
        when SRAM_WAIT =>
          if din.go = '1' then
            za  <= std_logic_vector(din.addr);
            dout.data <= x"f0f0f0f0f";

            case din.dir is
              when DIR_WRITE =>
                xwa <= '0';
                zd  <= std_logic_vector(din.data(31 downto 0));
                zdp <= std_logic_vector(din.data(35 downto 32));
                state <= SRAM_WRITE;

              when DIR_READ =>
                xwa <= '1';
                zd  <= (others => 'Z');
                zdp <= (others => 'Z');
                state <= SRAM_READ;

            end case;
          end if;

        when SRAM_READ | SRAM_WRITE =>
          if count = 0 then
            state <= SRAM_WAIT;
            count <= 5;
            xwa <= '1';

            if state = SRAM_READ then
              dout.data <= unsigned(std_logic_vector'(zdp & zd));
            end if;
          else
            count <= count-1;
          end if;

      end case;
    end if;
  end process;
end implementation;
