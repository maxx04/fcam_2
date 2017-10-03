library ieee; 
use ieee.std_logic_1164.all;

library work ;
	use work.all ;

entity tb_crc16_ccit is 
end tb_crc16_ccit;

architecture Behavioral of tb_crc16_ccit is	

constant clk_period : time := 100 ns ;
signal clk : std_logic ;
signal data : std_logic_vector(7 downto 0) ;
signal reset : std_logic := '1';

signal crc_value:  std_logic_vector (15 downto 0);
signal crc_en: std_logic := '0';

signal x: integer  := 65; 
signal y: integer  := 0;

component crc16_ccit is 
  port ( data_in : in std_logic_vector (7 downto 0);
    crc_en , rst, clk : in std_logic;
    crc_out : out std_logic_vector (15 downto 0));
end component crc16_ccit;

type frame_type is array (5 downto 0) of std_logic_vector (8*66-1 downto 0);
constant camout: frame_type := (
x"050001020304050708090a778899aabbccddeeff00112233445566778899aabbccddeeff00112233445566778899aabbccddeeffff00000100000000000000000000",
x"ff00000000112233445566778899aabbccddeeff00112233445566778899aabbccddeeff00112233445566778899aabbccddeeffff00000100000000000000000000",
x"ff00000000112233445566778899aabbccddeeff00112233445566778899aabbccddeeff00112233445566778899aabbccddeeffff00000100000000000000000000",
x"ff00000000112233445566778899aabbccddeeff00112233445566778899aabbccddeeff00112233445566778899aabbccddeeffff00000100000000000000000000",
x"ff00000000112233445566778899aabbccddeeff00112233445566778899aabbccddeeff00112233445566778899aabbccddeeffff00000100000000000000000000",
x"ff00000000112233445566778899aabbccddeeff00112233445566778899aabbccddeeff00112233445566778899aabbccddeeffff00000100000000000000000000"
 );

begin	

crc16_inst:    crc16_ccit port map  ( 
    data_in => data,
    crc_en  => crc_en,
    rst => reset, 
    clk => clk,
    crc_out => crc_value );
    
        process
    	begin
			clk <= '0';
    		wait for clk_period;
    		clk <= '1';
    		wait for clk_period; 
    	end process;
    	
    	process (clk)
		

    	
    	begin

--		if ( reset = '0') then
--		x := 65;
--		y := 0;
--		crc_en <= '0';
		
		if falling_edge(clk) then
		
			crc_en <= '1';
		
			data <= camout(5) ((x+1)*8-1 downto x*8);
			
		x <= x - 1;
		y <= y + 1;

		end if;


				reset <= '0';
    	
  --  	    	wait for clk_period*10;
				

 	
    	   -- insert stimulus here 
    	   
--
--		for i in 5 downto 0 loop --- line
--			for j in 65 downto 0 loop -- byte
--			
--		   wait for  clk_period/2; -- and clk = '1'); -- then
--		if( clk = '1' ) then
--				data <= camout(i) ( (j+1)*8-1 downto j*8);
--		end if;
--			end loop;
--			crc_en <= '0';
--		end loop;
--		
   --   wait;
    	
    	end process;
    
    end architecture Behavioral;