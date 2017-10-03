----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 26.10.2012 20:04:00
-- Design Name: 
-- Module Name: pack_builder - Behavioral
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
--

entity pack_builder is
	generic(
		packet_length : integer                      := 3 + 1 + 7 + 2; --   sync + ctrl + data + crc  
		sync_byte     : STD_LOGIC_VECTOR(7 downto 0) := x"AF"
	);
	Port(clk       : in  STD_LOGIC;
		 nreset    : in  STD_LOGIC;
		 valid     : in  STD_LOGIC;     -- 1 - data input valid an steigende flanke
		 data_in   : in  STD_LOGIC_VECTOR(7 downto 0); -- eingangsdaten
		 rr        : in  STD_LOGIC;     -- read enable - empfaenger ist ready data zu empfangen
		 ctrl_byte : in  STD_LOGIC_VECTOR(7 downto 0); -- wird eingelesen nach sync_bytes 
		 data_out  : buffer STD_LOGIC_VECTOR(7 downto 0); -- ausgangsdaten
		 busy      : out STD_LOGIC;     -- packer ist beschaeftigt
		 oe        : out STD_LOGIC;     -- ausgangsdaten valid und duerfen ausgelesen werden
		 pack_ende : out STD_LOGIC;     -- 1 - packet ende
		 debug     : out STD_LOGIC);
end pack_builder;

architecture first of pack_builder is
	signal crc_value        : std_logic_vector(15 downto 0);
	signal crc_en           : std_logic                    := '0';
	signal crc_reset        : std_logic                    := '0';
	signal crc_result       : std_logic_vector(15 downto 0);
	signal data             : std_logic_vector(7 downto 0) := x"00";
	signal valid_intern     : std_logic                    := '0';
	signal data_in_use      : boolean                      := false; -- noch nicht ausgegebene daten in data register
	signal re_was_not_ready : boolean                      := false;

	component crc16_ccit is
		port(data_in          : in  std_logic_vector(7 downto 0);
			 crc_en, rst, clk : in  std_logic;
			 crc_out          : out std_logic_vector(15 downto 0));
	end component crc16_ccit;

	signal x       : positive range 1 to 1024 := 1;
	signal started : boolean                  := false; -- start_pck kommt 2 mal vor wegen dclk (clk = 2*dclk)

begin
	crc16_inst : crc16_ccit port map(
			data_in => data_out,
			crc_en  => crc_en,
			rst     => crc_reset,
			clk     => clk,
			crc_out => crc_value);

	data <= data_in when rr = '1' else data;

	send_data : process(clk, nreset)
	begin
		if (nreset = '0') then
			x                <= 1;
			oe               <= '0';
			busy             <= '1';
			pack_ende        <= '0';
			started          <= false;
			data_in_use      <= false;
			re_was_not_ready <= false;

		elsif (clk'event and clk = '0') then
			busy <= '0';
			oe   <= '0';

			valid_intern <= valid;

			if (valid = '1') then
				data_in_use <= true;
			end if;

			if (rr = '1') then
				re_was_not_ready <= false;

				case x is
					when 1 | 2 =>
						data_out  <= x"ff";
						pack_ende <= '1';
						started   <= true;
						crc_en    <= '0';
						crc_reset <= '1';
						busy      <= '1';
						oe        <= '1';
						x         <= x + 1;

					when 3 | 4 | 5 =>
						data_out  <= sync_byte;
						pack_ende <= '0';
						started   <= true;
						crc_en    <= '0';
						crc_reset <= '1';
						busy      <= '1';
						oe        <= '1';
						x         <= x + 1;

					when 6 =>
						data_out  <= ctrl_byte;
						crc_en    <= '1';
						crc_reset <= '0';
						busy      <= '0';
						oe        <= '1';
						x         <= x + 1;

					when packet_length - 2 =>
						if (valid = '1' or data_in_use) then
							busy   <= '1';
							oe     <= '1';
							crc_en <= '1';

							data_out    <= data;
							data_in_use <= false;

							x <= x + 1;
						else
							busy   <= '0';
							crc_en <= '0';
							oe     <= '0';
						end if;

					when packet_length - 1 =>
						oe       <= '1';
						crc_en   <= '0';
						data_out <= crc_value(15 downto 8);
						busy     <= '1';
						x        <= x + 1;

					when packet_length =>
						oe         <= '1';
						crc_result <= crc_value;
						data_out   <= crc_value(7 downto 0);
						crc_en     <= '0';
						pack_ende  <= '0'; -- am anfang wird ausgegeben wegen buffer flash
						busy       <= '1';
						started    <= false;
						x          <= 1;

					when others =>
						busy <= '0';
						if (valid = '1' or data_in_use) then
							oe        <= '1';
							crc_reset <= '0';
							crc_en    <= '1';
							if (re_was_not_ready) then
								re_was_not_ready <= false;
							else
								data_out    <= data;
								data_in_use <= false;
							end if;
							x <= x + 1;
						else
							oe     <= '0';
							crc_en <= '0';
						end if;

				end case;

			else
				oe     <= '0';
				busy   <= '1';
				crc_en <= '0';

				data_out         <= data;
				re_was_not_ready <= true;

			end if;

		end if;

	end process send_data;

end architecture first;

architecture through of pack_builder is
begin
	data_out <= data_in;
	busy     <= not rr;
	oe       <= valid;

end through;

architecture test of pack_builder is
signal data_buff             : std_logic_vector(7 downto 0) := x"00";


begin
data_out <= data_buff;

	I_frame_tester : frame_tester
		generic map(frames_skip => 4000)
		port map(nreset         => nreset,
			     clk            => clk,
			     receiver_ready => rr,
			     oe             => oe,
			     data           => data_buff);

end architecture test;

architecture RTL of pack_builder is
	-- rr unterbrechung ist minimum 2 Takte länge, sonst Fehlfunktion


	signal crc_value                                    : std_logic_vector(15 downto 0);
	signal crc_en                                       : std_logic                    := '0';
	signal crc_reset                                    : std_logic                    := '0';
	signal crc_result                                   : std_logic_vector(15 downto 0);
	signal data                                         : std_logic_vector(7 downto 0) := x"00";
	signal stop_pack, control_data_ready, output_enable : std_logic                    := '0';
	signal valid_fall_edge, stop_pack_delayed           : std_logic;
	signal valid_delayed                                : std_logic;
	signal receiver_ready_delayed                       : std_logic;
	signal crc_en_delayed, crc_oe                       : std_logic;
	signal data_in_pipe_in                              : boolean                      := false; -- noch nicht ausgegebene daten in data_in register
	signal data_in_pipe_out                             : boolean                      := false; -- noch nicht ausgegebene daten in data_out register
	--	signal re_was_not_ready : boolean                      := false;

	signal byte_pos     : integer range 0 to 511;
	signal byte_pos_out : std_logic_vector(10 downto 0);

	signal started : boolean := false;  -- start_pck kommt 2 mal vor wegen dclk (clk = 2*dclk)
	
	signal nclk: std_logic;

	for all : delayed_sig use entity work.delayed_sig(RTL);

begin

nclk <= not clk;

	I_crc16 : crc16_ccit
		port map(
			data_in => data_out,
			crc_en  => crc_oe,
			rst     => crc_reset,
			clk     => nclk,
			crc_out => crc_value);

	I_valid_fall_edge : edge_detect
		port map(async_sig => valid,
			     clk       => nclk,
			     rise      => open,
			     fall      => valid_fall_edge);

	I_delayed_receiver_ready : delayed_sig
		Port map(sig     => rr,
			     clk     => clk,
			     sig_out => receiver_ready_delayed);

	busy   <= stop_pack;
	oe     <= output_enable;
	crc_oe <= '1' when crc_en_delayed = '1' and output_enable = '1' else '0';

	data_cntr : process(clk, nreset)
	begin
		if (nreset = '0') then
			data_out        <= x"EE";
			data_in_pipe_in <= false;

		elsif clk'event and clk = '0' then
			if valid = '1' then
				data_in_pipe_in <= false;
			end if;

			if valid = '1' and valid_fall_edge = '0' and (control_data_ready = '1' or receiver_ready_delayed = '0') then
				data_in_pipe_in <= true;
			end if;

			if data_in_pipe_in and stop_pack = '0' then
				data_in_pipe_in <= false;
			end if;

			if receiver_ready_delayed = '1' then
				if control_data_ready = '1' then
					if (byte_pos = packet_length) then
						data_out <= crc_value(15 downto 8);
					else
						data_out <= data;
					end if;

				elsif valid = '1' or data_in_pipe_in then
					data_out <= data_in;

				end if;

			end if;
		end if;
	end process data_cntr;

	oe_cntr : process(clk, nreset)
	begin
		if (nreset = '0') then
			byte_pos         <= 1;
			output_enable    <= '0';
			data_in_pipe_out <= false;

		elsif clk'event and clk = '0' then
			output_enable <= '0';

			if rr = '1' then
				if control_data_ready = '1' or valid = '1' or (data_in_pipe_in and receiver_ready_delayed = '1') or data_in_pipe_out then
					output_enable    <= '1';
					byte_pos         <= byte_pos + 1;
					byte_pos_out     <= conv_std_logic_vector(byte_pos, 11); -- TODO automatische Breite
					data_in_pipe_out <= false;
				end if;

				if byte_pos = packet_length then
					byte_pos <= 1;

				end if;
			else
				if receiver_ready_delayed = '1' and (valid = '1' or control_data_ready = '1' or data_in_pipe_in) then
					data_in_pipe_out <= true;
				end if;
			end if;
		end if;
	end process oe_cntr;

	pack_cntr : process(clk, nreset)
	begin
		if (nreset = '0') then
			stop_pack <= '1';
			pack_ende <= '0';
			started   <= false;

		elsif clk'event and clk = '0' then
			control_data_ready <= '0';
			stop_pack          <= '1';
			crc_en             <= '0';

			if rr = '1' then
				case byte_pos is
					when 1 | 2 =>
						data               <= x"ff";
						pack_ende          <= '1';
						started            <= true;
						crc_reset          <= '1';
						control_data_ready <= '1';

					when 3 | 4 | 5 =>
						data               <= sync_byte;
						pack_ende          <= '0';
						control_data_ready <= '1';

					when 6 =>
						data               <= ctrl_byte;
						crc_en             <= '1';
						crc_reset          <= '0';
						control_data_ready <= '1';

					when packet_length - 1 =>
						control_data_ready <= '1';
						data               <= crc_value(15 downto 8);

					when packet_length =>
						control_data_ready <= '1';
						crc_result         <= crc_value;
						data               <= crc_value(7 downto 0);
						pack_ende          <= '0'; -- am anfang wird ausgegeben wegen buffer flash
						started            <= false;

					when others =>
						stop_pack <= '0';
						crc_en    <= '1';

				end case;

				crc_en_delayed <= crc_en;

			end if;

		end if;

	end process pack_cntr;

end RTL;