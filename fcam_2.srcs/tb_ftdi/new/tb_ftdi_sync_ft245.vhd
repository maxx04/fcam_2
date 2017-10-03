library ieee; 
use ieee.std_logic_1164.all;
use IEEE.std_logic_arith.all;
use IEEE.std_logic_signed.all;

library work ;
use work.cam_pkg.all;

entity tb_main is 
end tb_main;

architecture Behavioral of tb_main is	

   component main
    port(
         reset : in std_logic; 
         cam_dout : in  std_logic_vector(7 downto 0);
         dclk : in  std_logic;
         vd : in  std_logic;
         hd : in  std_logic;
         cam_scl : inout  std_logic;
         cam_sda : inout  std_logic;
         cam_reset : out  std_logic;
         cam_clk : out  std_logic;
         ftdi_din : inout  std_logic_vector(7 downto 0);
         ftdi_scl : inout  std_logic;
         ftdi_sda : inout  std_logic;
         ftdi_reset : out  std_logic;
         ftdi_rxf : in std_logic;
         ftdi_txe : in std_logic;
         ftdi_rd : out std_logic;
         ftdi_wr : out std_logic;
         ftdi_oe : out std_logic;	
         ftdi_siwu: out std_logic;	
         clk_in : in  std_logic;
         clk_out : out  std_logic;
         debug1: out std_logic;
         debug2: out std_logic
        );
    end component;
    
for all: main use entity work.main(fifo_cam);
-- for all: cam use entity work.cam(test_ftdi);

component sim_ft245 is
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
	
	ftdi_data_in : in STD_LOGIC_VECTOR (7 downto 0);
	ftdi_data_out : out STD_LOGIC_VECTOR (7 downto 0)
           
           );
end component sim_ft245;

component sim_cam is
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
end component sim_cam;



signal clk_60 : std_logic ;
signal dclk : std_logic ;
-- signal data : std_logic_vector(7 downto 0) ;
signal reset : std_logic := '0';

signal  ftdi_data_out_ready: std_logic := '0';
signal 	debug1, debug2 : std_logic;

signal  ftdi_rxf : std_logic := '1'; 
signal  ftdi_txe : std_logic := '1'; 
signal  ftdi_rd : std_logic := '0';
signal 	ftdi_wr: std_logic := '0'; 
signal	ftdi_oe: std_logic := '1'; 
signal	fifo_ready: std_logic := '0';
signal	ftdi_nsiwu: std_logic := '1';
signal 	clk_in, clk_out:  std_logic := '0';

signal cam_dout : std_logic_vector(7 downto 0);
signal 	vd, hd : std_logic;
signal 	cam_clk: std_logic := '0';
signal cam_reset, cam_scl, cam_sda : std_logic;
signal ftdi_din : std_logic_vector(7 downto 0);
signal 	ftdi_reset, se : std_logic;

signal data_to_ftdi: STD_LOGIC_VECTOR (7 downto 0);
signal data_from_ftdi: STD_LOGIC_VECTOR (7 downto 0);
signal ftdi_data: STD_LOGIC_VECTOR (7 downto 0);


signal w1, d_out: STD_LOGIC_VECTOR (7 downto 0) := x"00";	
signal d_out_en: std_logic := '0';
signal sd1,sd2,sd3 : std_logic_vector (7 downto 0) := x"00";	
signal pck_byte_count : std_logic_vector (7 downto 0) := x"00";
	
-- for U_ftdi: ftdi_sync_ft245 use entity work.ftdi_sync_ft245(test);

begin	

U_main: main port map (
         reset => reset,
          cam_dout => cam_dout,
          dclk => dclk,
          vd => vd,
          hd => hd,
          cam_scl => cam_scl,
          cam_sda => cam_sda,
          cam_reset => cam_reset,
          cam_clk => cam_clk,
          ftdi_din => ftdi_din,
          ftdi_scl => cam_scl,
          ftdi_sda => cam_sda,
          ftdi_reset => ftdi_reset,
          ftdi_rxf  =>    ftdi_rxf,
          ftdi_txe  =>   ftdi_txe,
          ftdi_rd  =>  ftdi_rd,
          ftdi_wr  =>  ftdi_wr,
          ftdi_oe  =>  ftdi_oe,
          ftdi_siwu => ftdi_nsiwu,
          clk_in => clk_in,
          clk_out => clk_out,
          debug1 => debug1,
          debug2 => debug2
        );

U_sim_ft245: sim_ft245 port map (

	clk => clk_60,
	reset => reset,
	nrxf => ftdi_rxf,
	ntxe => ftdi_txe,
	nrd => ftdi_rd,
	nwr => ftdi_wr,
	noe => ftdi_oe,
	nsiwu => ftdi_nsiwu,
	ftdi_data_in => data_to_ftdi,
	ftdi_data_out => data_from_ftdi
	);
	
U_sim_cam: sim_cam port map (
	
	reset => reset, 
	cam_dout => cam_dout,
	dclk => dclk,
	vd => vd,
	hd => hd,
	cam_scl => cam_scl,
	cam_sda => cam_sda,
	cam_reset => cam_reset,
	cam_clk  => cam_clk
   );

	clk_in <= clk_60;
	clk_out <= cam_clk;
	data_to_ftdi <= ftdi_din;
 
	se <= '0';
	reset <= '0','1' after 200 ns;
	
	
	process (clk_60)
	
	
	begin
	
	if (reset = '0') then
	
		pck_byte_count <= x"d0";
			
	elsif ( clk_60'event and clk_60 = '0') then
	
		d_out_en <= '0';
	
		if (ftdi_wr = '0') then
			w1 <= data_to_ftdi;
		
			pck_byte_count <= pck_byte_count + 1;
				
			if ( sd1 = x"ff" and sd2 = x"af" and sd3 = x"af") then
				pck_byte_count <= x"00";
			end if;

			
			if pck_byte_count >= 0 and pck_byte_count < pck_data_length 
					and data_to_ftdi  /= x"fe" and data_to_ftdi  /= x"f3" then
					
				d_out <= data_to_ftdi;
				d_out_en <= '1';
				
					 if ( not ((CONV_INTEGER(data_to_ftdi) - CONV_INTEGER(d_out) = 1)  
--									or (CONV_INTEGER(data_to_ftdi) - CONV_INTEGER(d_out) = -63)
--									or (CONV_INTEGER(data_to_ftdi) - CONV_INTEGER(d_out) = -1)
									or (w1 = x"fe" and data_to_ftdi = x"00")
									or (d_out = x"5f" and data_to_ftdi = x"00")
--									or (CONV_INTEGER(data_to_ftdi) - CONV_INTEGER(d_out) = 11)
--									or (CONV_INTEGER(data_to_ftdi) - CONV_INTEGER(d_out) = -254)
									
									
									)) then
									
					d_out_en <= 'X';
					
--					assert (false)
--					report "sequence bad"
--					severity FAILURE;
					 
					end if;
					
					

				
				
			end if;
		
				sd1 <= sd2;
            sd2 <= sd3;
            sd3 <= w1;
				
		end if;		
				
	end if;
	end process;
	
--	data_to_ftdi <= x"fa";--, (others => 'Z') after 1000 ns;
								
    
--process 
--begin
--
--wait until  clk_60 = '0';
--
--if ( reset = '0' ) then
--
--else
--	
--
--
--end if;
--
--end process;

-- process 

-- begin

-- wait until  clk = '0';

-- data_old <= data_to_packbuld;

-- end process;

-- process

-- begin

-- wait until  clk = '1';

-- if ( fifo_ready = '1' ) then

	-- assert ((CONV_INTEGER(data_to_packbuld) - CONV_INTEGER(data_old) = 1)  )
	-- report "sequence bad"
	-- severity WARNING;

-- end if;

-- end process;


end architecture Behavioral;