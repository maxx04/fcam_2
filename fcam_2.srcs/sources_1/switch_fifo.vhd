----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 06.11.2012 20:54:02
-- Design Name: 
-- Module Name: switch_fifo - Behavioral
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
use IEEE.std_logic_unsigned.all;

library UNISIM;
use UNISIM.VComponents.all;

library work;
use work.cam_pkg.all;

entity switch_fifo is
	generic(
		packet_length : positive range 1 to 512  := 3 + 6 + 2; --  3 sync + 10 data + 2 crc - 
		fifo_size     : positive range 1 to 2000 := 9
	);
	Port(
		-- in
		clk        : in  std_logic;     -- clock zur abholung von daten (60 MHz)
		clk_in     : in  std_logic;     -- clock daten eingang in buffer
		nreset     : in  std_logic;     -- negativ reset

		din        : in  std_logic_vector(7 downto 0); -- Dateneingang in buffer
		we         : in  std_logic;     --  wenn 1 die daten vom DIN werden eingelesen mit jedem clk nedge.
		re         : in  std_logic;     -- wenn 1 naechste byte wird mit naechste nedge ausgegeben        
		-- out        
		dout_ready : out STD_LOGIC;     -- daten bereit zum abholen
		dout       : out std_logic_vector(7 downto 0); -- datenausgang

		full       : out std_logic;
		empty      : out std_logic;
		debug      : out std_logic
	);
end switch_fifo;

----------------------------------------------------------------------------
----------------------------------------------------------------------------


architecture flash of switch_fifo is
	signal oe : std_logic := '0';       -- Freigabe Daten Versenden 

	signal cnt_byte_to_output, cnt_byte_out : integer range 0 to 2047 := 0;

	signal switch_buff : boolean := false;

	signal data_out : boolean := false;

	signal do_mem, do_buff, do_buff_temp, do_a, do_b             : std_logic_vector(7 downto 0); -- 8-bit data output
	--signal  dop, dop_a, dop_b:  std_logic_vector (0 downto 0);    -- 1-bit parity output
	signal addr_mem, addr_buff, addr_a, addr_b, last_byte_output : std_logic_vector(10 downto 0); -- 11-bit address input
	signal di_mem, di_buff, di_a, di_b                           : std_logic_vector(7 downto 0); -- 8-bit data input
	signal dip, dip_a, dip_b                                     : std_logic_vector(0 downto 0); -- 1-bit parity input
	--signal  en_a, en_b  :  std_logic;       -- ram enable input
	--      ssr => ssr,    -- synchronous set/reset input
	signal we_mem, we_buff, we_a, we_b                           : std_logic; -- write enable input

	signal buff_b_activ  : boolean   := false; -- gerade / ungerade reihe
	signal flash         : boolean   := false;
	signal last_switch   : boolean   := false;
	signal out_empty     : std_logic := '1';
	signal fifo_overflow : std_logic := '1';
	signal we1, we2      : std_logic;
	
	signal reset : std_logic;

begin
    reset <= not nreset;

	--    RAMB16_S9: 2k x 8 + 1 Parity bit Single-Port RAM
	--               Spartan-3
	--    Xilinx HDL Language Template, version 13.4

	buff_a : RAMB16_S9
		generic map(
			INIT       => X"000",       --  Value of output RAM registers at startup
			SRVAL      => X"000",       --  Ouput value upon SSR assertion
			WRITE_MODE => "WRITE_FIRST", --  WRITE_FIRST, READ_FIRST or NO_CHANGE
			-- The following INIT_xx declarations specify the initial contents of the RAM
			-- Address 0 to ---
			-- Byte 32 downto 0
			INIT_00    => X"0000000000000000000000000000000000000000000000000000060504030201"
		)
		port map(
			do   => do_a,               -- 8-bit Data Output
			dop  => open,               -- 1-bit parity Output
			addr => addr_a,             -- 11-bit Address Input
			clk  => clk,                -- TODO Clock ausgang soll schneller sein als eingang 
			di   => di_a,               -- 8-bit Data Input
			dip  => dip_a,              -- 1-bit parity Input
			en   => '1',                -- RAM Enable Input
			ssr  => reset,         -- Synchronous Set/Reset Input
			we   => we_a                -- Write Enable Input
		);

	buff_b : RAMB16_S9
		generic map(
			INIT       => X"000",       --  Value of output RAM registers at startup
			SRVAL      => X"000",       --  Ouput value upon SSR assertion
			WRITE_MODE => "WRITE_FIRST", --  WRITE_FIRST, READ_FIRST or NO_CHANGE
			-- The following INIT_xx declarations specify the initial contents of the RAM
			-- Address 0 to ---
			-- Byte 32 downto 0
			INIT_00    => X"0000000000000000000000000000000000000000000000000000D6D5D4D3D2D1"
		)
		port map(
			do   => do_b,               -- 8-bit Data Output
			dop  => open,               -- 1-bit parity Output
			addr => addr_b,             -- 11-bit Address Input
			clk  => clk,                -- Clock
			di   => di_b,               -- 8-bit Data Input
			dip  => dip_b,              -- 1-bit parity Input
			en   => '1',                -- RAM Enable Input
			ssr  => reset,         -- Synchronous Set/Reset Input
			we   => we_b                -- Write Enable Input
		);

	addr_a_switch : addr_a <= addr_buff when not buff_b_activ else addr_mem;
	addr_b_switch : addr_b <= addr_buff when buff_b_activ else addr_mem;

	di_a_switch : di_a <= di_mem when buff_b_activ else x"ff";
	di_b_switch : di_b <= di_mem when not buff_b_activ else x"ff";

	do_a_switch : do_buff <= do_b when buff_b_activ else do_a;

	we_a_switch : we_a <= we_buff when not buff_b_activ else we_mem;
	we_b_switch : we_b <= we_buff when buff_b_activ else we_mem;

	addr_buff <= CONV_STD_LOGIC_VECTOR(cnt_byte_out, 11);

	full  <= fifo_overflow;
	empty <= out_empty;

	-- fifo speichert ab adresse 1 !!!!

	save_to_fifo : process(clk_in, clk, nreset)
		variable cnt_byte : integer range 0 to 2047 := 0;

	begin
		if (nreset = '0') then
			we_mem   <= '1';
			we_buff  <= '0';
			addr_mem <= CONV_STD_LOGIC_VECTOR(1, 11);
			cnt_byte := 1;

		elsif (clk_in'event and clk_in = '0') then

			-- umschalten 
			switch_buff <= false;

			if (flash) then
				last_switch <= true;
			end if;

			if (cnt_byte = fifo_size + 1 or (last_switch and not data_out)) then
				switch_buff <= true;
				last_switch <= false;

				cnt_byte_to_output <= cnt_byte - 1;
				cnt_byte           := 1;

				buff_b_activ <= not buff_b_activ;

				we_mem  <= '1';
				we_buff <= '0';

			end if;

			if (we = '1') then
				addr_mem <= CONV_STD_LOGIC_VECTOR(cnt_byte, 11);
				di_mem   <= din;
				cnt_byte := cnt_byte + 1;
			end if;

		end if;

	end process save_to_fifo;

	-----------------------------------------------------------------------------------


	read_from_fifo : process(clk, nreset)
	begin
		if (nreset = '0') then
			cnt_byte_out <= 1;

		elsif (clk'event and clk = '0') then
			data_out <= false;

			if (switch_buff) then
				cnt_byte_out <= 1;
			else
				if (re = '1' and cnt_byte_out <= cnt_byte_to_output) then
					dout         <= do_buff;
					cnt_byte_out <= cnt_byte_out + 1;
					data_out     <= true;
				else
					null;
				end if;

			end if;

		end if;

	end process read_from_fifo;

	output_en_proc : dout_ready <= '1' when data_out else '0';

	fifo_overflow <= '1' when out_empty = '0' and switch_buff else '0';

	flash_proc : process(clk, nreset)
	begin
		if (nreset = '0') then
			flash <= false;
			we1   <= '0';

		elsif (clk'event and clk = '0') then
			if (we1 = '1' and we = '0') then
				flash <= true;
			else
				flash <= false;
			end if;

			we1 <= we;

		end if;

	end process flash_proc;

	db : debug <= fifo_overflow;
--
end flash;

architecture test of switch_fifo is
  
begin
	I_frame_tester : frame_tester
		generic map(frames_skip => 4000)
		port map(nreset         => nreset,
			     clk            => clk,
			     receiver_ready => re,
			     oe             => dout_ready,
			     data           => dout);

end test;


