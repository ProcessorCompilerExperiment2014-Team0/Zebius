library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library work;

package zebius is

  -- common data
  subtype reg_data_t is unsigned(31 downto 0);

  -- zebius_alu
  subtype alu_inst_t is unsigned(3 downto 0);

  type alu_in_t is record
    inst : alu_inst_t;
    i1   : reg_data_t;
    i2   : reg_data_t;
  end record;

  type alu_out_t is record
    o : reg_data_t;
  end record;

  -- zebius_sram_controller
  type    sram_dir_t  is (SRAM_DIR_WRITE, SRAM_DIR_READ);
  subtype sram_data_t is unsigned(35 donwto 0);
  subtype sram_addr_t is unsigned(19 donwto 0);

  type sram_controller_in_t is record
    data : sram_data_t;
    addr : sram_addr_t;
    dir  : sram_dir_t;
    go   : std_logic;
  end record;

  type sram_controller_out_t is record
    data : out sram_data_t;
    busy : out std_logic;
  end record;

end zebius;
