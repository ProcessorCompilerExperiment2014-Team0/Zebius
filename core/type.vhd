library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;


package zebius_type_p is

  type iodir_t is (DIR_WRITE, DIR_READ);
  subtype reg_data_t is unsigned(31 downto 0);

end zebius_type_p;
