library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library work;

package zebius is

  -- common data
  subtype reg_data_t is unsigned(31 downto 0);

  -- zebius_core
  type zebius_inst_t is record
    a : unsigned(3 downto 0);
    b : unsigned(3 downto 0);
    c : unsigned(3 downto 0);
    d : unsigned(3 downto 0);
  end record;

  function zebius_inst(inst : std_logic_vector(15 downto 0))
    return zebius_inst_t;

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
  subtype sram_data_t is unsigned(35 downto 0);
  subtype sram_addr_t is unsigned(19 downto 0);

  type sram_controller_in_t is record
    data : sram_data_t;
    addr : sram_addr_t;
    dir  : sram_dir_t;
    go   : std_logic;
  end record;

  type sram_controller_out_t is record
    data : sram_data_t;
    busy : std_logic;
  end record;

end zebius;

package body zebius is
  function zebius_inst(inst : std_logic_vector(15 downto 0))
    return zebius_inst_t is
  variable v : zebius_inst_t;
  begin
    v.a := unsigned(inst(15 downto 12));
    v.b := unsigned(inst(11 downto 8));
    v.c := unsigned(inst( 7 downto 4));
    v.d := unsigned(inst( 3 downto 0));
    return v;
  end;
end zebius;
