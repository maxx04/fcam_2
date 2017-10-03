----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 13.05.2012 13:53:37
-- Design Name: 
-- Module Name: cam_config - Behavioral
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

use ieee.std_logic_arith.all;
use IEEE.std_logic_unsigned.all;

library work;
use work.cam_lib.all ;

entity cam_config is
    Port ( clk : in std_logic;
           nReset : in std_logic;
           scl : inout std_logic;
           sda : inout std_logic;
           debug : out std_logic );
end cam_config;

architecture Behavioral of cam_config is

for all: DividerN use entity work.DividerN(small);

    constant NB_REGS : integer := 32; 
    constant TCM8230MD_I2C_ADDR : std_logic_vector(6 downto 0) := "0111100"; 

    TYPE registers_state IS (INIT, SEND_ADDR, WAIT_ACK0, SEND_DATA, WAIT_ACK1, NEXT_REG, STOP) ; 
    
    signal i2c_data : std_logic_vector(7 downto 0 ) ; 
    signal reg_data : std_logic_vector(15 downto 0 ) ; 
    signal i2c_addr : std_logic_vector(6 downto 0 ) ; 
    signal send : std_logic ; 
    signal rcv : std_logic ; 
    signal dispo : std_logic ; 
    signal ack_byte, nack_byte : std_logic ; 
   
    signal reg_state : registers_state ; 
    signal reg_addr : std_logic_vector(7 downto 0 ) ;     
	
	signal i2c_clk : std_logic;
	signal reset : std_logic;
	
begin
reset <= not nReset;

div_inst_i2c: DividerN
     generic map (divide_value => 256)
     port map ( clk => clk, reset => reset,  clk_out => i2c_clk, tc => open);
   		
register_rom_vga: rgb565_register_rom --rom containg sensor configuration
	port map (
	   clk => clk,
		en => '1',
		addr => reg_addr, 
		data => reg_data
	); 
    
i2c_master0: i2c_master -- i2c master to send sensor configuration, no proof its working
    	port map ( 
    		clock => i2c_clk, 
    		areset => nreset, 
    		sda => sda, 
    		scl => scl, 
    		data_in => i2c_data, 
    		slave_addr => TCM8230MD_I2C_ADDR, 
    		send => send, 
    		rcv => rcv, 
    		dispo => dispo, 
    		ack_byte => ack_byte,
    		nack_byte => nack_byte
    	); 
   			
  			
-- i2c_interface
init_proc:	process(clk, nreset)

begin

-- i2c_addr <= TCM8230MD_I2C_ADDR ; -- sensor address

if  nreset = '0'  then
	reg_state <= init ;
	reg_addr <= (others => '0');
	
elsif clk'event and clk = '1' then

	case reg_state is
	
		when init => 
			if  dispo = '1'  then 
				send <= '1' ; 
				i2c_data <= reg_data(15 downto 8) ; 
				reg_state <= send_addr ;
			end if ;
			
		when send_addr => --send register address
			if  ack_byte = '1'  then
				send <= '1' ; 
				i2c_data <= reg_data(7 downto 0) ; 
				reg_state <= wait_ack0 ;
			elsif nack_byte = '1' then
				send <= '0' ; 
				reg_state <= next_reg ;
			end if ;
			
		when wait_ack0 => -- falling edge of ack 
		  if  ack_byte = '0'  then
				reg_state <= send_data ;
			end if ;
			
		when send_data => --send register value
			if  ack_byte = '1'  then
				send <= '0' ; 
				reg_state <= wait_ack1 ; 
				reg_addr <= reg_addr + 1;
			elsif nack_byte = '1' then
				send <= '0' ; 
				reg_state <= next_reg ;
			end if ;
			
		when wait_ack1 => -- wait for ack
		  if  ack_byte = '0'  then
				reg_state <= next_reg ;
			end if ;
			
		when next_reg => -- switching to next register
			send <= '0' ;
			if ( NOT ack_byte = '1' ) AND  reg_data /= X"FFFF"  AND  dispo = '1'  AND  conv_integer(reg_addr) < NB_REGS  then
				reg_state <= send_addr ; 
				i2c_data <= reg_data(15 downto 8) ; 
				send <= '1' ;
			elsif  conv_integer(reg_addr) >= NB_REGS  OR  reg_data = X"FFFF"  then
				reg_state <= stop ;
			end if ;
			
		when stop => -- all register were set, were done !
			send <= '0' ;
			reg_state <= stop ;
			
		when others => 
			reg_state <= init ;
			
	end case ;
end if ;

end process init_proc;  

-- debug <= i2c_clk;


end Behavioral;
