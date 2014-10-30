library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

package zebius_u232c_in_p is

  type u232c_in_in_t is record
    take : std_logic;
  end record;

  type u232c_in_out_t is record
    ready : std_logic;
    data : unsigned(7 downto 0);
  end record;

  component u232c_in is
      generic (
        wtime: unsigned(15 downto 0) := x"1ADB");
      port (
        clk  : in  std_logic;
        rx   : in  std_logic;
        din  : in  u232c_in_in_t;
        dout : out u232c_in_out_t);
  end component;

end package;



library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library work;
use work.zebius_u232c_in_p.all;


entity u232c_in is
  generic (
    wtime: unsigned(15 downto 0) := x"1ADB");
  port (
    clk   : in  std_logic;
    rx   : in  std_logic;
    din  : in  u232c_in_in_t;
    dout : out u232c_in_out_t);
end u232c_in;


architecture blackbox of u232c_in is

  type state is (waiting, reading, done);

  type ratch_t is record
    -- interface
    ready : std_logic;
    buf : unsigned(7 downto 0);
    -- receive
    recvbuf : unsigned(7 downto 0);
    countdown : unsigned(15 downto 0);
    st : state;
    idx : integer range -1 to 7;
  end record;

  signal r, rin : ratch_t := (
    ready => '0',
    buf => (others => '-'),
    recvbuf => (others => '0'),
    countdown => wtime,
    st => waiting,
    idx => 0);

begin

  combinational: process(r, rx, din)
    variable v : ratch_t;
  begin
    v := r;

    case v.st is
      when WAITING =>
        if rx = '0' then
          v.st := READING;
          v.countdown := shift_right(unsigned(wtime), 1);
          v.idx := -1;
        end if;
      when others => null;
    end case;

    if din.take = '1' then
      v.ready := '0';
    end if;

    dout.ready <= v.ready;

    rin <= v;
  end process;

  sequential: process(clk)
    variable v : ratch_t;
  begin
    if rising_edge(clk) then
      v := rin;

      case v.st is
        when READING =>
          if v.countdown = 0 then
            v.recvbuf := rx & v.recvbuf(7 downto 1);
            v.countdown := wtime;

            if v.idx /= 7 then
              v.idx := v.idx+1;
            else
              assert v.ready = '0' report "buffered byte is not still read. This byte will be abondoned.";

              v.st := DONE;
              v.buf := v.recvbuf;
              v.ready := '1';

              dout.data <= v.buf;
            end if;
          else
            v.countdown := v.countdown-1;
          end if;

        when DONE =>
          if v.countdown = 0 then
            v.st := WAITING;
          else
            v.countdown := v.countdown-1;
          end if;

        when others => null;
      end case;

      r <= v;
    end if;
  end process;
end blackbox;
