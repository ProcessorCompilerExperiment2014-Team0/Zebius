library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library work;
use work.zebius_alu_p.all;
use work.zebius_sram_controller_p.all;
use work.zebius_u232c_out_p.all;


package zebius_core_p is

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
    port (
      clk : in  std_logic;
      ci  : in  core_in_t;
      co  : out core_out_t);
  end component;

end package;



library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library work;
use work.zebius_alu_p.all;
use work.zebius_core_p.all;
use work.zebius_sram_controller_p.all;
use work.zebius_u232c_out_p.all;

use work.zebius_core_internal_p.all;
use work.zebius_loader_p.all;
use work.zebius_type_p.all;
use work.zebius_util_p.all;


entity zebius_core is
  port (
    clk : in  std_logic;
    ci   : in  core_in_t;
    co   : out core_out_t);
end zebius_core;


architecture behavior of zebius_core is

  signal r   : ratch_t := (
    state => CORE_INIT,
    mode => MODE_NOP,
    reg_file => (others => x"00000000"),
    inst => zebius_inst(x"0000"),
    wr_idx => 0,
    wr_src => WR_ALU,
    mem_data => (others => '0'),
    mem_dir => DIR_READ,
    sout_data => (others => '0'),
    wtime => 0,
    nextpc => PC_SEQ,
    jmp_idx => 0);

begin

  cycle: process(clk)
    variable v : ratch_t;
    variable inst_idx : integer range 0 to array_bound;
  begin
    if rising_edge(clk) then
      v := r;

      -- reset output
      co.sout.go <= '0';
      co.sram.dir <= DIR_READ;

      case v.state is
        when CORE_INIT =>
          v.state := next_state(v.state, v.mode);
          v.mode := MODE_FETCH_INST;

        when CORE_WAIT =>
          if v.wtime /= 0 then
            v.wtime := v.wtime-1;
          else
            v.state := next_state(v.state, v.mode);
          end if;

        when CORE_FETCH_INST =>
          co.sram.addr <= v.reg_file(0)(21 downto 0);
          co.sram.dir <= DIR_READ;

          v.wtime := 1;
          v.state := next_state(v.state, v.mode);

        when CORE_DECODE_INST =>
          v.inst := zebius_inst(ci.sram.data(15 downto 0));

          decode_inst(v.inst, v, co.alu, co.sram, co.sout);

          v.state := next_state(v.state, v.mode);

        when CORE_ACCESS_MEMORY =>
          co.sram.addr <= ci.alu.o(21 downto 0);
          co.sram.data <= v.mem_data;
          co.sram.dir <= v.mem_dir;

          v.state := next_state(v.state, v.mode);

        when CORE_OUTPUT =>
          if ci.sout.busy = '0' then
            co.sout.data <= v.sout_data;
            co.sout.go <= '1';

            v.state := next_state(v.state, v.mode);
          end if;

        when CORE_WRITE_BACK =>
          case v.wr_src is
            when WR_ALU =>
              v.reg_file(v.wr_idx) := ci.alu.o;

            when WR_MEMORY =>
              v.reg_file(v.wr_idx) := ci.sram.data(31 downto 0);
          end case;

          v.state := next_state(v.state, v.mode);

        when CORE_UPDATE_PC =>
          case v.nextpc is
            when PC_SEQ =>
              v.reg_file(0) := v.reg_file(0)+2;

            when PC_BR_TRUE =>
              if v.reg_file(3)(0) = '1' then
                v.reg_file(0) := ci.alu.o;
              else
                v.reg_file(0) := v.reg_file(0)+2;
              end if;

            when PC_BR_FALSE =>
              if v.reg_file(3)(0) = '0' then
                v.reg_file(0) := ci.alu.o;
              else
                v.reg_file(0) := v.reg_file(0)+2;
              end if;

            when PC_BRA =>
              v.reg_file(0) := ci.alu.o;

            when PC_JMP =>
              v.reg_file(0) := v.reg_file(v.jmp_idx);

          end case;

          v.state := next_state(v.state, v.mode);
          v.mode := MODE_FETCH_INST;

      end case;


      r <= v;
    end if;
  end process;
end behavior;
