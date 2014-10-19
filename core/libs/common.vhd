library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library work;

package zebius_p is

  -- config
  constant debug_mode : boolean := false;

  function set_u232c_wtime (debug : boolean) return std_logic_vector;
  
  -- common data
  type wdir_t is (DIR_WRITE, DIR_READ);
  subtype reg_data_t is unsigned(31 downto 0);

  -- zebius_core
  type zebius_inst_t is record
    a : unsigned(3 downto 0);
    b : unsigned(3 downto 0);
    c : unsigned(3 downto 0);
    d : unsigned(3 downto 0);
  end record;

  -- utility
  function zebius_inst(inst : std_logic_vector(15 downto 0))
    return zebius_inst_t;

  function signed_resize(n : unsigned;
                         size : natural)
    return unsigned;

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

end zebius_p;



package body zebius_p is

  function set_u232c_wtime (debug : boolean) return std_logic_vector is
  begin
    if debug then return x"0004"; else return x"1adb"; end if;
  end function;

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

  function signed_resize(n : unsigned;
                         size : natural)
    return unsigned  is

    alias m : unsigned(n'length-1 downto 0) is n;
    variable sn : signed(n'length-1 downto 0);
    variable esn : signed(size-1 downto 0);

  begin
    sn := signed(std_logic_vector(m));
    esn := resize(sn, size);
    return unsigned(std_logic_vector(esn));
  end;

end zebius_p;
