library IEEE;
        use IEEE.std_logic_1164.all;
        use IEEE.std_logic_unsigned.all;
		
library work;
        use work.all ;

entity rgb565_register_rom is
    port(
        clk, en	:	in std_logic ;
        data : out std_logic_vector(15 downto 0 );
        addr : in std_logic_vector(7 downto 0 )
    );
end rgb565_register_rom;

architecture vga of rgb565_register_rom is
 
type array_32 is array (0 to 32) of std_logic_vector(15 downto 0 );
	
	signal rom : array_32 :=( 
	(X"02" & X"00"),
	(X"03" & X"02"), 
	(X"1E" & X"68"), 
	(X"04" & X"0F"), -- 1F dauer, 0F - default
	(X"22" & X"10"), 
	(X"24" & X"0F"), 
	(X"28" & X"06"), 
	(X"FF" & X"FF"), -- FF & FF config ende
	(X"00" & X"00"),
	(X"00" & X"00"),
	(X"00" & X"00"),
	(X"00" & X"00"),
	(X"00" & X"00"),
	(X"00" & X"00"),
	(X"03" & X"0a"), 
	(X"0C" & X"00"), 
	(X"3E" & X"00"), 
	(X"70" & X"3a"), 
	(X"71" & X"35"), 
	(X"72" & X"11"), 
	(X"73" & X"f0"), 
	(X"a2" & X"02"),
	(X"15" & X"00"), 
	(X"7a" & X"20"), 
	(X"7b" & X"10"), 
	(X"7c" & X"1e"), 
	(X"7d" & X"35"), 
	(X"7e" & X"5a"), 
	(X"7f" & X"69"), 
	(X"80" & X"76"), 
	(X"81" & X"80"), 
	(X"82" & X"88"), 
	(X"87" & X"c4")

);

--
	begin
	-- rom_process
process(clk)
    begin
        if clk'event and clk = '1' then
            if en = '1' then
                data <= rom(conv_integer(addr)) ;
            end if;
        end if;
end process;  
	
end vga ;

