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
  type core_state_t is (CORE_INIT,
                        CORE_FETCH_INST,
                        CORE_DECODE_INST,
                        CORE_WRITE_BACK);

  type reg_file_t is array (0 to 48) of reg_data_t;
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

    inst_idx   : integer range 0 to 3;
    inst       : zebius_inst_t;
    wtime      : integer range 0 to 63;
  end record;

  signal r   : ratch_t := (core_state => CORE_INIT,
                           reg_file   => (others => x"00000000"),
                           inst_idx   => 0,
                           inst       => zebius_inst(x"0000"),
                           wtime      => 0);
  signal rin : ratch_t := (core_state => CORE_INIT,
                           reg_file   => (others => x"00000000"),
                           inst_idx   => 0,
                           inst       => zebius_inst(x"0000"),
                           wtime      => 1);

  --- components
  -- ALU
  component zebius_alu is
    port ( clk  : in  std_logic;
           dout : out alu_out_t;
           din  : in  alu_in_t);
  end component;

  signal alu_in  : alu_in_t;
  signal alu_out : alu_out_t;

  --- subprograms for each state
  -- CORE_INIT

  -- CORE_FETCH_INST
  type array_inst_t is array (0 to 3) of zebius_inst_t;
  constant array_inst : array_inst_t
    := ( zebius_inst(x"E103"), -- MOV #3 R1
         zebius_inst(x"E208"), -- MOV #8 R2
         zebius_inst(x"312C"), -- ADD R1 R2
         zebius_inst(x"321C")  -- ADD R1 R2
         );

  --- subprograms for each instructions
  --procedure zebius_inst_movei (variable v : ratch_t;
  --                             inst : zebius_inst_t) is
  --variable i : reg_data_t;
  --variable n : integer range 0 to 47;
  --begin
  --  i := resize(inst.c & inst.d, 32);
  --  n := to_integer(inst.b);

  --  v.reg_file(n+16) := i;
  --  v.wtime          := 0;
  --end;

  --function zebius_inst_add (v : ratch_t) return ratch_t is
  --variable m, n : integer range 0 to 47;
  --begin
  --  m := to_integer(v.inst.b);
  --  n := to_integer(v.inst.c);

  --  alu_in.inst := "0001";
  --  alu_in.i1   := v.reg_file(m+16);
  --  alu_in.i2   := v.reg_file(n+16);
  --  v.wtime       := 2;
  --end;

begin

  alu1: zebius_alu
  port map ( clk  => clk,
             din  => alu_in,
             dout => alu_out);

  comb: process(r)
    variable v : ratch_t;
  begin
    v := r;

    if v.wtime /= 0 then
      v.wtime := v.wtime-1;
    else
      case v.core_state is
        when CORE_INIT =>
          v.core_state := CORE_FETCH_INST;

        when CORE_FETCH_INST =>
          v.inst := array_inst(v.inst_idx);
          if v.inst_idx = 3 then
            v.inst_idx := 0;
          else
            v.inst_idx := v.inst_idx + 1;
          end if;

          v.core_state := CORE_DECODE_INST;

        when CORE_DECODE_INST =>
          if v.inst.a = x"E" then
            -- MOV #i Rn
            v.reg_file(to_integer(v.inst.b)+16) := resize((v.inst.c & v.inst.d), 32);
            v.wtime          := 0;
            v.core_state := CORE_FETCH_INST;
          elsif v.inst.a = x"3" and v.inst.d = x"c" then
            -- ADD Rm Rn
            alu_in.inst <= "0001";
            alu_in.i1   <= v.reg_file(to_integer(v.inst.b)+16);
            alu_in.i2   <= v.reg_file(to_integer(v.inst.c)+16);
            v.wtime       := 2;
            v.core_state := CORE_WRITE_BACK;
          end if;

        when CORE_WRITE_BACK =>
          if v.inst.a = x"3" and v.inst.d = x"c" then
            v.reg_file(to_integer(v.inst.c)+16) := alu_out.o;
          end if;

          v.core_state := CORE_FETCH_INST;
      end case;
    end if;

    rin <= v;
  end process;

  ratch: process(clk)
  begin
    if rising_edge(clk) then r <= rin; end if;
  end process;
  
end behavior;
