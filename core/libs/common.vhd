library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library work;

package zebius is

  -- common data
  subtype reg_data is unsigned(31 downto 0);

  -- zebius_alu
  type alu_in is record
    inst : std_logic_vector(3 downto 0);
    i1 : reg_data;
    i2 : reg_data;
  end record;

  type alu_out is record
    o : reg_data;
  end record;

end zebius;

