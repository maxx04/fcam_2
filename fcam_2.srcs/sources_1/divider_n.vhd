library IEEE;
library work;

use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

use work.usefuls.ALL;

entity DividerN is
  generic (
      divide_value : positive := 8);
  port (
      clk, reset : in std_logic;
      clk_out, tc : out std_logic);
end DividerN;

--  architecture Behavioral of DividerN is
--    constant required_bits : integer := min_bits(mod_even(divide_value) - 1);
--    signal timer : std_logic_vector(required_bits - 1 downto 0) := (others => '0');
--    signal clk_n : std_logic;
--  begin
--    clk_n <= not clk;
  
--    gen_even: if (divide_value mod 2 = 0) generate
--      process(clk, reset) begin
--        if reset = '1' then
--          timer <= (others => '0');
--          tc <= '0';
--        elsif clk'event and clk = '1' then
--          if timer < conv_std_logic_vector(divide_value - 1, required_bits) then
--            timer <= timer + 1;
--            tc <= '0';
--          else
--            timer <= (others => '0');
--            tc <= '1';
--          end if;
--        end if;
--      end process;
    
--      clk_out <= '1' when timer < conv_std_logic_vector(divide_value / 2, required_bits) 
--          else '0';
--    end generate;
  
--    -- divide_value % 2 = 1�̂Ƃ��͕��G(?�?��\�ɂ��邽��)
--    -- �Ⴆ��5�̂Ƃ��̓J�E���^�̓�?삪
--    -- clk    ---___---___---___---___---___---___---___---___---
--    -- timer   9  1  0  2  2  4  5  7  7  9  9  1  0  2  2  4  5
--    -- clkout ___---------------_______________---------------___
--    gen_odd: if (divide_value >= 3) and (divide_value mod 2 = 1) generate
--      process(clk, clk_n, reset) begin
--        if reset = '1' then
--          timer <= (others => '0');
--          tc <= '0';
--        elsif (clk'event and clk = '1') then
--          if timer >= conv_std_logic_vector(divide_value - 1, required_bits) then
--            timer(0) <= '1';
--          else
--            timer(0) <= '0';
--          end if;
--        elsif (clk_n'event and clk_n = '1') then
--          if timer < conv_std_logic_vector((divide_value * 2) - 1, required_bits) then
--            timer(required_bits - 1 downto 1) <= timer(required_bits - 1 downto 1) + 1;
--            tc <= '0';
--          else
--            timer(required_bits - 1 downto 1) <= (others => '0');
--            tc <= '1';
--          end if;
--        end if;
--      end process;
    
--      clk_out <= '1' when timer < conv_std_logic_vector(divide_value, required_bits) 
--          else '0';
--    end generate;
  
--    gen_unity: if (divide_value = 1) generate
--      tc <= '0' when reset = '1' else clk;
--      clk_out <= clk;
--    end generate;
--  end Behavioral;

architecture small of DividerN is


constant required_bits : integer := min_bits(mod_even(divide_value) - 1);


signal v1: std_logic := '0';

begin

clk_out <= v1;

div: process(reset, clk)

variable cnt : integer range 0 to 512 := 0; --todo
constant divider: integer := divide_value - 1; 
 
begin

if reset = '1' then
 cnt := 0;
 tc <= '0';

elsif (CLK'event and CLK = '1') then

	if (cnt = divider ) then
		v1 <= not v1;
		cnt := 0;
	end if;

cnt := cnt + 1;
			
end if;

end process div;

end architecture small;
