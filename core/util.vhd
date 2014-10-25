library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;


package zebius_util_p is

  function bound(mini : integer;
                 val  : integer;
                 maxi : integer)
    return integer;

  function signed_integer(n : unsigned)
    return integer;

  function signed_resize(n : unsigned;
                         size : natural)
    return unsigned;

end zebius_util_p;


package body zebius_util_p is

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

end zebius_util_p;
