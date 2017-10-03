----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date:    20:42:13 10/10/2011 
-- Design Name: 
-- Module Name:    ios - Behavioral 
-- Project Name: 
-- Target Devices: 
-- Tool versions: 
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
use work.cam_lib.all;

use work.cam_pkg.all;

entity main is
	Port(
		reset      : in    std_logic;   -- reset
		-- main
		cam_dout   : in    std_logic_vector(7 downto 0); -- pixel data
		dclk       : in    std_logic;   -- pixel sync reisende flanke
		vd         : in    std_logic;   -- vertikal sync
		hd         : in    std_logic;   -- horisontal sync

		cam_scl    : inout std_logic;   -- i2c scl cam
		cam_sda    : inout std_logic;   -- i2c sda cam
		cam_reset  : out   std_logic;   -- reset cam
		cam_clk    : out   std_logic;   --- clk input for cam

		-- ftdi
		ftdi_din   : inout std_logic_vector(7 downto 0) := x"00";
		ftdi_scl   : inout std_logic;
		ftdi_sda   : inout std_logic;
		ftdi_reset : out   std_logic;
		ftdi_rxf   : in    std_logic;
		ftdi_txe   : in    std_logic;
		ftdi_rd    : out   std_logic;
		ftdi_wr    : out   std_logic;
		ftdi_oe    : out   std_logic;
		ftdi_siwu  : out   std_logic;
		-- clk
		clk_in     : in    std_logic;
		clk_out    : out   std_logic;

		debug1     : out   std_logic;
		debug2     : out   std_logic
	);

end entity main;

-----------------------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------------

architecture fifo_cam of main is
	signal clk : std_logic;

	signal frame_start : std_logic;
	signal frame_end   : std_logic;
	signal line_start  : std_logic;
	signal line_end    : std_logic;
	signal code        : std_logic;

	constant bytes_pro_pixel : integer := G_PIXEL_BYTES;

	constant window_start_x : integer := 11; --pixel
	constant window_start_y : integer := 11; --pixel
	constant window_size    : integer := G_LINE_WIDTH; --pixel

	for all : DividerN use entity work.DividerN(small);

	component cam_code is
		Port(
			din         : in  std_logic_vector(7 downto 0);
			reset       : in  std_logic;
			clk         : in  std_logic;

			code        : out std_logic;
			frame_start : out std_logic;
			frame_end   : out std_logic;
			line_start  : out std_logic;
			line_end    : out std_logic
		);

	end component cam_code;

	component cam_config is
		Port(
			clk    : in    STD_LOGIC;
			nReset : in    STD_LOGIC;
			scl    : inout STD_LOGIC;
			sda    : inout STD_LOGIC;
			debug  : out   std_logic
		);
	end component cam_config;

	signal cam_out_ready       : std_logic; -- data out from cam ready
	signal ftdi_ie             : std_logic; -- ftdi ready to read data
	signal pack_data_out_ready : std_logic := '0'; -- data out from pack_builder ready
	signal ftdi_data_out_ready : std_logic := '0'; -- data out from ftdi ready
	signal pack_ende           : std_logic := '1';
	signal se, pe              : std_logic := '0';
	signal error               : std_logic := '0';

	signal fifo_empty, fifo_overflow : std_logic := '1';
	signal pack_builder_busy         : std_logic := '0';
--	signal data_to_ftdi_ready        : std_logic := '0';
	signal ftdi_ready                : std_logic := '0';
	signal can_read_fifo             : std_logic := '0';
	signal data                      : STD_LOGIC_VECTOR(7 downto 0);
	signal ctrl_byte                 : STD_LOGIC_VECTOR(7 downto 0);
	signal data_to_ftdi              : STD_LOGIC_VECTOR(7 downto 0);
	signal data_to_packbuld          : STD_LOGIC_VECTOR(7 downto 0) := x"00";

	signal data_from_ftdi : STD_LOGIC_VECTOR(7 downto 0);

	type byte_array is array (0 to 3) of std_logic_vector(7 downto 0);
	signal start_sync : byte_array := (x"f3", x"f3", x"f3", x"fe");

	signal fifo_ready : std_logic := '0';
	signal pause_done : boolean   := true;
	signal overfl     : std_logic := '0';
	
	signal nreset : std_logic;
	signal npack_builder_busy : std_logic;

	for inst_switch_fifo : switch_fifo use entity work.switch_fifo(flash);
	for inst_pack_builder : pack_builder use entity work.pack_builder(test);
	for ftdi : ftdi_sync_ft245 use entity work.ftdi_sync_ft245(read);
-------------------------------------------------------------------------

begin
	cam_reset  <= reset;
	ftdi_reset <= reset;
	nreset <= not reset;
	
	npack_builder_busy <= not pack_builder_busy;

	debug1 <= '1' when ftdi_txe = '1' else '0';

	div_inst_cam : DividerN
		generic map(divide_value => 2)
		port map(clk => clk_in, reset => nreset, clk_out => cam_clk, tc => open);

	cam_config_inst : cam_config
		port map(
			clk    => clk_in,
			nReset => reset,
			scl    => cam_scl,
			sda    => cam_sda,
			debug  => open
		);

	code_inst : cam_code
		port map(
			din         => cam_dout,
			reset       => reset,
			clk         => dclk,
			code        => code,
			frame_start => frame_start,
			frame_end   => frame_end,
			line_start  => line_start,
			line_end    => line_end
		);

	inst_switch_fifo : switch_fifo
		generic map(
			packet_length => GL_PACKET_LENGTH,
			fifo_size     => 1800)
		Port map(
			clk        => clk,          -- clock zur abholung von daten (60 MHz)
			clk_in     => dclk,         -- clock daten eingang in buffer
			nreset     => reset,        -- negativ reset
			din        => data,         -- Daten eingang in buffer
			we         => cam_out_ready,
			re         => npack_builder_busy, -- read enable 1 - wird auslesen ; 0 - nicht bereit 
			-- (1 zyklus verzoegerung)
			-- out
			dout_ready => fifo_ready,
			dout       => data_to_packbuld,
			full       => fifo_overflow,
			empty      => open,
			debug      => open
		);

	inst_pack_builder : pack_builder
		generic map(
			packet_length => GL_PACKET_LENGTH,
			sync_byte     => x"AF")
		port map(
			clk       => clk, 
			nreset    => reset,
			valid     => fifo_ready,
			data_in   => data_to_packbuld,
			rr        => ftdi_ready,
			ctrl_byte => ctrl_byte,
			data_out  => data_to_ftdi,
			busy      => pack_builder_busy,
			oe        => pack_data_out_ready,
			pack_ende => pe,
			debug     => open
		);

	ftdi_ready <= '1' when (ftdi_ie = '1') else '0';

	ftdi : ftdi_sync_ft245 port map(
			clk_60         => clk,
			nreset         => reset,
			we             => pack_data_out_ready, -- write enable
			re             => ftdi_data_out_ready, -- read enable
			ie             => ftdi_ie,  -- ftdi ready receive data
			send_immediate => se,       -- send data immediate.
			data_in        => data_to_ftdi, -- data to send to FTDI
			data_out       => data_from_ftdi, -- data to read from FTDI
			debug          => open,

			-- chip connections
			clk            => clk_in,   -- 60 MHz from chip
			nrxf           => ftdi_rxf,
			ntxe           => ftdi_txe,
			nrd            => ftdi_rd,
			nwr            => ftdi_wr,
			noe            => ftdi_oe,
			nsiwu          => ftdi_siwu,
			ftdi_data      => ftdi_din
		);

	flash_ftdi_usb : se <= '1' when (pe = '1' and clk = '1') else '0';

	save_pixels : process(dclk, reset)
		variable x          : integer range 0 to 2560 := 0;
		variable y          : integer range 0 to 1024 := 0;
		variable byte_count : integer range 0 to 7    := 0;

		variable window_end : boolean := false;

	begin
		if (reset = '0') then
			cam_out_ready <= '0';
			x             := 0;
			y             := 0;
			window_end    := false;
			byte_count    := 0;

		elsif (dclk'event and dclk = '1') then
			cam_out_ready <= '0';

			if (line_start = '1') then
				x := 0;

			elsif (line_end = '1') then
				y := y + 1;
				x := x + 1;             -- byteposition weiter gez�hlt

			elsif (frame_start = '1') then
				y := 0;
				x := 0;

			-- end if;

			elsif (y >= window_start_y and y < window_start_y + window_size) then -- pixel in Window drin

				if (x >= window_start_x * bytes_pro_pixel and x < (window_start_x + window_size) * bytes_pro_pixel) then -- pixel in Window drin

					cam_out_ready <= '1';

				end if;

			end if;

			if (overfl = '1') then
				data <= x"ff";
			else
--							    data <= cam_dout;
				data <= CONV_STD_LOGIC_VECTOR(x, 8);
			end if;

			ctrl_byte <= x"00";

			x := x + 1;                 -- byteposition weiter gezaehlt


			if (frame_end = '1' or window_end) then
				window_end := true;

				if (byte_count = 4) then
					window_end := false; -- nur dann true wenn packet geschlossen ist
					byte_count := 0;

				else
					data          <= start_sync(byte_count);
					byte_count    := byte_count + 1;
					cam_out_ready <= '1';

				--			if pe = '1' then
				-- zuerst leerbytes
				-- berechnen position im packet um leer zu fahren
				-- flash für fifo?, nein wird ausgesaugt
				-- dann frame sync 
				-- fifo flash leer fahren
				-- pc soll restliche bytes ignorieren oder packets mit anzahl bytes hinzufügen 
				-- (z.B. 256 und internem buffer um bytes zu zahlen)

				--			end if;

				end if;

			end if;

		end if;

	end process save_pixels;

	overflow_check : process(clk, reset) is
	begin
		if reset = '0' then
			debug2 <= '0';
			overfl <= '0';

		elsif (clk'event and clk = '0') then
			if (fifo_overflow = '1') then
				debug2 <= '1';
				overfl <= '1';
			end if;

		end if;
	end process overflow_check;

end architecture fifo_cam;
