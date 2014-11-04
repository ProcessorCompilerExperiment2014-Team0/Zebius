library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

package zebius_u232c_in_p is
  subtype u232c_in_id_t is integer range 0 to 15;
  constant U232C_IN_FIRST_ID : u232c_in_id_t := 15;
  function next_u232c_in_id (i: u232c_in_id_t) return u232c_in_id_t;

  type u232c_in_out_t is record
    id : u232c_in_id_t;
    data : unsigned(7 downto 0);
  end record;

  component u232c_in is
      generic (
        wtime: unsigned(15 downto 0) := x"1adb");
      port (
        clk  : in  std_logic;
        rx   : in  std_logic;
        dout : out u232c_in_out_t);
  end component;
end package;

package body zebius_u232c_in_p is
  function next_u232c_in_id (
    i: u232c_in_id_t)
    return u232c_in_id_t is
  begin
    case i is
      when 13 | 14 | 15 =>
        return 0;
      when others =>
        return i+1;
    end case;

  end function;
end package body;



library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library work;
use work.zebius_u232c_in_p.all;


entity u232c_in is
  generic (
    wtime: unsigned(15 downto 0) := x"1ADB");
  port (
    clk  : in  std_logic;
    rx   : in  std_logic;
    dout : out u232c_in_out_t := (
      id => U232C_IN_FIRST_ID,
      data => (others => '0')));
end u232c_in;


architecture behavior of u232c_in is

  type state_t is (WAITING, INIT, READING, DONE);

  type ratch_t is record
    id : u232c_in_id_t;
    buf : unsigned(7 downto 0);
    countdown : unsigned(15 downto 0);
    state : state_t;
    idx : integer range 0 to 7;
  end record;

  signal r : ratch_t := (
    id => U232C_IN_FIRST_ID,
    buf => (others => '1'),
    countdown => (others => '0'),
    state => WAITING,
    idx => 0);

begin

  statemachine: process(clk)
    variable v : ratch_t;
  begin
    if rising_edge(clk) then
      v := r;

      case v.state is
        when WAITING =>
          if rx='0' and v.countdown = 0 then
            v.state  := INIT;
            v.countdown := shift_right(unsigned(wtime), 1);
          elsif v.countdown /= 0 then
            v.countdown := v.countdown-1;
          end if;

        when INIT =>
          if v.countdown = 0 then
            if rx = '0' then
              v.state := READING;
              v.idx := 0;
              v.countdown := wtime;
            else
              v.state := WAITING;
            end if;
          elsif v.countdown /= 0 then
            v.countdown := v.countdown-1;
          end if;

        when READING =>
          if v.countdown = 0 then
            v.buf := rx & v.buf(7 downto 1);
            v.countdown := wtime;
            if v.idx /= 7 then
              v.idx := v.idx+1;
            else
              v.state := DONE;
            end if;
          else
            v.countdown := v.countdown-1;
          end if;

        when DONE =>
          v.id := next_u232c_in_id(v.id);

          dout.data <= v.buf;
          dout.id <= v.id;

          v.state := waiting;
      end case;

      r <= v;
    end if;
  end process;

end behavior;
