----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 13.10.2012 08:55:02
-- Design Name: 
-- Module Name: ftdi_sync_ft245 - Behavioral
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

library work;
use work.cam_pkg.all;

entity ftdi_sync_ft245 is
    Port (
    
           clk_60: out STD_LOGIC; -- clk to send / read data rising edge 
           nreset: in STD_LOGIC; -- reset negativ
           we:  in STD_LOGIC; -- high: there are data to send to FTDI
           re: out STD_LOGIC; -- high: data ready to read from FTDI
			  ie: out std_logic; -- input enable high: ready to read data into FTDI
           send_immediate:  in STD_LOGIC; -- send data immediate.
           data_in : in STD_LOGIC_VECTOR (7 downto 0); -- data to send to FTDI
           data_out : out STD_LOGIC_VECTOR (7 downto 0); -- data to read from FTDI
           debug : out STD_LOGIC;
           
-- connections to chip   

           clk : in STD_LOGIC; -- ausgang vom FTDI-Chip zur datenabholung. (60 Mhz)        
           
           nrxf : in STD_LOGIC; -- When high, do not read data from the FIFO. When low, there is data available in the FIFO
           --  which can be read by driving RD# low. When in synchronous mode, data is transferred on every clock 
           -- that RXF# and RD# are both low. Note that the OE# pin must be driven low at least 1 clock period before asserting RD# low.
           ntxe : in STD_LOGIC; -- Bereitschaft zum datenaufnehmen vom FTDI Chip 1 - nicht bereit; 0 - bereit.
           -- When high, do not write data into the FIFO. When low, data can be written into the FIFO by driving WR# low. 
           -- When in synchronous mode, data is transferred on every clock that TXE# and WR# are both low.
           nrd : out STD_LOGIC; -- Enables the current FIFO data byte to be driven onto D0...D7 when RD# goes low. 
           -- The next FIFO data byte (if available) is fetched from the receive FIFO buffer each CLKOUT cycle until RD# goes high.
           nwr : out STD_LOGIC; -- Enables the data byte on the D0...D7 pins to be written into the transmit FIFO buffer when WR# is low. 
           -- The next FIFO data byte is written to the transmit FIFO buffer each CLKOUT cycle until WR# goes high.
           noe : out STD_LOGIC; -- ist low dann databus als input. Output enable when low to drive data onto D0-7. 
           -- This should be driven low at least 1 clock period before driving RD# low to allow for data buffer turn-around.
           nsiwu : out STD_LOGIC; -- The Send Immediate / WakeUp signal combines two functions on a single pin.
           -- If USB is in suspend mode (PWREN# = 1) and remote wakeup is enabled in the EEPROM, 
           -- strobing this pin low will cause the device to request a resume on the USB Bus. 
           -- Normally, this can be used to wake up the Host PC.  During normal operation (PWREN# = 0), 
           -- if this pin is strobed low any data in the device RX buffer will be sent out over USB on the next Bulk-IN request
           -- from the drivers regardless of the pending packet size. This can be used to optimize USB transfer speed for some applications. 
           -- Tie this pin to VCCIO if not used.
           
           ftdi_data : inout STD_LOGIC_VECTOR (7 downto 0) -- D7 to D0 bidirectional FIFO data. This bus is normally input unless OE# is low.
           
           );
end ftdi_sync_ft245;

architecture read of ftdi_sync_ft245 is

signal ready_to_read_from_FTDI: boolean := false;
signal read_ftdi: boolean := false;
signal ready_to_write_to_FTDI: boolean := false;
signal ntxe_old, we_old: std_logic;
signal flanke: boolean := false;



begin

clock: clk_60 <= clk;

--debug <= '1' when ready_to_write_to_FTDI and ntxe = '0' else '0';

nsiwu <= '1';

-- flash:	nsiwu <= '0' when (send_immediate = '1'  and  we = '1' ) else '1';

--write_to_FTDI:	ftdi_data <= data_in when ( we = '1' or flanke) and ntxe = '0'  else (others => 'Z');

--nwr_proc:	nwr <= '0' when (we = '1' or flanke ) and ntxe = '0' else '1';

ie_proc:	ie <= '1' when ntxe = '0' else '0';

main: process (clk, nreset)

variable n: integer range 0 to 1200 := 0;
variable bytes_send: integer range 0 to 6000 := 0;

begin

if (nreset = '0') then  

ready_to_read_from_FTDI <= false;
ready_to_write_to_FTDI <= false;
n := 0;

bytes_send := 0;


elsif (clk'event and clk = '0') then

	nrd <= '1'; 
	noe <= '1';
	re <= '0';
	
	if (ntxe = '0') then
	
		if (we = '1' or flanke) then
		
			ftdi_data <= data_in;
			nwr <= '0';
		else
			ftdi_data <= (others => 'Z');
			nwr <= '1';

		end if;
		
	else
	
	
--		ftdi_data <= (others => 'Z');	
	
	end if;
	
end if;	
	


end process main;

fl: process (nreset, clk)

begin

if (nreset = '0') then

ntxe_old <= '0';
we_old <= '0';
flanke <= false;

elsif (clk'event and clk = '0') then

	if (we_old = '1' and we = '0' ) then
	
		flanke <= true;
	
	end if;

	if ntxe_old = '1' and ntxe = '0' and flanke then
	
		flanke <= true;
		
	elsif ntxe = '0' then
	
		flanke <= false;
	
	end if;
	
ntxe_old <= ntxe;
we_old <= we;

end if;

end process fl;

end read;


architecture test of ftdi_sync_ft245 is

type byte_array is array (0 to G_LINE_WIDTH * G_PIXEL_BYTES) of std_logic_vector( 7 downto 0 );

signal color: byte_array;
signal read_enable: boolean := false;
signal read_byte: boolean := false;
signal x: integer range 0 to 200 * G_LINE_WIDTH * G_PIXEL_BYTES * G_LINE_WIDTH := 1;
  
signal ready_to_read_from_FTDI: boolean := false;
signal ready_to_write_to_FTDI: boolean := false;

signal block_writed: boolean := true;
signal data_tmp: STD_LOGIC_VECTOR (7 downto 0);

signal stop_write: boolean := false;

begin

write_to_FTDI:	ftdi_data <= data_tmp when not read_byte else (others => 'Z');

				nwr <= '1' when ntxe = '1' or stop_write else '0';
				
				debug <= '1' when ntxe = '1' or stop_write else '0';


main: process (clk, nreset)

variable n: integer range 0 to 3000 := 0;
variable bytes_send: integer range 0 to 3000 := 0;
constant space_cycles: integer := 2000;
constant siwu_cycles: integer := 0;
variable y: integer range 0 to 10 * G_LINE_WIDTH * G_PIXEL_BYTES := 1;

begin

if nreset = '0' then
   
read_enable <= false;
ready_to_write_to_FTDI <= false;

x <= 0;
n := 0;
y := 0;
bytes_send := 0;

stop_write <= false;


elsif (clk'event and clk = '0') then

	nsiwu <= '1';
	read_enable <= false;
	stop_write <= true;

	if ready_to_write_to_FTDI and ntxe = '0' and bytes_send < 500 then 
	
		
		if x < 1 * (G_LINE_WIDTH * (G_LINE_WIDTH * G_PIXEL_BYTES + space_cycles + siwu_cycles) + 4)  then

				read_enable <= true;
  
			if  x < G_LINE_WIDTH * (G_LINE_WIDTH * G_PIXEL_BYTES + space_cycles + siwu_cycles ) + 4 then
			
				stop_write <= false;
	
				read_enable <= false;
				
				bytes_send := bytes_send + 1;

				case x is

				 when 0 | 1 | 2   =>
			 
					data_tmp <= x"F3";
					-- stop_write <= false;
					-- nwr <= '0';
				
				 when 3 =>
				 
					data_tmp <= x"FE";
					y := 0;
					-- stop_write <= false;
					-- nwr <= '0';

				 when others =>
				 
				 
					data_tmp <= CONV_STD_LOGIC_VECTOR(y, 8);
					y := y + 1;
				 

					-- if  y < 4  then 

						-- data_tmp <= color(y);


					if  y < G_LINE_WIDTH * G_PIXEL_BYTES then

					
					-- zeile ende
					-- elsif  y < G_LINE_WIDTH * G_PIXEL_BYTES + 1 then
					
						-- data_tmp <= x"10";
						-- stop_write <= true;
		
						
					-- elsif  y <= G_LINE_WIDTH * G_PIXEL_BYTES + 4 then	


						
					-- elsif  y < G_LINE_WIDTH * G_PIXEL_BYTES + 2 + siwu_cycles then
			
		
						
						
					-- elsif  y < G_LINE_WIDTH * G_PIXEL_BYTES + space_cycles + siwu_cycles then
						-- stop_write <= true;					

						
						-- nsiwu <= '0';
						
						-- data_tmp <= x"f0";

						-- read_enable <= true;
		

					
					else
					
						y := 0;
						
					end if; 
					

				
		
				end case; -- write frame
				
			else -- not in frame, can read
			
			-- ready_to_write_to_FTDI <= false;

			end if; 

			x <= x + 1;
	
		else 
		
			x <= 0;

		end if;
		
		elsif 	bytes_send = 501 then
		
			-- nsiwu <= '0';
			bytes_send := bytes_send + 1;
		
		elsif 	bytes_send < 3000 then
			bytes_send := bytes_send + 1;
		
		else
		
			bytes_send := 0;

        end if;	 --	ntxe = '0'
		

		
		if ntxe = '0' then
			if n = 4 then
				ready_to_write_to_FTDI <= true;
			else
				n := n + 1;
			end if;
		else
			ready_to_write_to_FTDI <= false;
			n := 0;

		end if;


	end if;

end process main;


				

read_from_FTDI: process ( clk, nreset)

begin

if (nreset = '0') then

	read_byte <= false;
	ready_to_read_from_FTDI <= false;


elsif (clk'event and clk = '0') then

	noe <= '1';
	nrd <= '1';
	read_byte <= false;
	
	if nrxf = '0' then
	
		if read_enable then
		
			if (ready_to_read_from_FTDI) then
				
				read_byte <= true;
				nrd <= '0';

			end if;	

			ready_to_read_from_FTDI <= true;
			noe <= '0';
			
		end if;
	
	else
		ready_to_read_from_FTDI <= false;
		
	end if;
	

end if;

end process read_from_FTDI;


read_write_switch: process ( clk, nreset)

variable n: integer range 0 to 1024 := 0;

begin

if (nreset = '0') then

	for i in 0 to 4 loop
		color(i) <= x"45"; 
	end loop;

	n := 0;

elsif (clk'event and clk = '0') then

	
	if read_byte and n < 6 then
	
		if ftdi_data = CONV_STD_LOGIC_VECTOR(n, 8) then
		
			color(n) <= ftdi_data;
			n := n + 1;
			
		end if;
		
	else
		n := 0;
	end if;
	
end if;

end process read_write_switch;


end test;

