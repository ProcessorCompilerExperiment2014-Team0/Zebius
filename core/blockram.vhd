library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

package blockram_p is

  type blockram_in_t is record
    we : std_logic;
    en : std_logic;
    addr : unsigned(7 downto 0);
    data : unsigned(31 downto 0);
  end record;

  type blockram_out_t is record
    data : unsigned(31 downto 0);
  end record;

  component blockram is
    port (
      clk : in std_logic;
      din : in blockram_in_t;
      dout : out blockram_out_t);
  end component;

end blockram_p;

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library work;
use work.blockram_p.all;

entity blockram is
  port (
    clk : in std_logic;
    din : in blockram_in_t;
    dout : out blockram_out_t);
end blockram;


architecture syn of blockram is
  type ram_type is array (255 downto 0) of unsigned(31 downto 0);
  signal RAM: ram_type := (
    0 => x"EE0FEF01", -- MOV     #1, R15    ;; .start : MOV     #15, R14
    1 => x"E00C4FED", -- SHLD    R14, R15 : MOV     #12, R0
    2 => x"4E0B9E02", -- MOV.L   .call_addr.24, R14 : JSR     @R14
    3 => x"A0032009", -- AND     R0, R0 : BRA     .call_endp.25
    4 => x"20092009", -- AND     R0, R0 : AND     R0, R0
    5 => x"0000002A", -- .data.l fib.10    ;; .call_addr.24
    6 => x"4E0B9E02", -- MOV.L   .call_addr.26, R14    ;; .call_endp.25 : JSR     @R14
    7 => x"A0032009", -- AND     R0, R0 : BRA     .call_endp.27
    8 => x"20092009", -- AND     R0, R0 : AND     R0, R0
    9 => x"0000008A", -- .data.l min_caml_print_int    ;; .call_addr.26
    10 => x"0E2AA034", -- BRA     .end    ;; .call_endp.27 : STS     PR, R14    ;; fib.10
    11 => x"7F042FE2", -- MOV.L   R14, @R15 : ADD     #4, R15
    12 => x"30E7EE01", -- MOV     #1, R14 : CMP/GT  R14, R0
    13 => x"7FFC8903", -- BT      .JLE_else.28 : ADD     #-4, R15
    14 => x"4E2B6EF2", -- MOV.L   @R15, R14 : JMP     @R14
    15 => x"61032009", -- AND     R0, R0 : MOV     R0, R1    ;; .JLE_else.28
    16 => x"2F0271FF", -- ADD     #-1, R1 : MOV.L   R0, @R15
    17 => x"7F086013", -- MOV     R1, R0 : ADD     #8, R15
    18 => x"4E0B9E02", -- MOV.L   .call_addr.29, R14 : JSR     @R14
    19 => x"A0032009", -- AND     R0, R0 : BRA     .call_endp.30
    20 => x"20092009", -- AND     R0, R0 : AND     R0, R0
    21 => x"0000002A", -- .data.l fib.10    ;; .call_addr.29
    22 => x"61F27FF8", -- ADD     #-8, R15    ;; .call_endp.30 : MOV.L   @R15, R1
    23 => x"7F0471FE", -- ADD     #-2, R1 : ADD     #4, R15
    24 => x"7FFC2F02", -- MOV.L   R0, @R15 : ADD     #-4, R15
    25 => x"7F086013", -- MOV     R1, R0 : ADD     #8, R15
    26 => x"4E0B9E02", -- MOV.L   .call_addr.31, R14 : JSR     @R14
    27 => x"A0032009", -- AND     R0, R0 : BRA     .call_endp.32
    28 => x"20092009", -- AND     R0, R0 : AND     R0, R0
    29 => x"0000002A", -- .data.l fib.10    ;; .call_addr.31
    30 => x"7F047FF8", -- ADD     #-8, R15    ;; .call_endp.32 : ADD     #4, R15
    31 => x"7FFC61F2", -- MOV.L   @R15, R1 : ADD     #-4, R15
    32 => x"7FFC301C", -- ADD     R1, R0 : ADD     #-4, R15
    33 => x"4E2B6EF2", -- MOV.L   @R15, R14 : JMP     @R14
    34 => x"000B2009", -- AND     R0, R0 : RTS         ;; min_caml_print_int
    35 => x"20092009", -- AND     R0, R0 : AND     R0, R0
    36 => x"00010000", -- .data.l #65536    ;; min_caml_hp
    37 => x"00002009", -- AND     R0, R0    ;; .end : WRITE   R0
    38 => x"0000AFB2", -- BRA     .start
    others => x"00000000");
begin

  process(clk)
  begin
    if rising_edge(clk) then
      if din.en = '1' then
        if din.we = '1' then
          RAM(to_integer(din.addr)) <= din.data;
        end if;
        dout.data <= RAM(to_integer(din.addr));
      end if;
    end if;
  end process;

end syn;
