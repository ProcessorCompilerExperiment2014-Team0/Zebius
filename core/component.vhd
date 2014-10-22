library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library work;
use work.zebius_p.all;

package zebius_component_p is

  -- alu
  type alu_in_t is record
    inst : alu_inst_t;
    i1   : reg_data_t;
    i2   : reg_data_t;
  end record;

  type alu_out_t is record
    o : reg_data_t;
  end record;

  component zebius_alu
    port ( din  : in  alu_in_t;
           dout : out alu_out_t);
  end component;


  -- u232c_out
  type u232c_out_in_t is record
    data : std_logic_vector (7 downto 0);
    go   : std_logic;
  end record;

  type u232c_out_out_t is record
    busy : std_logic;
  end record;

  component u232c_out
    generic ( wtime: std_logic_vector(15 downto 0));
    port ( clk  : in  std_logic;
           data : in  std_logic_vector (7 downto 0);
           go   : in  std_logic;
           busy : out std_logic;
           tx   : out std_logic);
  end component;


  -- zebius_sram_controller
  subtype sram_data_t is unsigned(35 downto 0);
  subtype sram_addr_t is unsigned(19 downto 0);

  type sram_controller_in_t is record
    data : sram_data_t;
    addr : sram_addr_t;
    dir  : iodir_t;
  end record;

  type sram_controller_out_t is record
    data : sram_data_t;
  end record;

  component sram_controller is
    port ( clk   : in  std_logic;

           zd    : inout std_logic_vector(31 downto 0);
           zdp   : inout std_logic_vector(3  downto 0);
           za    : out   std_logic_vector(19 downto 0);
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

           din   : in  sram_controller_in_t;
           dout  : out sram_controller_out_t);
  end component;


  -- core
  type core_in_t is record
    alu  : alu_out_t;
    sout : u232c_out_out_t;
    sram : sram_controller_out_t;
  end record;

  type core_out_t is record
    alu  : alu_in_t;
    sout : u232c_out_in_t;
    sram : sram_controller_in_t;
  end record;

  component zebius_core
    port ( clk : in  std_logic;
           ci  : in  core_in_t;
           co  : out core_out_t);
  end component;

end zebius_component_p;
