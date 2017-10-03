library ieee; 
use ieee.std_logic_1164.all;
use IEEE.std_logic_arith.all;
use IEEE.std_logic_signed.all;

library work ;
use work.cam_pkg.all;

entity tb_pack_builder is 
end tb_pack_builder;

architecture Behavioral of tb_pack_builder is	

constant clk_period : time := 100 ns ;
signal clk, dclk : std_logic ;
signal data : std_logic_vector(7 downto 0) ;
signal reset : std_logic := '1';


signal  oe : std_logic; -- data out from cam ready
signal  pack_data_out_ready: std_logic := '0';  -- data out from pack_builder ready
signal  pack_ende: std_logic := '1'; 
signal  error, se : std_logic;

signal  fifo_empty : std_logic := '1'; 
signal  ftdi_ready : std_logic := '1'; 
signal  start_pck : std_logic := '0';
signal 	pack_builder_busy: std_logic := '0'; 
signal	can_read_fifo: std_logic := '1'; 
signal	fifo_ready: std_logic := '0';
signal	switch_buff: std_logic := '0';
signal wr:  std_logic := '0';


signal data_to_ftdi: STD_LOGIC_VECTOR (7 downto 0);
signal data_to_packbuld: STD_LOGIC_VECTOR (7 downto 0);

type frame_type is array (5 downto 0) of std_logic_vector (8*66-1 downto 0);
constant camout: frame_type := (
x"010203040506010203040506010203040506eeff00112233445566778899aabbccddeeff00112233445566778899aabbccddeeffff00000100000000000000000000",
x"ff00000000112233445566778899aabbccddeeff00112233445566778899aabbccddeeff00112233445566778899aabbccddeeffff00000100000000000000000000",
x"ff00000000112233445566778899aabbccddeeff00112233445566778899aabbccddeeff00112233445566778899aabbccddeeffff00000100000000000000000000",
x"ff00000000112233445566778899aabbccddeeff00112233445566778899aabbccddeeff00112233445566778899aabbccddeeffff00000100000000000000000000",
x"ff00000000112233445566778899aabbccddeeff00112233445566778899aabbccddeeff00112233445566778899aabbccddeeffff00000100000000000000000000",
x"ff00000000112233445566778899aabbccddeeff00112233445566778899aabbccddeeff00112233445566778899aabbccddeeffff00000100000000000000000000"
 );


    	
    	signal x: integer range 0 to 1023 := 0;
		signal y: integer range 0 to 1023 := 0;
		
		signal npack_builder_busy : std_logic;
		
		signal data_old: STD_LOGIC_VECTOR (7 downto 0) := x"00";

for inst_switch_fifo: switch_fifo use entity work.switch_fifo(flash);
for inst_pack_builder: pack_builder use entity work.pack_builder(through);

begin	

npack_builder_busy <= not pack_builder_busy;

inst_switch_fifo: switch_fifo
    generic map (
       packet_length => 3 + 1 + 7 + 2,  --  3 sync + 1 ctrl + 10 data + 2 crc - 
       fifo_size => 8 )
    port map( 
        clk => clk, -- clock zur abholung von daten (60 MHz)
        clk_in => dclk, -- clock daten eingang in buffer
        nreset => reset, -- negativ reset
        din => data, -- Daten eingang in buffer
        we => oe, -- 1 wenn daten vom DIN einlesen mit jedem clk nedge TODO ueberlauf kontrolle
		re => npack_builder_busy, -- 1 daten werden gelesen, 0 - nicht
-- out 
        dout_ready => fifo_ready,
		dout => data_to_packbuld, -- Datenschnittstelle f�r FTDI
        full => open, -- daten waren nicht abgeholt = 1
		
		empty => open, -- daten waren nicht abgeholt = 1
        debug => open
        ); 
		  

     
inst_pack_builder:  pack_builder

generic map (
   packet_length => 3 + 1 + 7 + 2, --  3 sync + 10 data + 2 crc - 
   sync_byte  => x"AF")
port map (
	 clk => clk,
	 nreset => reset,
	 valid => fifo_ready,
	 data_in => data_to_packbuld,
	 rr => ftdi_ready,
	 ctrl_byte => x"00",
	 data_out =>  data_to_ftdi, 
	 busy => pack_builder_busy,
	 oe => pack_data_out_ready,
	 pack_ende => pack_ende,
	 debug => open
);

    

   reset <= '0' after 20 ns,'1' after 650 ns;
	ftdi_ready <= '0' after 4400 ns, '1' after 5300 ns,
								'0' after 14400 ns, '1' after 15300 ns,
								'0' after 21700 ns, '1' after 22000 ns;
								
	can_read_fifo <= not (pack_builder_busy);
    
  process
begin
	clk <= '0';
	wait for clk_period;
	clk <= '1';
	wait for clk_period; 
end process;

process
	begin
	dclk <= '0';
	wait for 2*clk_period;
	dclk <= '1';
	wait for 2*clk_period; 
end process;


process 
begin

wait until  dclk = '0';

if ( reset = '0' ) then
	 x <= 1;
	 oe <= '0';
	 data <= (others => '0');
	 wr <= '0';
 
else
	
	if(y < 128) then
	
	oe <= '0';

		if ( x < 64) then
			x <= x + 1;
			oe <= '1'; -- data uebertragung frei
		else

			oe <= '0';
	--			wait;
		 end if;
		 
			data <= CONV_STD_LOGIC_VECTOR(x, 8); -- daten bilden	    

	else
		y <= 1;
		x <= 1;
	end if;
	
	y <= y + 1;

end if;

end process;

process 

begin

wait until  clk = '0';

data_old <= data_to_packbuld;

end process;

process

begin

wait until  clk = '1';

if ( fifo_ready = '1' ) then

	assert ((CONV_INTEGER(data_to_packbuld) - CONV_INTEGER(data_old) = 1)  )
	report "sequence bad"
	severity WARNING;

end if;

end process;


end architecture Behavioral;