library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library work;
use work.zebius_p.all;

package zebius_component_p is

  -- alu
  subtype alu_inst_t is unsigned(3 downto 0);

  type alu_in_t is record
    inst : alu_inst_t;
    i1   : reg_data_t;
    i2   : reg_data_t;
  end record;

  type alu_out_t is record
    o : reg_data_t;
  end record;

  
  -- u232c_out
  type u232c_out_in_t is record
    data : std_logic_vector (7 downto 0);
    go   : std_logic;
  end record;

  type u232c_out_out_t is record
    busy : std_logic;
  end record;


  -- zebius_sram_controller
  subtype sram_data_t is unsigned(35 downto 0);
  subtype sram_addr_t is unsigned(19 downto 0);

  type sram_controller_in_t is record
    data : sram_data_t;
    addr : sram_addr_t;
    dir  : iodir_t;
    go   : std_logic;
  end record;

  type sram_controller_out_t is record
    data : sram_data_t;
    busy : std_logic;
  end record;


  -- core
  type core_in_t is record
    alu  : alu_out_t;
    sout : u232c_out_out_t;
  end record;

  type core_out_t is record
    alu  : alu_in_t;
    sout : u232c_out_in_t;
  end record;
  
end zebius_component_p;
