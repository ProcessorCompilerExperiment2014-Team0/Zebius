library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library work;
use work.zebius_type_p.all;
use work.zebius_util_p.all;

use work.zebius_alu_p.all;
use work.zebius_fpu_p.all;
use work.zebius_sram_controller_p.all;
use work.zebius_u232c_in_p.all;
use work.zebius_u232c_out_p.all;


package zebius_core_internal_p is
  subtype reg_index_t is integer range 0 to 47;

  type reg_file_t is array (0 to 47) of reg_data_t;
  --  0: Program Counter
  --  1: Procedure Register
  --  2: Global Base Register
  --  3: Status Register
  --  4: Floating-point Communication Register
  --  5: Floating-point Status/Control Register
  --  6-15: reserved
  -- 16-31: General Porpose Register
  -- 32-47: Floating-point Register

  type core_state_t is (
    CORE_INIT,
    CORE_WAIT,
    CORE_FETCH_INST,
    CORE_DECODE_INST,
    CORE_ACCESS_MEMORY,
    CORE_INPUT,
    CORE_OUTPUT,
    CORE_WRITE_BACK,
    CORE_UPDATE_PC);

  type inst_mode_t is (
    MODE_NOP,

    MODE_FETCH_INST,
    MODE_ARITH,
    MODE_INPUT,
    MODE_OUTPUT,
    MODE_MOV_REG,
    MODE_LOAD,
    MODE_LOAD_DISP,
    MODE_STORE,
    MODE_BRANCH_DISP,
    MODE_BRANCH_ABS);

  -- types for each core_state
  subtype wtime_t is integer range 0 to 63;
  type wr_src_t is (
    WR_ALU,
    WR_FPU,
    WR_INPUT,
    WR_MEMORY);
  type next_pc_t is (
    PC_BR_TRUE,
    PC_BR_FALSE,
    PC_BRA,
    PC_JMP,
    PC_SEQ);

  -- latch
  type ratch_t is record
    state : core_state_t;
    mode : inst_mode_t;
    reg_file : reg_file_t;

    inst       : zebius_inst_t;
    -- writeback
    wr_idx : reg_index_t;
    wr_src : wr_src_t;
    -- memory
    mem_data : sram_data_t;
    mem_dir : iodir_t;
    -- input
    sin_id : u232c_in_id_t;
    sin_data : unsigned(7 downto 0);
    -- output
    sout_data : unsigned(7 downto 0);
    -- wait
    wtime : wtime_t;
    -- update pc
    nextpc : next_pc_t;
    jmp_idx : reg_index_t;
  end record;

  function next_state (
    state : core_state_t;
    mode : inst_mode_t)
    return core_state_t;

  procedure decode_inst (
    inst : zebius_inst_t;
    v : inout ratch_t;
    signal alu : out alu_in_t;
    signal fpu : out fpu_in_t;
    signal mem : out sram_controller_in_t;
    signal sout : out u232c_out_in_t);

end package;


package body zebius_core_internal_p is

  function next_state (
    state : core_state_t;
    mode : inst_mode_t)
    return core_state_t is
  begin
    case state is
      when CORE_INIT => return CORE_FETCH_INST;
      when CORE_UPDATE_PC => return CORE_FETCH_INST;
      when others =>

        case mode is
          when MODE_NOP =>
            return CORE_UPDATE_PC;

          when MODE_FETCH_INST =>
            case state is
              when CORE_FETCH_INST => return CORE_WAIT;
              when CORE_WAIT => return CORE_DECODE_INST;
              when others =>
                assert false report "invalid core state" severity ERROR;
            end case;

          when MODE_ARITH =>
            case state is
              when CORE_DECODE_INST => return CORE_WRITE_BACK;
              when CORE_WRITE_BACK => return CORE_UPDATE_PC;
              when others =>
                assert false report "invalid core state" severity ERROR;
            end case;

          when MODE_INPUT =>
            case state is
              when CORE_DECODE_INST => return CORE_INPUT;
              when CORE_INPUT => return CORE_WRITE_BACK;
              when CORE_WRITE_BACK => return CORE_UPDATE_PC;
              when others =>
                assert false report "invalid core state" severity ERROR;
            end case;


          when MODE_OUTPUT =>
            case state is
              when CORE_DECODE_INST => return CORE_OUTPUT;
              when CORE_OUTPUT => return CORE_UPDATE_PC;
              when others =>
                assert false report "invalid core state" severity ERROR;
            end case;

          when MODE_MOV_REG =>
            case state is
              when CORE_DECODE_INST => return CORE_UPDATE_PC;
              when others =>
                assert false report "invalid core state" severity ERROR;
            end case;

          when MODE_LOAD =>
            case state is
              when CORE_DECODE_INST => return CORE_WAIT;
              when CORE_WAIT => return CORE_WRITE_BACK;
              when CORE_WRITE_BACK => return CORE_UPDATE_PC;
              when others =>
                assert false report "invalid core state" severity ERROR;
            end case;

          when MODE_LOAD_DISP =>
            case state is
              when CORE_DECODE_INST => return CORE_ACCESS_MEMORY;
              when CORE_ACCESS_MEMORY => return CORE_WAIT;
              when CORE_WAIT => return CORE_WRITE_BACK;
              when CORE_WRITE_BACK => return CORE_UPDATE_PC;
              when others =>
                assert false report "invalid core state" severity ERROR;
            end case;

          when MODE_STORE =>
            case state is
              when CORE_DECODE_INST => return CORE_UPDATE_PC;
              when others =>
                assert false report "invalid core state" severity ERROR;
            end case;

          when MODE_BRANCH_DISP =>
            case state is
              when CORE_DECODE_INST => return CORE_UPDATE_PC;
              when others =>
                assert false report "invalid core state" severity ERROR;
            end case;

          when MODE_BRANCH_ABS =>
            case state is
              when CORE_DECODE_INST => return CORE_UPDATE_PC;
              when others =>
                assert false report "invalid core state" severity ERROR;
            end case;

          when others =>
            return CORE_INIT;
        end case;
    end case;

    return CORE_INIT;
  end function;

  procedure decode_inst (
    inst : zebius_inst_t;
    v : inout ratch_t;
    signal alu : out alu_in_t;
    signal fpu : out fpu_in_t;
    signal mem : out sram_controller_in_t;
    signal sout : out u232c_out_in_t) is

    variable n : reg_index_t;
    variable m : reg_index_t;
    variable d : reg_data_t;
    variable i : reg_data_t;
  begin

    v.nextpc := PC_SEQ;

    if inst.a = "0000" and inst.c = "0000" and inst.d = "0001" then
      -- read Rn
      n := to_integer(inst.b);

      v.mode := MODE_INPUT;
      v.wr_idx := n+16;
      v.wr_src := WR_INPUT;

    elsif inst.a = "0000" and inst.c = "0000" and inst.d = "0000" then
      -- write Rn
      n := to_integer(inst.b);

      v.mode := MODE_OUTPUT;
      v.sout_data := v.reg_file(n+16)(7 downto 0);

    elsif inst.a = "0000" and inst.c = "0000" and inst.d = "0001" then
      -- read Rn
      -- fixme!
      n := to_integer(inst.b);

      v.mode := MODE_MOV_REG;

    elsif inst.a = "1110" then
      -- mov #imm Rn
      n := to_integer(inst.b);
      i := signed_resize(inst.c & inst.d, 32);

      v.mode := MODE_MOV_REG;
      v.reg_file(n+16) := i;

    elsif inst.a = "1001" then
      -- mov.l @(disp, PC)
      n := to_integer(inst.b);
      d := signed_resize(inst.c & inst.d, 32);

      v.mode := MODE_LOAD_DISP;
      v.wtime := 1;
      v.wr_idx := n+16;
      v.wr_src := WR_MEMORY;

      alu.inst <= ALU_INST_DISP_PC_L;
      alu.i1 <= v.reg_file(0);
      alu.i2 <= d;

      v.mem_dir := DIR_READ;

    elsif inst.a = "0110" and inst.d = "0011" then
      -- mov Rm Rn
      n := to_integer(inst.b);
      m := to_integer(inst.c);

      v.mode := MODE_MOV_REG;
      v.reg_file(n+16) := v.reg_file(m+16);

    elsif inst.a = "0010" and inst.d = "0010" then
      -- mov.l Rm @Rn
      n := to_integer(inst.b);
      m := to_integer(inst.c);

      v.mode := MODE_STORE;

      assert v.reg_file(n+16)(1 downto 0) = "00"
        report "memory access to unaligned address"
        severity warning;

      mem.addr <= v.reg_file(n+16)(21 downto 0);
      mem.data <= "0000" & v.reg_file(m+16);
      mem.dir <= DIR_WRITE;

    elsif inst.a = "0110" and inst.d = "0010" then
      -- mov.l @Rm Rn
      n := to_integer(inst.b);
      m := to_integer(inst.c);

      assert v.reg_file(m+16)(1 downto 0) = "00"
        report "memory access to unaligned address"
        severity warning;


      v.mode := MODE_LOAD;
      v.wtime := 1;
      v.wr_src := WR_MEMORY;
      v.wr_idx := n+16;

      mem.addr <= v.reg_file(m+16)(21 downto 0);
      mem.dir <= DIR_READ;

    elsif inst.a = "0000" and inst.c = "0010" and inst.d = "1010" then
      -- sts PR Rn
      n := to_integer(inst.b);

      v.mode := MODE_MOV_REG;
      v.reg_file(n+16) := v.reg_file(1);

    elsif inst.a = "0011" and inst.d = "1100" then
      -- add Rm Rn
      n := to_integer(inst.b);
      m := to_integer(inst.c);

      v.mode := MODE_ARITH;
      v.wr_src := WR_ALU;
      v.wr_idx := n+16;

      alu.inst <= ALU_INST_ADD;
      alu.i1 <= v.reg_file(n+16);
      alu.i2 <= v.reg_file(m+16);

    elsif inst.a = "0111" then
      -- add #imm Rn
      n := to_integer(inst.b);
      i := signed_resize(inst.c & inst.d, 32);

      v.mode := MODE_ARITH;
      v.wr_src := WR_ALU;
      v.wr_idx := n+16;

      alu.inst <= ALU_INST_ADD;
      alu.i1 <= v.reg_file(n+16);
      alu.i2 <= i;

    elsif inst.a = "0011" and inst.d = "0000" then
      -- cmp/eq Rm Rn
      n := to_integer(inst.b);
      m := to_integer(inst.c);

      v.mode := MODE_ARITH;
      v.wr_src := WR_ALU;
      v.wr_idx := 3;

      alu.inst <= ALU_INST_EQ;
      alu.i1 <= v.reg_file(n+16);
      alu.i2 <= v.reg_file(m+16);

    elsif inst.a = "0011" and inst.d = "0111" then
      -- cmp/gt Rm Rn
      n := to_integer(inst.b);
      m := to_integer(inst.c);

      v.mode := MODE_ARITH;
      v.wr_src := WR_ALU;
      v.wr_idx := 3;

      alu.inst <= ALU_INST_GT;
      alu.i1 <= v.reg_file(n+16);
      alu.i2 <= v.reg_file(m+16);

    elsif inst.a = "0011" and inst.d = "1000" then
      -- sub Rm Rn
      n := to_integer(inst.b);
      m := to_integer(inst.c);

      v.mode := MODE_ARITH;
      v.wr_src := WR_ALU;
      v.wr_idx := n+16;

      alu.inst <= ALU_INST_SUB;
      alu.i1 <= v.reg_file(n+16);
      alu.i2 <= v.reg_file(m+16);

    elsif inst.a = "0010" and inst.d = "1001" then
      -- and Rm Rn
      n := to_integer(inst.b);
      m := to_integer(inst.c);

      v.mode := MODE_ARITH;
      v.wr_src := WR_ALU;
      v.wr_idx := n+16;

      alu.inst <= ALU_INST_AND;
      alu.i1 <= v.reg_file(n+16);
      alu.i2 <= v.reg_file(m+16);

    elsif inst.a = "0110" and inst.d = "0111" then
      -- not Rm Rn
      n := to_integer(inst.b);
      m := to_integer(inst.c);

      v.mode := MODE_ARITH;
      v.wr_src := WR_ALU;
      v.wr_idx := n+16;

      alu.inst <= ALU_INST_NOT;
      alu.i1 <= v.reg_file(n+16);
      alu.i2 <= v.reg_file(m+16);

    elsif inst.a = "0010" and inst.d = "1011" then
      -- or Rm Rn
      n := to_integer(inst.b);
      m := to_integer(inst.c);

      v.mode := MODE_ARITH;
      v.wr_src := WR_ALU;
      v.wr_idx := n+16;

      alu.inst <= ALU_INST_OR;
      alu.i1 <= v.reg_file(n+16);
      alu.i2 <= v.reg_file(m+16);

    elsif inst.a = "0010" and inst.d = "1010" then
      -- xor Rm Rn
      n := to_integer(inst.b);
      m := to_integer(inst.c);

      v.mode := MODE_ARITH;
      v.wr_src := WR_ALU;
      v.wr_idx := n+16;

      alu.inst <= ALU_INST_XOR;
      alu.i1 <= v.reg_file(n+16);
      alu.i2 <= v.reg_file(m+16);

    elsif inst.a = "0100" and inst.d = "1101" then
      -- shld Rm Rn
      n := to_integer(inst.b);
      m := to_integer(inst.c);

      v.mode := MODE_ARITH;
      v.wr_src := WR_ALU;
      v.wr_idx := n+16;

      alu.inst <= ALU_INST_SHLD;
      alu.i1 <= v.reg_file(m+16);
      alu.i2 <= v.reg_file(n+16);

    elsif inst.a = "1000" and inst.b = "1011" then
      -- BF label
      d := signed_resize(inst.c & inst.d, 32);

      v.mode := MODE_BRANCH_DISP;
      v.wr_src := WR_ALU;
      v.nextpc := PC_BR_FALSE;

      alu.inst <= ALU_INST_INC_PC;
      alu.i1 <= v.reg_file(0);
      alu.i2 <= d;

    elsif inst.a = "1000" and inst.b = "1001" then
      -- BT label
      d := signed_resize(inst.c & inst.d, 32);

      v.mode := MODE_BRANCH_DISP;
      v.nextpc := PC_BR_TRUE;

      alu.inst <= ALU_INST_INC_PC;
      alu.i1 <= v.reg_file(0);
      alu.i2 <= d;

    elsif inst.a = "1010" then
      -- BRA label
      d := signed_resize(inst.b & inst.c & inst.d, 32);

      v.mode := MODE_BRANCH_DISP;
      v.nextpc := PC_BRA;

      alu.inst <= ALU_INST_INC_PC;
      alu.i1 <= v.reg_file(0);
      alu
        .i2 <= d;

    elsif inst.a = "0100" and inst.c = "0010" and inst.d = "1011" then
      -- JMP @Rn
      n := to_integer(inst.b);

      v.mode := MODE_BRANCH_ABS;
      v.nextpc := PC_JMP;
      v.jmp_idx := n+16;

    elsif inst.a = "0100" and inst.c = "0000" and inst.d = "1011" then
      -- JSR @Rn
      n := to_integer(inst.b);

      v.mode := MODE_BRANCH_ABS;
      v.nextpc := PC_JMP;
      v.jmp_idx := n+16;
      v.reg_file(1) := v.reg_file(0)+4;

    elsif inst.a = "0000" and inst.b = "0000" and inst.c = "0000" and inst.d = "1011" then
      -- RTS
      v.mode := MODE_BRANCH_ABS;
      v.nextpc := PC_JMP;
      v.jmp_idx := 1;

    elsif inst.a = "1111" and inst.c = "1000" and inst.d = "1101" then
      -- FLDI0 FRn
      n := to_integer(inst.b);

      v.mode := MODE_MOV_REG;
      v.reg_file(n+32) := x"00000000";

    elsif inst.a = "1111" and inst.c = "1001" and inst.d = "1101" then
      -- FLDI1 FRn
      n := to_integer(inst.b);

      v.mode := MODE_MOV_REG;
      v.reg_file(n+32) := x"3f800000";

    elsif inst.a = "1111" and inst.d = "1100" then
      -- FMOV FRm FRn
      n := to_integer(inst.b);
      m := to_integer(inst.c);

      v.mode := MODE_MOV_REG;
      v.reg_file(n+32) := v.reg_file(m + 32);

    elsif inst.a = "1111" and inst.d = "1000" then
      -- FMOV.S @Rm FRn
      n := to_integer(inst.b);
      m := to_integer(inst.c);

      assert v.reg_file(m+16)(1 downto 0) = "00"
        report "memory access to unaligned address"
        severity warning;


      v.mode := MODE_LOAD;
      v.wtime := 1;
      v.wr_src := WR_MEMORY;
      v.wr_idx := n+32;

      mem.addr <= v.reg_file(m+16)(21 downto 0);
      mem.dir <= DIR_READ;

    elsif inst.a = "1111" and inst.d = "1010" then
      -- FMOV.S FRm @Rn
      n := to_integer(inst.b);
      m := to_integer(inst.c);

      v.mode := MODE_STORE;

      assert v.reg_file(n+16)(1 downto 0) = "00"
        report "memory access to unaligned address"
        severity warning;

      mem.addr <= v.reg_file(n+16)(21 downto 0);
      mem.data <= "0000" & v.reg_file(m+32);
      mem.dir <= DIR_WRITE;

    elsif inst.a = "1111" and inst.d = "0000" then
      -- FADD FRm FRn
      n := to_integer(inst.b);
      m := to_integer(inst.c);

      v.mode := MODE_ARITH;
      v.wr_src := WR_FPU;
      v.wr_idx := n+32;

      fpu.inst <= FPU_INST_ADD;
      fpu.i1 <= v.reg_file(n+32);
      fpu.i2 <= v.reg_file(m+32);

    elsif inst.a = "1111" and inst.d = "0100" then
      -- FCMP/EQ FRm FRn
      n := to_integer(inst.b);
      m := to_integer(inst.c);

      v.mode := MODE_ARITH;
      v.wr_src := WR_FPU;
      v.wr_idx := n+32;

      fpu.inst <= FPU_INST_EQ;
      fpu.i1 <= v.reg_file(n+32);
      fpu.i2 <= v.reg_file(m+32);

    elsif inst.a = "1111" and inst.d = "0101" then
      -- FCMP/GT FRm FRn
      n := to_integer(inst.b);
      m := to_integer(inst.c);

      v.mode := MODE_ARITH;
      v.wr_src := WR_FPU;
      v.wr_idx := n+32;

      fpu.inst <= FPU_INST_GT;
      fpu.i1 <= v.reg_file(n+32);
      fpu.i2 <= v.reg_file(m+32);

    elsif inst.a = "1111" and inst.d = "0011" then
      -- FDIV FRm FRn
      n := to_integer(inst.b);
      m := to_integer(inst.c);

      v.mode := MODE_ARITH;
      v.wr_src := WR_FPU;
      v.wr_idx := n+32;

      fpu.inst <= FPU_INST_DIV;
      fpu.i1 <= v.reg_file(n+32);
      fpu.i2 <= v.reg_file(m+32);

    elsif inst.a = "1111" and inst.d = "0010" then
      -- FMUL FRm FRn
      n := to_integer(inst.b);
      m := to_integer(inst.c);

      v.mode := MODE_ARITH;
      v.wr_src := WR_FPU;
      v.wr_idx := n+32;

      fpu.inst <= FPU_INST_MUL;
      fpu.i1 <= v.reg_file(n+32);
      fpu.i2 <= v.reg_file(m+32);

    elsif inst.a = "1111" and inst.c = "0100" and inst.d = "1101" then
      -- FNEG FRn
      n := to_integer(inst.b);

      v.mode := MODE_ARITH;
      v.wr_src := WR_FPU;
      v.wr_idx := n+32;

      fpu.inst <= FPU_INST_NEG;
      fpu.i1 <= v.reg_file(n+32);
      fpu.i2 <= x"00000000";

    elsif inst.a = "1111" and inst.c = "0110" and inst.d = "1101" then
      -- FSQRT FRn
      n := to_integer(inst.b);

      v.mode := MODE_ARITH;
      v.wr_src := WR_FPU;
      v.wr_idx := n+32;

      fpu.inst <= FPU_INST_SQRT;
      fpu.i1 <= v.reg_file(n+32);
      fpu.i2 <= x"00000000";

    elsif inst.a = "1111" and inst.d = "0001" then
      -- FSUB FRn
      n := to_integer(inst.b);
      m := to_integer(inst.c);

      v.mode := MODE_ARITH;
      v.wr_src := WR_FPU;
      v.wr_idx := n+32;

      fpu.inst <= FPU_INST_SUB;
      fpu.i1 <= v.reg_file(n+32);
      fpu.i2 <= v.reg_file(m+32);

    elsif inst.a = "0100" and inst.c = "0101" and inst.d = "1010" then
      -- LDS Rm FPUL
      m := to_integer(inst.b);

      v.mode := MODE_MOV_REG;
      v.reg_file(4) := v.reg_file(m+16);

    elsif inst.a = "0000" and inst.c = "0101" and inst.d = "1010" then
      -- STS FPUL Rn
      n := to_integer(inst.b);

      v.mode := MODE_MOV_REG;
      v.reg_file(n+16) := v.reg_file(4);

    elsif inst.a = "1111" and inst.c = "0001" and inst.d = "1101" then
      -- FLDS FRm FPUL
      m := to_integer(inst.b);

      v.mode := MODE_MOV_REG;
      v.reg_file(4) := v.reg_file(m+32);

    elsif inst.a = "1111" and inst.c = "0000" and inst.d = "1101" then
      -- FSTS FPUL FRn
      n := to_integer(inst.b);

      v.mode := MODE_MOV_REG;
      v.reg_file(n+32) := v.reg_file(4);

    elsif inst.a = "1111" and inst.c = "0011" and inst.d = "1101" then
      -- FTRC FRm FPUL
      m := to_integer(inst.b);

      v.mode := MODE_ARITH;
      v.wr_src := WR_FPU;
      v.wr_idx := 4;

      fpu.inst <= FPU_INST_FTOI;
      fpu.i1 <= v.reg_file(m+32);
      fpu.i2 <= x"00000000";

    elsif inst.a = "1111" and inst.c = "0010" and inst.d = "1101" then
      -- FLOAT FLUL FRn
      n := to_integer(inst.b);

      v.mode := MODE_ARITH;
      v.wr_src := WR_FPU;
      v.wr_idx := n+32;

      fpu.inst <= FPU_INST_FTOI;
      fpu.i1 <= v.reg_file(4);
      fpu.i2 <= x"00000000";

    else
      assert false report "invalid instruction" severity FAILURE;
    end if;

  end procedure;

end package body;
