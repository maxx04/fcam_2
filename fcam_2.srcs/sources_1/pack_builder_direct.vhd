----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 26.10.2012 20:04:00
-- Design Name: 
-- Module Name: pack_builder - Behavioral
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
use IEEE.std_logic_arith.all;



-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx primitives in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity pack_builder_direct is
    generic  (
       packet_length : integer := 3 + 1 + 7 + 2;  --   sync + ctrl + data + crc  
       sync_byte : STD_LOGIC_VECTOR (7 downto 0) := x"AF"
         );
    Port ( 	clk : in STD_LOGIC;
			nreset : in STD_LOGIC;
			valid : in STD_LOGIC; -- data input valid
			data_in : in STD_LOGIC_VECTOR (7 downto 0);
			re : in STD_LOGIC; -- read enable
			ctrl_byte: in STD_LOGIC_VECTOR (7 downto 0); -- wird eingelesen nach sync_bytes falling edge
			data_out : buffer STD_LOGIC_VECTOR (7 downto 0);
			busy : out STD_LOGIC;
			oe : out STD_LOGIC;
			pack_ende : out STD_LOGIC;
			debug : out STD_LOGIC);
end pack_builder_direct;

architecture Behavioral of pack_builder_direct is

signal crc_value:  std_logic_vector (15 downto 0);
signal crc_en: std_logic := '0';
signal crc_reset: std_logic := '0';
signal crc_result:  std_logic_vector (15 downto 0);
signal data:  std_logic_vector (7 downto 0) := x"00";
signal oe_t: std_logic := '0';
signal data_in_use: boolean := false;
signal re_was_not_ready: boolean := false;

component crc16_ccit is 
  port ( data_in : in std_logic_vector (7 downto 0);
    crc_en , rst, clk : in std_logic;
    crc_out : out std_logic_vector (15 downto 0));
end component crc16_ccit;


signal x: integer range 0 to 1024 := 1;
signal started: boolean := false; -- start_pck kommt 2 mal vor wegen dclk (clk = 2*dclk)

type array_6 is array (1 to 6) of std_logic_vector(7 downto 0 ); 
signal fifo_6 : array_6 ;

begin

crc16_inst:    crc16_ccit port map  ( 
    data_in => data_out,
    crc_en  => crc_en,
    rst => crc_reset, 
    clk => clk, 
    crc_out => crc_value );
    

send_data: process (clk, nreset)

begin

if ( nreset = '0') then
    x <= 0;
    oe <= '0';
    busy <= '1';
    pack_ende <= '0';
    started <= false;
	 data_in_use <= false;
	 re_was_not_ready <= false;
    
elsif (clk'event and clk = '0') then


if (valid = '1') then -- oder fifo nicht leer oder nicht voll
			
			oe <= oe_t;
			oe_t <= '1';
			

		x <= x + 1;
	   
		 case x is
	
			 when 1 | 2 | 3    =>
				data_out <= sync_byte;
				crc_reset <= '1';
				started <= true;
		
			when 4 =>
				data_out <= ctrl_byte;
				 crc_en <= '1';
				 crc_reset <= '0';
			
			 when  packet_length - 1 =>  
			 	crc_en <= '0';
				data_out <= crc_value( 15 downto 8 );


			 when  packet_length =>  
				crc_result <= crc_value;	
				data_out <= crc_value ( 7 downto 0 );
				pack_ende <= '1';
				started <= false;
				oe_t <= '0'; -- TODO schwach 
				x <= 0;
                
			 when others =>
				crc_en <= '1';
				data_out <= data_in;



		  end case;
  


else
			oe <= oe_t;
			oe_t <= '0';
	crc_en <= '0';
end if;

end if;


end process send_data;

end Behavioral;
