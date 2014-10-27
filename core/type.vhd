library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;


package zebius_type_p is

  type iodir_t is (DIR_WRITE, DIR_READ);
  subtype reg_data_t is unsigned(31 downto 0);

  type zebius_inst_t is record
    a : unsigned(3 downto 0);
    b : unsigned(3 downto 0);
    c : unsigned(3 downto 0);
    d : unsigned(3 downto 0);
  end record;

  function zebius_inst(
    inst : unsigned(15 downto 0))
    return zebius_inst_t;

end zebius_type_p;


package body zebius_type_p is

  function zebius_inst(
    inst : unsigned(15 downto 0))
    return zebius_inst_t is

  variable i : zebius_inst_t;

  begin
    i.a := inst(15 downto 12);
    i.b := inst(11 downto 8);
    i.c := inst(7 downto 4);
    i.d := inst(3 downto 0);

    return i;
  end function;

end zebius_type_p;
