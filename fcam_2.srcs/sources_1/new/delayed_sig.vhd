----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 06.04.2013 12:19:18
-- Design Name: 
-- Module Name: delayed_sig - RTL
-- Project Name: 
-- Target Devices: 
-- Tool Versions: 
-- Description: 
-- verlaengert signal auf ein takt
-- Dependencies: 
-- 
-- Revision:
-- Revision 0.01 - File Created
-- Additional Comments:
-- 
----------------------------------------------------------------------------------


library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity delayed_sig is
	Port(sig     : in  STD_LOGIC;
		 clk     : in  STD_LOGIC;
		 sig_out : out STD_LOGIC);
end delayed_sig;

architecture RTL of delayed_sig is
begin
	process
		variable sr : std_logic := '0';
	begin
		wait until clk'event and clk = '1';
		
		sig_out <= sig;

--		if sig = '0' and sr = '1' then
--			sig_out <= '1';
----		else
----			sig_out <= sig;
--		end if;

		sr := sig;

	end process;

end architecture RTL;
