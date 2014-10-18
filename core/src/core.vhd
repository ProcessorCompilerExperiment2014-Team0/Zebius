library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library work;
use work.zebius_p.all;
use work.zebius_core_p.all;
use work.zebius_alu_p.all;


entity zebius_core is
  port ( clk : in  std_logic;
         rx  : in  std_logic;
         tx  : out std_logic);
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

    serial_write_flag : integer range 0 to 2;
  end record;

  signal r   : ratch_t := (core_state => CORE_INIT,
                           reg_file   => (others => x"00000000"),
                           inst       => zebius_inst(x"0000"),
                           writeback  => 7,
                           wtime      => 0,
                           serial_write_flag => 0);

  --- components
  -- ALU
  component zebius_alu is
    port ( clk  : in  std_logic;
           dout : out alu_out_t;
           din  : in  alu_in_t);
  end component;

  signal alu_in  : alu_in_t;
  signal alu_out : alu_out_t;

  -- u232c_out
  component u232c_out is
    generic (wtime: std_logic_vector(15 downto 0));
    port (clk  : in  std_logic;
          data : in  std_logic_vector (7 downto 0);
          go   : in  std_logic;
          busy : out std_logic;
          tx   : out std_logic);    
  end component;

  constant u232c_wtime : std_logic_vector(15 downto 0) := set_u232c_wtime(debug_mode);

  signal o_data : std_logic_vector(7 downto 0);
  signal o_go   : std_logic := '0';
  signal o_busy : std_logic;


  --- subprograms for each state
  -- CORE_INIT

  -- CORE_FETCH_INST
  type array_inst_t is array (0 to 3) of zebius_inst_t;
  constant array_inst : array_inst_t
    := ( zebius_inst(x"E161"), -- MOV #61 R1
         zebius_inst(x"0100"), -- WRITE R1
         zebius_inst(x"E262"), -- MOV #62 R2
         zebius_inst(x"0200")  -- WRITE R2
         );

  -- instructions
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
    alu_in.i1 <= w.reg_file(m);
    alu_in.i2 <= w.reg_file(n);

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

begin
  -- components

  debug: if false generate
  alu1: zebius_alu
    port map ( clk  => clk,
               din  => alu_in,
               dout => alu_out);
  end generate;

  rs232c_out : u232c_out generic map (wtime => u232c_wtime)
    port map (
      clk  => clk,
      data => o_data,
      go   => o_go,
      busy => o_busy,
      tx   => tx);


  -- twoproc
  cycle: process(clk)
    variable v : ratch_t;
    variable inst_idx : integer range 0 to 3;
  begin
    v := r;

    if v.serial_write_flag > 0 then
      v.serial_write_flag := v.serial_write_flag-1;
    else
      o_go <= '0';
    end if;

    if v.wtime /= 0 then
      v.wtime := v.wtime-1;
    else

      case v.core_state is
        when CORE_INIT =>
          v.core_state := CORE_FETCH_INST;

        when CORE_FETCH_INST =>
          inst_idx := to_integer(shift_right(v.reg_file(0), 1));
          v.inst := array_inst(inst_idx);

          if v.reg_file(0) = 6 then
            v.reg_file(0) := x"00000000";
          else
            v.reg_file(0) := v.reg_file(0) + 2;
          end if;

          v.core_state := CORE_DECODE_INST;

        when CORE_DECODE_INST =>

          case zebius_inst_mode(v.inst) is
            when MODE_WRITE =>
              if o_busy = '0' then
                o_data <= std_logic_vector(v.reg_file(to_integer(v.inst.b)+16)(7 downto 0));
                o_go   <= '1';
                v.serial_write_flag := 1;
                v.core_state := CORE_FETCH_INST;
              end if;

            when MODE_MOV_IMMEDIATE =>
              do_move_immediate(v);

            when MODE_MOV_REGISTER =>
              do_move_register(v);

            when MODE_ADD_IMMEDIATE =>
              do_add_immediate(v, alu_in);

            when MODE_ARITH =>
              do_arith(v, alu_in);

              -- when MODE_BRANCH =>

            when others => null;
          end case;

        when CORE_ALU_WRITE_BACK =>
          v.reg_file(v.writeback) := alu_out.o;
          v.core_state := CORE_FETCH_INST;

      end case;
    end if;
    
    r <= v;
  end process;
end behavior;
