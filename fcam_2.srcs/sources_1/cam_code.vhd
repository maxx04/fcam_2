----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 23.04.2012 18:11:27
-- Design Name: 
-- Module Name: cam_code - behavioral
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
use IEEE.STD_LOGIC_1164.all;

entity cam_code is
    port (
    
        din : in std_logic_vector (7 downto 0); 
        reset : in std_logic;
        clk : in std_logic;
        
        code : out std_logic;
        frame_start : out std_logic;
        frame_end : out std_logic;
        line_start : out std_logic;
        line_end : out std_logic);
           
end cam_code;

architecture behavioral of cam_code is

signal sd1,sd2,sd3,sd4 : std_logic_vector (7 downto 0) := x"00";

begin


main: process (reset, clk)

    begin
    
        if (reset = '0') then
        
            frame_start <= '0';
            line_start <= '0';
            frame_end <= '0';
            line_end <= '0';
        
        elsif rising_edge(clk) then
        
            code <= '0';
            
            if ( sd3 = x"FF" and sd4 = x"00" and din = x"00") then
            
                code <= '1';
            
            elsif ( sd1 = x"FF" and sd2 = x"00" and sd3 = x"00") then
            
            
                case (sd4) is
                
                    when x"02" =>
                    frame_start <= '1';
                    --             line_start <= '1';
                    
                    when x"03" =>
                    frame_end <= '1';
                    --             line_end <= '1';
                    
                    when x"00" =>
                    line_start <= '1';
                    
                    when x"01" =>
                    line_end <= '1';
                    
                    when others =>
                    frame_start <= '0';
                    line_start <= '0';
                    frame_end <= '0';
                    line_end <= '0';
                
                end case;
            
            else
            
                frame_start <= '0';
                line_start <= '0';
                frame_end <= '0';
                line_end <= '0';
            
            end if;
            
            sd1 <= sd2;
            sd2 <= sd3;
            sd3 <= sd4;
            sd4 <= din;
        
        end if;

end process main;

end behavioral;
