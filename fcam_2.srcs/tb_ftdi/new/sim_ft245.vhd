library ieee; 
use ieee.std_logic_1164.all;
use IEEE.std_logic_arith.all;
use IEEE.std_logic_signed.all;

library work ;
use work.cam_pkg.all;


entity sim_ft245 is
    Port (
	
	clk : out STD_LOGIC; -- ausgang vom FTDI-Chip zur datenabholung. (60 Mhz) 
	
	reset : in std_logic;

	nrxf : out STD_LOGIC; -- When high, do not read data from the FIFO. When low, there is data available in the FIFO
	--  which can be read by driving RD# low. When in synchronous mode, data is transferred on every clock 
	-- that RXF# and RD# are both low. Note that the OE# pin must be driven low at least 1 clock period before asserting RD# low.
	ntxe : out STD_LOGIC; -- Bereitschaft zum datenaufnehmen vom FTDI Chip 1 - nicht bereit; 0 - bereit.
	-- When high, do not write data into the FIFO. When low, data can be written into the FIFO by driving WR# low. 
	-- When in synchronous mode, data is transferred on every clock that TXE# and WR# are both low.
	nrd : in STD_LOGIC; -- Enables the current FIFO data byte to be driven onto D0...D7 when RD# goes low. 
	-- The next FIFO data byte (if available) is fetched from the receive FIFO buffer each CLKOUT cycle until RD# goes high.
	nwr : in STD_LOGIC; -- Enables the data byte on the D0...D7 pins to be written into the transmit FIFO buffer when WR# is low. 
	-- The next FIFO data byte is written to the transmit FIFO buffer each CLKOUT cycle until WR# goes high.
	noe : in STD_LOGIC; -- ist low dann databus als input. Output enable when low to drive data onto D0-7. 
	-- This should be driven low at least 1 clock period before driving RD# low to allow for data buffer turn-around.
	nsiwu : in STD_LOGIC; -- The Send Immediate / WakeUp signal combines two functions on a single pin.

--	ftdi_data : inout STD_LOGIC_VECTOR (7 downto 0) -- D7 to D0 bidirectional FIFO data. This bus is normally input unless OE# is low.
-- Data is read or written on the rising edge of the CLKOUT clock   
	ftdi_data_in : in STD_LOGIC_VECTOR (7 downto 0);
	ftdi_data_out : out STD_LOGIC_VECTOR (7 downto 0)
	
   );
			  
end sim_ft245;

architecture RTL of sim_ft245 is	

constant clk_period : time := 8.333333333 ns ;
signal clk_in: std_logic;
signal bytes_sent: integer := 0;
signal ack_time: time := 150 ns;
signal ftdi_data_register : STD_LOGIC_VECTOR (7 downto 0);

begin	

clk <= clk_in;
		
   
process
begin
	clk_in <= '0';
	wait for clk_period;
	clk_in <= '1';
	wait for clk_period; 
end process;

--	ntxe <= '1', '0' after 200 ns, '1' after 19700 ns, '0' after 20300 ns, '1' after 20600 ns, '0' after 20700 ns ;
--	ftdi_data_out <= x"22" after 1500 ns;

process (clk_in, reset)



begin

if reset = '0' then

	bytes_sent <= 0;
	ntxe <= '0';

elsif clk_in'event and clk_in = '1' then

	nrxf <= '1';
	ntxe <= '0';

	if  bytes_sent > 300  then

		ntxe <= '1';
		bytes_sent <= bytes_sent + 1;
		
	else
		bytes_sent <= bytes_sent + 1;
		ftdi_data_register <= ftdi_data_in;
	
	end if;
	
	if  bytes_sent > 301 then
	
		bytes_sent <= 0;
		
	end if;

end if;

end process;


end architecture RTL;