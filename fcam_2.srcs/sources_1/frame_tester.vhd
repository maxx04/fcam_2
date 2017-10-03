----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 13.04.2013 20:58:11
-- Design Name: 
-- Module Name: frame_tester - rtl
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
library work;

use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

use work.cam_pkg.all;

entity frame_tester is
	generic(
		frames_skip : integer := 1000   -- frames skip
	);
	Port(nreset         : in  STD_LOGIC;
		 clk            : in  STD_LOGIC;
		 receiver_ready : in  STD_LOGIC;
		 oe             : out std_logic;
		 data           : out STD_LOGIC_VECTOR(7 downto 0));
end frame_tester;

architecture rtl of frame_tester is
	signal frame_position : integer range 0 to 1000 * (G_LINE_WIDTH * G_PIXEL_BYTES * G_LINE_WIDTH + 4) := 0;
	signal line_position  : integer range 0 to 1000 * G_LINE_WIDTH * G_PIXEL_BYTES                      := 0;
begin
	send_data : process(clk, nreset)
	begin
		if (nreset = '0') then
			frame_position <= 0;
			line_position  <= 0;

		elsif (clk'event and clk = '1') then
			oe <= '0';
			-- pack_ende <= '0';

			if (receiver_ready = '1') then
				if (frame_position < frames_skip * G_LINE_WIDTH * G_PIXEL_BYTES * G_PIXEL_BYTES + 4) then
					if (frame_position < G_LINE_WIDTH * G_LINE_WIDTH * G_PIXEL_BYTES + 4) then
						case frame_position is
							when 0 | 1 | 2 =>
								data <= x"F3";
								oe   <= '1';

							when 3 =>
								data          <= x"FE";
								-- pack_ende <= '1';
								line_position <= 0;
								oe            <= '1';

							when others =>
								if line_position < G_LINE_WIDTH * G_PIXEL_BYTES then
									data <= CONV_STD_LOGIC_VECTOR(line_position, 8);
									oe   <= '1';
								end if;

								if line_position > G_LINE_WIDTH * G_PIXEL_BYTES then
									line_position <= 0;
								else
									line_position <= line_position + 1;
								end if;

						end case;

					end if;

					frame_position <= frame_position + 1;

				else
					frame_position <= 0;

				end if;

			end if;

		end if;

	end process send_data;

end rtl;
