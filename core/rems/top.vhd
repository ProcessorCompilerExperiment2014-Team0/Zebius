library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library unisim;
use unisim.vcomponents.all;

entity top is
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
end top;

architecture implementation of top is
  signal clk, iclk: std_logic;
  
  component sram_controller is
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
           addr  : in    std_logic_vector(19 downto 0);
           wdir  : in    std_logic;
           go    : in    std_logic;
           busy  : out   std_logic;
           clk   : in    std_logic);
  end component;

  signal sram_data : std_logic_vector(35 downto 0) := (others => '0');
  signal addr      : std_logic_vector(19 downto 0) := (others => '0');
  signal wdir      : std_logic := '0';
  signal sram_go   : std_logic := '0';
  signal sram_busy : std_logic := '0';

  component u232c
    generic (wtime: std_logic_vector(15 downto 0) := x"1ADB");
    Port ( clk  : in  std_logic;
           data : in  std_logic_vector (7 downto 0);
           go   : in  std_logic;
           busy : out std_logic;
           tx   : out std_logic);
  end component;

  signal input, output : std_logic_vector(35 downto 0) := (others => '0');

  signal rom_o : std_logic_vector(7 downto 0) := "11000011";
  signal uart_go : std_logic := '0';
  signal uart_busy : std_logic := '0';

  type state is (st_write, st_read);
  signal st : state := st_write;

  type  write_state is (wr_write, wr_wait);
  signal wst: write_state := wr_write;

  type  read_state is (rd_load, rd_lwait, rd_write, rd_wwait);
  signal rst: read_state := rd_load;
  
  signal count : unsigned(19 downto 0) := (others => '0');
begin
  -- clockgen
  ib: ibufg port map (
    i => mclk1,
    o => iclk);
  bg: bufg port map (
    i => iclk,
    o => clk);

  sram: sram_controller
    port map (
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

      input  => input,
      output => output,
      addr   => addr,
      wdir   => wdir,
      go     => sram_go,
      busy   => sram_busy,
      clk    => clk);

  rs232c: u232c generic map (wtime=>x"1ADB")
    port map (
      clk => clk,
      data=> rom_o,
      go  => uart_go,
      busy=> uart_busy,
      tx  => rs_tx);

  doit: process (clk)
  begin
    if rising_edge(clk) then
      case st is
        when st_write =>
          case wst is
            when wr_write =>
              if sram_go = '0' and sram_busy = '0' then
                addr    <= std_logic_vector(count);
                input   <= "0000000000000000" & std_logic_vector(count);
                sram_go <= '1';
                wdir    <= '1';
                wst <= wr_wait;
              end if;

            when wr_wait =>
              sram_go <= '0';
              if sram_busy = '0' then
                if count = "11111111111111111111" then
                  count <= "00000000000000000000";
                  st <= st_read;
                else
                  count <= count+1;
                end if;
              end if;
          end case;

        when st_read =>
          case rst is
            when rd_load =>
              if sram_go = '0' and sram_busy ='0' then
                addr <= std_logic_vector(count);
                sram_go <= '1';
                wdir <= '0';
                rst <= rd_lwait;
              end if;

            when rd_lwait =>
              sram_go <= '0';
              if sram_busy = '0' then
                rst <= rd_write;
              end if;

            when rd_write =>
              rom_o <= output(7 downto 0);
              if uart_go = '0' and uart_busy = '0' then
                uart_go <= '1';
                rst <= rd_wwait;
              end if;

            when rd_wwait =>
              uart_go <= '0';
              if uart_busy = '0' then
                rst <= rd_load;
                if count = "11111111111111111111" then
                  st <= st_write;
                  count <= "00000000000000000000";
                else
                  count <= count+1;
                end if;
              end if;
		  end case;
      end case;
    end if;
  end process;
end implementation;
