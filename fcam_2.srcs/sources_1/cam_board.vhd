----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date:    09:43:05 03/25/2012 
-- Design Name: 
-- Module Name:    cam_board - Behavioral 
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

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx primitives in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity cam_board is

    Port ( 
    reset : in std_logic; -- reset
-- cam
    cam_dout : in  std_logic_vector (7 downto 0); -- pixel data
	 dclk : in  std_logic; -- pixel sync reisende flanke 
	 vd : in  std_logic; -- vertikal sync
	 hd : in std_logic; -- horisontal sync
	 
	 cam_scl : inout std_logic; -- i2c scl cam
	 cam_sda : inout std_logic; -- i2c sda cam
	 cam_reset : out std_logic; -- reset cam
	 cam_clk : out  std_logic; --- clk input for cam
	 
-- ftdi
	ftdi_din : inout std_logic_vector (7 downto 0) := "00000000";
--	ftdi_scl : inout std_logic;
--	ftdi_sda : inout std_logic;
	ftdi_reset : out std_logic;
	ftdi_rxf : in std_logic;
	ftdi_txe : in std_logic;
	ftdi_rd : out std_logic;
	ftdi_wr : out std_logic;
	ftdi_oe : out std_logic;
    ftdi_siwu : out std_logic;	

			  
-- clk	 
	clk_in : in  std_logic;
    clk_out : out  std_logic;
    
    debug1: out std_logic;
    debug2: out std_logic
    
    );
 
end cam_board;

architecture Behavioral of cam_board is


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

 
BEGIN
 

cam_inst: main port map (
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
          ftdi_scl => open,
          ftdi_sda => open,
          ftdi_reset => ftdi_reset,
          ftdi_rxf  =>    ftdi_rxf,
          ftdi_txe  =>   ftdi_txe,
          ftdi_rd  =>  ftdi_rd,
          ftdi_wr  =>  ftdi_wr,
          ftdi_oe  =>  ftdi_oe,
          ftdi_siwu => ftdi_siwu,
          clk_in => clk_in,
          clk_out => clk_out,
          debug1 => debug1,
          debug2 => debug2
        );
		  
	


end Behavioral;

