----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 28.05.2012 07:31:01
-- Design Name: 
-- Module Name: cam_lib - Behavioral
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
        use IEEE.std_logic_1164.all;
		  use IEEE.std_logic_signed.all;
--		  use ieee.math_real.log2;
--		  use ieee.math_real.ceil;
		  use ieee.numeric_std.all;
		  
--library WORK ;
--use work.generic_components.all ;

PACKAGE cam_lib IS
component i2c_master is
	port(
 		clock : in std_logic; 
 		areset : in std_logic; 
 		slave_addr : in std_logic_vector(6 downto 0 ); 
 		data_in : in std_logic_vector(7 downto 0 );
		data_out : out std_logic_vector(7 downto 0 );  
 		send : in std_logic; 
 		rcv : in std_logic; 
 		scl : inout std_logic; 
 		sda : inout std_logic; 
 		dispo, ack_byte, nack_byte : out std_logic
	); 
end component;

component register_rom is
	port(
		clk,en : in std_logic;
 		data : out std_logic_vector(15 downto 0 ); 
 		addr : in std_logic_vector(7 downto 0 )
	); 
end component;

type FRAME_FORMAT is (VGA, QVGA);

constant QVGA_WIDTH : natural := 320;
constant VGA_WIDTH : natural := 640;
constant QVGA_HEIGHT : natural := 240;
constant VGA_HEIGHT : natural := 480;

type CAMERA_TYPE is (OV7670, OV7725);

component DividerN is
  generic (
      divide_value : positive );
  port (
      clk, reset : in std_logic;
      clk_out, tc : out std_logic);
end component DividerN;

component yuv_register_rom is
	port(
		clk,en : in std_logic;
 		data : out std_logic_vector(15 downto 0 ); 
 		addr : in std_logic_vector(7 downto 0 )
	); 
end component;

component rgb565_register_rom is
	port(
		clk,en : in std_logic;
 		data : out std_logic_vector(15 downto 0 ); 
 		addr : in std_logic_vector(7 downto 0 )
	); 
end component;

END cam_lib;