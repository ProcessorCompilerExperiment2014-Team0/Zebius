library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library work;

package zebius_p is

  -- common data
  type iodir_t is (DIR_WRITE, DIR_READ);
  subtype reg_data_t is unsigned(31 downto 0);


  --- zebius_core
  type zebius_inst_t is record
    a : unsigned(3 downto 0);
    b : unsigned(3 downto 0);
    c : unsigned(3 downto 0);
    d : unsigned(3 downto 0);
  end record;

  type zebius_inst_mode_t is (MODE_NOP,
                              MODE_WRITE,
                              MODE_MOV_IMMEDIATE,
                              MODE_MOV_REGISTER,
                              MODE_ADD_IMMEDIATE,
                              MODE_ARITH,
                              MODE_BRANCH);

  function zebius_inst_mode (zi : zebius_inst_t)
    return zebius_inst_mode_t;


  --- zebius_alu
  subtype alu_inst_t is unsigned(3 downto 0);

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
  function zebius_inst (inst : std_logic_vector(15 downto 0))
    return zebius_inst_t;

  function decode_alu_inst (zi : zebius_inst_t)
    return alu_inst_t;

  function bound(mini : integer;
                 val  : integer;
                 maxi : integer)
    return integer;

  function signed_integer(n : unsigned)
    return integer;
  
  function signed_resize(n : unsigned;
                         size : natural)
    return unsigned;

end zebius_p;


package body zebius_p is

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

  function zebius_inst_mode (zi : zebius_inst_t)
    return zebius_inst_mode_t is
    variable m : zebius_inst_mode_t := MODE_NOP;
  begin

    if zi.a = "0000" and zi.c = "0000"  and zi.d = "0000" then
      m := MODE_WRITE;
      
    elsif zi.a = "1110" then
      -- MOV #i Rn
      m := MODE_MOV_IMMEDIATE;
      
    elsif (zi.a = "0110" and zi.d = "0011") or
      (zi.a = "0000" and zi.c = "0010" and zi.d = "1010") then
      -- MOV Rm Rn / STS PR Rn
      m := MODE_MOV_REGISTER;

    elsif zi.a = "0111" then
      -- ADD #imm Rn
      m := MODE_ADD_IMMEDIATE;

    elsif  zi.a = "0011" or zi.a = "0010" or
      (zi.a = "0110" and zi.d = "0111") or
      (zi.a = "0100" and zi.d = "1101") then
      -- (Arith) Rm Rn
      m := MODE_ARITH;

    elsif (zi.a = "1000" and zi.b = "1011") or
      (zi.a = "1000" and zi.b = "1001") or
      zi.a = "1010" or
      (zi.a = "0100" and zi.c = "0010" and zi.d = "1011") or
      (zi.a = "0100" and zi.c = "0000" and zi.d = "1011") or
      (zi.a = "0000" and zi.b = "0000" and zi.c = "0000" and zi.d = "1011") then
      -- (Branch)
      m := MODE_BRANCH;

    end if;

    return m;

  end;

  function signed_integer(n : unsigned)
    return integer is
    variable sn : signed(n'length-1 downto 0);    
  begin
    sn := signed(n);
    return to_integer(sn);
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

  function bound(mini : integer;
                 val  : integer;
                 maxi : integer)
    return integer is
  begin
    if (val < mini) then
      return mini;
    elsif (val > maxi) then
      return maxi;
    else
      return val;
    end if;
  end;

end zebius_p;
