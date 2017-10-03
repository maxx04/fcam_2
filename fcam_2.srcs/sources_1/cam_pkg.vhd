----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 07.11.2012 05:36:01
-- Design Name: 
-- Module Name: cam_pkg - Behavioral
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
use IEEE.STD_LOGIC_1164.all;
use ieee.numeric_std.all;

package CAM_PKG is

	-- packet data length (bytes)
	constant pck_data_length  : positive := 12;
	constant numb_sync_bytes  : positive := 5;
	constant numb_cntrl_bytes : positive := 1;
	constant numb_crc_bytes   : positive := 2;

	constant gl_packet_length : positive := numb_sync_bytes + numb_cntrl_bytes + pck_data_length + numb_crc_bytes;

	constant G_LINE_WIDTH  : integer := 48;
	constant G_PIXEL_BYTES : integer := 2;

	type T_SM_SETTINGS is record
		x_cnt   : unsigned(15 downto 0);
		y_cnt   : unsigned(15 downto 0);
		cmp_idx : unsigned(2 downto 0);
	end record;

	constant C_SM_SETTINGS : T_SM_SETTINGS := (
		(others => '0'),
		(others => '0'),
		(others => '0')
	);

	component switch_fifo is
		generic(
			packet_length : positive := 3 + 1 + 6 + 2; --  sync + ctrl + data + crc - 
			fifo_size     : positive := 9
		);
		Port(
			clk        : in  STD_LOGIC; -- clock zur abholung von daten (60 MHz)
			clk_in     : in  std_logic; -- clock daten eingang in buffer
			nreset     : in  STD_LOGIC; -- negativ reset
			din        : in  STD_LOGIC_VECTOR(7 downto 0); -- Daten eingang in buffer
			we         : in  std_logic; -- 1 wenn daten vom DIN einlesen mit jedem clk nedge TODO Ueberlauf kontrolle?
			re         : in  STD_LOGIC; -- Bereitschaft zum Aufnehmen vom FTDI Chip 1 - nicht bereit; 0 - bereit

			-- out        
			dout_ready : out STD_LOGIC; -- Signal Daten abholen fuer FTDI
			dout       : out STD_LOGIC_VECTOR(7 downto 0); -- Datenschnittstelle fuer FTDI
			full       : out STD_LOGIC; -- daten waren nicht abgeholt = 1
			empty      : out STD_LOGIC;
			debug      : out std_logic
		);
	end component switch_fifo;

	component pack_builder is
		generic(
			packet_length : integer                      := 3 + 512 + 2; --  3 sync + 10 data + 2 crc - 
			sync_byte     : STD_LOGIC_VECTOR(7 downto 0) := x"AF"
		);
		Port(clk       : in  STD_LOGIC;
			 nreset    : in  STD_LOGIC;
			 valid     : in  STD_LOGIC;
			 data_in   : in  STD_LOGIC_VECTOR(7 downto 0);
			 rr        : in  STD_LOGIC;
			 ctrl_byte : in  STD_LOGIC_VECTOR(7 downto 0);
			 data_out  : buffer STD_LOGIC_VECTOR(7 downto 0);
			 busy      : out STD_LOGIC;
			 oe        : out STD_LOGIC;
			 pack_ende : out STD_LOGIC;
			 debug     : out STD_LOGIC);
	end component pack_builder;

	component ftdi_sync_ft245 is
		Port(
			clk_60         : out   STD_LOGIC; -- clk to send / read data 
			nreset         : in    STD_LOGIC; -- reset negativ
			we             : in    STD_LOGIC; -- high - data ready to send to FTDI
			re             : out   STD_LOGIC; -- high - data ready to read from FTDI, low not ready 
			ie             : out   std_logic; -- input enable high: ready to read data into FTDI		   
			send_immediate : in    STD_LOGIC; -- send data immediate when high.
			data_in        : in    STD_LOGIC_VECTOR(7 downto 0); -- data to send to FTDI
			data_out       : out   STD_LOGIC_VECTOR(7 downto 0); -- data to read from FTDI
			debug          : out   STD_LOGIC;

			-- to chip   

			clk            : in    STD_LOGIC; -- ausgang vom FTDI-Chip zur datenabholung. (60 Mhz)        
			nrxf           : in    STD_LOGIC; -- When high, do not read data from the FIFO. When low, there is data available in the FIFO
			ntxe           : in    STD_LOGIC; -- Bereitschaft zum datenaufnehmen vom FTDI Chip 1 - nicht bereit; 0 - bereit.
			nrd            : out   STD_LOGIC; -- Enables the current FIFO data byte to be driven onto D0...D7 when RD# goes low. 
			nwr            : out   STD_LOGIC; -- Enables the data byte on the D0...D7 pins to be written into the transmit FIFO buffer when WR# is low. 
			noe            : out   STD_LOGIC; -- ist low dann databus als input Output enable when low to drive data onto D0-7. 
			nsiwu          : out   STD_LOGIC;

			ftdi_data      : inout STD_LOGIC_VECTOR(7 downto 0) -- D7 to D0 bidirectional FIFO data. This bus is normally input unless OE# is low.

		);
	end component ftdi_sync_ft245;

	component edge_detect is
		port(async_sig : in  std_logic;
			 clk       : in  std_logic;
			 rise      : out std_logic;
			 fall      : out std_logic);
	end component edge_detect;

	component crc16_ccit is
		port(data_in          : in  std_logic_vector(7 downto 0);
			 crc_en, rst, clk : in  std_logic;
			 crc_out          : out std_logic_vector(15 downto 0));
	end component crc16_ccit;

	component delayed_sig is
		Port(sig     : in  STD_LOGIC;
			 clk     : in  STD_LOGIC;
			 sig_out : out STD_LOGIC);
	end component delayed_sig;

	component frame_tester is
		generic(
			frames_skip : integer := 1000 -- frames skip
		);
		Port(nreset         : in  STD_LOGIC;
			 clk            : in  STD_LOGIC;
			 receiver_ready : in  STD_LOGIC;
			 oe             : out std_logic;
			 data           : out STD_LOGIC_VECTOR(7 downto 0));
	end component frame_tester;

	function log2(n : natural) return natural;

end package CAM_PKG;

package body CAM_PKG is

	-----------------------------------------------------------------------------
	function log2(n : natural) return natural is
	begin
		for i in 0 to 31 loop
			if (2 ** i) >= n then
				return i;
			end if;
		end loop;
		return 32;
	end log2;

-----------------------------------------------------------------------------

end package body CAM_PKG;
