library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library work;
use work.zebius.all;

entity zebius_core is
  port ( clk : in  std_logic);
end zebius_core;

architecture behavior of zebius_core is

  --- inner data structures
  type core_state_t is (CORE_INIT, CORE_FETCH_INST);

  type reg_file_t is array 0 to 48 of reg_data_t;
  --  0: Program Counter
  --  1: Procedure Register
  --  2: Global Base Register
  --  3: Status Register
  --  4: Floating-point Communication Register
  --  5: Floating-point Status/Control Register
  --  6-15: reserved
  -- 16-31: General Porpose Register
  -- 32-48: Floating-point Register

  type ratch_t is record
    core_state : core_state_t;
    reg_file   : reg_file_t;
    alu_in     : alu_in_t;
    alu_out    : alu_out_t;
  end record;

  signal r   : ratch_t := (core_state => CORE_INIT);
  signal rin : ratch_t;

  --- components
  -- ALU
  component zebius_alu is
    port ( clk  : in  std_logic;
           dout : out alu_out_t
           din  : in  alu_in_t);
  end component;

  --- subprograms for each state
  -- CORE_INIT
  procedure initialize_ratch (v: out ratch_t) is
  begin
    v.reg_file := (others => x"00000000");
  end;

begin

  -- Into which this component instance shouled be mapped, r or rin?
  alu1: zebius_alu
  port map ( clk  => clk;
             din  => rin.alu_in;
             dout => rin.alu_out);

  comb: process(r)
    variable v : ratch_t;
  begin
    v := r;

    if r'event then
      case core_state is
        when CORE_INIT =>
          initialize_ratch(v);
          v.core_state := CORE_FETCH;
        when CORE_FETCH =>

      end case;
    end if;

    rin <= v;
  end process;

  ratch: process(clk)
  begin
    if rising_edge(clk) then r <= rin; end if;
  end process;
  
end behavior;
