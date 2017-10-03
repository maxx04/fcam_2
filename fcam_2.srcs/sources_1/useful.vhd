library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;
use IEEE.std_logic_arith.all;

package usefuls is
  
  --- @param = 0 1 2 3 4 5 6 7 8
  --- @ret   = 0 0 1 1 2 2 2 2 3
  function log2_floor(N: natural) return natural;
  
  --- @param = 0 1 2 3 4 5 6 7 8
  --- @ret   = 0 0 1 2 2 3 3 3 3
  function log2_ceil(N: natural) return natural;

  --- find minimum number of bits required to
  --- represent N as an unsigned binary number
  --- @param = 0 1 2 3 4 5 6 7 8
  --- @ret   = 1 1 2 2 3 3 3 3 4
  ---
  function min_bits(N: natural) return positive;
  
  --- (N % 2 == 0) ? N : (N * 2)
  ---
  function mod_even(N: natural) return positive;
end;

package body usefuls is
  function log2_floor(N: natural) return natural is
  begin
    return min_bits(N) - 1;
  end;
  
  function log2_ceil(N: natural) return natural is
  begin
    if N < 2 then
      return 0;
    else
      return min_bits(N - 1);
    end if;
  end;

  --- find minimum number of bits required to
  --- represent N as an unsigned binary number
  ---
  function min_bits(N: natural) return positive is
  begin
    if N < 2 then
      return 1;
    else
      return 1 + min_bits(N/2);
    end if;
  end;
  
  --- (N % 2 == 0) ? N : (N * 2)
  ---
  function mod_even(N: natural) return positive is
  begin
    if N mod 2 = 0 then
      return N;
    else
      return N * 2;
    end if;
  end;
end;
