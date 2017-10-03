library ieee; 
use ieee.std_logic_1164.all;
use IEEE.std_logic_arith.all;
use IEEE.std_logic_signed.all;
use ieee.numeric_std.all;

library work ;
use work.cam_pkg.all;


entity sim_cam is
    Port (
	
         reset : in std_logic; 
         cam_dout : out  std_logic_vector(7 downto 0);
         dclk : out  std_logic;
         vd : out  std_logic;
         hd : out std_logic;
         cam_scl : inout  std_logic;
         cam_sda : inout  std_logic;
         cam_reset : in  std_logic;
         cam_clk : in  std_logic
	
   );
			  
end sim_cam;

architecture RTL of sim_cam is	

signal line_pos: natural range 0 to 480 := 0;
signal row_pos, byte_pos: natural range 0 to 640 := 0;
signal code_pos: natural range 0 to 4 := 0;


constant pic_width: integer := 640;
constant pic_width_blanc: integer := 4;
constant pic_high: integer := 480;
constant pic_high_blanc: integer := 4;

begin	

dclk <= cam_clk;
		
    
process (reset, cam_clk)


begin



if ( reset = '0' ) then

	line_pos <= 0;
	row_pos <= 0;
	vd <= '0';
	hd <= '0';
	byte_pos <= 0;

elsif ( cam_clk'event and cam_clk = '1' ) then

-- start frame


if line_pos = 0 and row_pos = 0  then

        case (code_pos) is 
        
          when 0 =>
             cam_dout <= x"ff";
             code_pos <= code_pos + 1;
             
          when 1 =>
             cam_dout <= x"00";
             code_pos <= code_pos + 1;
             
          when 2 =>
             cam_dout <= x"00";
             code_pos <= code_pos + 1;
             
          when 3 =>
             cam_dout <= x"02";
				 row_pos <= row_pos + 1;
				 vd <= '1';
             code_pos <= 0;
				 byte_pos <= 0;
             
          when others =>
				code_pos <= 0;
              
       end case;
		 
elsif  row_pos = pic_width and line_pos = pic_high then

        case (code_pos) is 
        
          when 0 =>
             cam_dout <= x"ff";
             code_pos <= code_pos + 1;
             
          when 1 =>
             cam_dout <= x"00";
             code_pos <= code_pos + 1;
             
          when 2 =>
             cam_dout <= x"00";
             code_pos <= code_pos + 1;
             
          when 3 =>
             cam_dout <= x"03";
				 row_pos <= row_pos + 1;
				 vd <= '0';
             code_pos <= 0;

             
          when others =>
				code_pos <= 0;
              
       end case;

elsif  row_pos = pic_width and line_pos <= pic_high then

        case (code_pos) is 
        
          when 0 =>
             cam_dout <= x"ff";
             code_pos <= code_pos + 1;
             
          when 1 =>
             cam_dout <= x"00";
             code_pos <= code_pos + 1;
             
          when 2 =>
             cam_dout <= x"00";
             code_pos <= code_pos + 1;
             
          when 3 =>
             cam_dout <= x"01";
				 row_pos <= row_pos + 1;
				 hd <= '0';
             code_pos <= 0;
             
          when others =>
				code_pos <= 0;
              
       end case;
		 
elsif  row_pos = 0 and line_pos <= pic_high then

        case (code_pos) is 
        
          when 0 =>
             cam_dout <= x"ff";
             code_pos <= code_pos + 1;
             
          when 1 =>
             cam_dout <= x"00";
             code_pos <= code_pos + 1;
             
          when 2 =>
             cam_dout <= x"00";
             code_pos <= code_pos + 1;
             
          when 3 =>
             cam_dout <= x"00";
				 row_pos <= row_pos + 1;
				 hd <= '1';
             code_pos <= 0;
				 byte_pos <= 0;
             
          when others =>
				code_pos <= 0;
              
       end case;
		
		elsif row_pos = pic_width + pic_width_blanc then
		
			row_pos <= 0;
			line_pos <= line_pos + 1;
			
		elsif line_pos > pic_high + pic_high_blanc and row_pos = pic_width + pic_width_blanc - 1 then
		
			row_pos <= 0;
			line_pos <= 0;
			
		else
		
			if row_pos > pic_width then
				cam_dout <= x"11";
			elsif line_pos > pic_high then
				cam_dout <= x"22";
			else
				cam_dout <= CONV_STD_LOGIC_VECTOR(byte_pos, 8);
				byte_pos <= byte_pos + 1;
			end if;
			
			row_pos <= row_pos + 1;
		 
		end if;
		

end if;

end process;


end architecture RTL;