library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library work;
use work.zebius_p.all;

package zebius_alu_p is

  -- type definition
  subtype alu_inst_t is unsigned(3 downto 0);

  type alu_in_t is record
    inst : alu_inst_t;
    i1   : reg_data_t;
    i2   : reg_data_t;
  end record;

  type alu_out_t is record
    o : reg_data_t;
  end record;

  -- constant
  constant ALU_INST_NOP  : alu_inst_t := "0000";
  constant ALU_INST_ADD  : alu_inst_t := "0001";
  constant ALU_INST_SUB  : alu_inst_t := "0010";
  constant ALU_INST_AND  : alu_inst_t := "0100";
  constant ALU_INST_OR   : alu_inst_t := "0101";
  constant ALU_INST_NOT  : alu_inst_t := "0110";
  constant ALU_INST_XOR  : alu_inst_t := "0111";
  constant ALU_INST_SHLD : alu_inst_t := "1000";
  constant ALU_INST_EQ   : alu_inst_t := "1001";
  constant ALU_INST_GT   : alu_inst_t := "1010";

  -- utility
  function decode_alu_inst(zi : zebius_inst_t) return alu_inst_t;

end zebius_alu_p;



package body zebius_alu_p is

  function decode_alu_inst(zi : zebius_inst_t)
    return alu_inst_t is
    variable ai : alu_inst_t := ALU_INST_NOP;
  begin
    case zi.a is
      when "0011" =>
        case zi.d is
          when "1100" => ai := ALU_INST_ADD;
          when "0000" => ai := ALU_INST_EQ;
          when "0111" => ai := ALU_INST_GT;
          when "1000" => ai := ALU_INST_SUB;
          when others => null;
        end case;

      when "0010" =>
        case zi.d is
          when "1001" => ai := ALU_INST_AND;
          when "1011" => ai := ALU_INST_OR;
          when "1010" => ai := ALU_INST_XOR;
          when others => null;
        end case;

      when "0110" =>
        if zi.d = "0111" then ai := ALU_INST_NOT; end if;

      when "0100" =>
        if zi.d = "1101" then ai := ALU_INST_SHLD; end if;

      when others => null;
    end case;

    return ai;
  end;

end zebius_alu_p;
