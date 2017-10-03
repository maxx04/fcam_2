----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 17.03.2013 16:51:24
-- Design Name: 
-- Module Name: edge - Behavioral
-- Project Name: 
-- Target Devices: 
-- Tool Versions: 
-- Description: 
-- 
-- Dependencies: 
-- 
-- Revision:
-- Revision 0.01 - File Created
-- Additional Comments:
-- 
----------------------------------------------------------------------------------


library IEEE;
use IEEE.STD_LOGIC_1164.ALL;


entity edge_detect is
  port (async_sig : in std_logic;
        clk       : in std_logic;
        rise      : out std_logic;
        fall      : out std_logic);
end;

architecture RTL_Lothar of edge_detect is
-- http://www.lothar-miller.de

begin
  process
    variable sr : std_logic_vector (3 downto 0) := "0000";
  begin
    wait until rising_edge(clk);
    -- Flanken erkennen
    rise <= not sr(3) and sr(2);
    fall <= not sr(2) and sr(3);
    -- Eingang in Schieberegister einlesen
    sr := sr(2 downto 0) & async_sig;
  end process;
end architecture;

architecture RTL of edge_detect is
begin
  process
    variable sr : std_logic := '0';
  begin
    wait until rising_edge(clk);
    -- Flanken erkennen
    fall <= '0';
    rise <= '0';
    if async_sig = '0' and sr = '1' then
    	fall <= '1';
    elsif async_sig = '1' and sr = '0' then
    	rise <= '1';
    end if;
    
    sr := async_sig;

  end process;
end architecture;

