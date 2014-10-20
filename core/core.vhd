library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library work;
use work.zebius_p.all;
use work.zebius_component_p.all;


entity zebius_core is
  port ( clk : in  std_logic;
         ci   : in  core_in_t;
         co   : out core_out_t);
end zebius_core;


architecture behavior of zebius_core is

  --- inner data structures
  type core_state_t is ( CORE_INIT,
                         CORE_FETCH_INST,
                         CORE_DECODE_INST,
                         CORE_ALU_WRITE_BACK);

  type reg_file_t is array (0 to 47) of reg_data_t;
  subtype reg_index_t is integer range 0 to 47;
  --  0: Program Counter
  --  1: Procedure Register
  --  2: Global Base Register
  --  3: Status Register
  --  4: Floating-point Communication Register
  --  5: Floating-point Status/Control Register
  --  6-15: reserved
  -- 16-31: General Porpose Register
  -- 32-47: Floating-point Register

  type ratch_t is record
    core_state : core_state_t;
    reg_file   : reg_file_t;

    inst       : zebius_inst_t;
    writeback  : reg_index_t;
    wtime      : integer range 0 to 63;
  end record;

  signal r   : ratch_t := (core_state => CORE_INIT,
                           reg_file   => (others => x"00000000"),
                           inst       => zebius_inst(x"0000"),
                           writeback  => 7,
                           wtime      => 0);

  --- subprograms for each state
  -- CORE_INIT

  -- CORE_FETCH_INST
  type array_inst_t is array (0 to 10) of zebius_inst_t;
  constant array_inst : array_inst_t
    := ( zebius_inst(x"e161"), -- 0 MOV #x61 R1
         zebius_inst(x"0100"), -- 2 WRITE R1
         zebius_inst(x"e262"), -- 4 MOV #x62 R2
         zebius_inst(x"0200"), -- 6 WRITE R2
         zebius_inst(x"affa"), -- 8 BRA start
         zebius_inst(x"6233"),
         zebius_inst(x"334c"),
         zebius_inst(x"70ff"),
         zebius_inst(x"3100"),
         zebius_inst(x"8bf9"),
         zebius_inst(x"aff4"));

  -- instructions
  procedure do_write(v    : inout ratch_t;
                     signal sout_out : in    u232c_out_out_t;
                     signal sout_in  : out   u232c_out_in_t) is
  begin
    if sout_out.busy = '0' then
      sout_in.data <= std_logic_vector(v.reg_file(to_integer(v.inst.b)+16)(7 downto 0));
      sout_in.go   <= '1';

      v.core_state := CORE_FETCH_INST;
    end if;
  end;

  procedure do_move_immediate(v : inout ratch_t) is
    variable i : reg_data_t;
    variable n : reg_index_t;
    variable w : ratch_t;
  begin
    w := v;

    i := signed_resize(v.inst.c & v.inst.d, 32);
    n := to_integer(v.inst.b)+16;
    w.reg_file(n) := i;
    w.core_state  := CORE_FETCH_INST;

    v := w;
  end;

  procedure do_move_register(v : inout ratch_t) is
    variable m, n : reg_index_t;
    variable w : ratch_t;
  begin
    w := v;

    if (v.inst.a = "0110" and v.inst.d = "0011") then
      -- MOV Rm Rn
      m := to_integer(v.inst.c)+16;
      n := to_integer(v.inst.b)+16;
    elsif (v.inst.a = "0000" and v.inst.c = "0010" and v.inst.d = "1010") then
      -- STS PR Rn
      m := 1;
      n := to_integer(v.inst.b)+16;
    end if;

    w.reg_file(n) := v.reg_file(m);
    w.core_state  := CORE_FETCH_INST;

    v := w;
  end;

  procedure do_add_immediate(v : inout ratch_t;
                             signal alu_in : out alu_in_t) is
    variable i : reg_data_t;
    variable n : reg_index_t;
    variable w : ratch_t;
  begin
    w := v;

    i := signed_resize(v.inst.c & v.inst.d, 32);
    n := to_integer(v.inst.b)+16;

    alu_in.inst <= "0001";
    alu_in.i1   <= i;
    alu_in.i2   <= v.reg_file(n);

    w.wtime := 1;
    w.writeback := n;
    w.core_state := CORE_ALU_WRITE_BACK;
    
    v := w;
  end;

  procedure do_arith(v : inout ratch_t;
                     signal alu_in : out alu_in_t) is
    variable ai : alu_inst_t;
    variable m, n : reg_index_t;
    variable w : ratch_t;
  begin
    w := v;

    ai := decode_alu_inst(v.inst);
    m := to_integer(v.inst.c)+16;
    n := to_integer(v.inst.b)+16;

    alu_in.inst <= ai;
    alu_in.i1   <= w.reg_file(m);
    alu_in.i2   <= w.reg_file(n);

    w.wtime := 1;
    case ai is
      when  ALU_INST_EQ | ALU_INST_GT =>
        w.writeback := 3;
      when others =>
        w.writeback := n;
    end case;
    w.core_state := CORE_ALU_WRITE_BACK;

    v := w;
  end;

  procedure do_branch(v : inout ratch_t) is
    constant t : std_logic := v.reg_file(3)(0);
    constant inst : zebius_inst_t := v.inst;
    variable pc : reg_data_t := v.reg_file(0);
    variable w : ratch_t;
  begin
    w := v;

    if inst.a = "1000" and inst.b = "1011" then
      -- BF disp
      if t = '0' then
        pc := unsigned(signed(pc) + (2 * signed(unsigned'(inst.c & inst.d))) + 2);
      end if;

    elsif inst.a = "1000" and inst.b = "1001" then
      -- BT disp
      if t = '1' then
        pc := unsigned(signed(pc) + (2 * signed(unsigned'(inst.c & inst.d))) + 2);
      end if;

    elsif inst.a = "1010" then
      -- BRA disp
      pc := unsigned(signed(pc) + (2 * signed(unsigned'(inst.b & inst.c & inst.d))) + 2);

      --elsif inst.a = "0100" and inst.d = "1011" then
      --  if inst.c = "0000" then
      --    -- JMP
      --    w.reg_file(1) := pc+x"4";
      --  end if;

      --  pc := w.reg_file(to_integer(inst.b)+16);

    elsif inst.a = "0000" and inst.b = "0000" and
      inst.c = "0000" and inst.d = "1011" then
      pc := w.reg_file(1);

    end if;

    w.reg_file(0) := pc;
    w.core_state := CORE_FETCH_INST;

    v := w;
  end;

  signal mode : zebius_inst_mode_t;

begin

  cycle: process(clk)
    variable v : ratch_t;
    variable inst_idx : integer range 0 to 4;
  begin
    if rising_edge(clk) then
      v := r;

      mode <= zebius_inst_mode(v.inst);

      -- reset u232c_out
      co.sout.go <= '0';

      if v.wtime /= 0 then
        v.wtime := v.wtime-1;
      else

        case v.core_state is
          when CORE_INIT =>
            v.core_state := CORE_FETCH_INST;

          when CORE_FETCH_INST =>
            inst_idx := bound(0, to_integer(shift_right(v.reg_file(0), 1)), 4);
            v.inst := array_inst(inst_idx);

            v.reg_file(0) := v.reg_file(0) + 2;

            v.core_state := CORE_DECODE_INST;

          when CORE_DECODE_INST =>

            case zebius_inst_mode(v.inst) is
              when MODE_WRITE =>
                do_write(v, ci.sout, co.sout);

              when MODE_MOV_IMMEDIATE =>
                do_move_immediate(v);

              when MODE_MOV_REGISTER =>
                do_move_register(v);

              when MODE_ADD_IMMEDIATE =>
                do_add_immediate(v, co.alu);

              when MODE_ARITH =>
                do_arith(v, co.alu);

              when MODE_BRANCH =>
                do_branch(v);

              when others => null;
            end case;

          when CORE_ALU_WRITE_BACK =>
            v.reg_file(v.writeback) := ci.alu.o;
            v.core_state := CORE_FETCH_INST;

        end case;
      end if;

      r <= v;
    end if;
  end process;
end behavior;
