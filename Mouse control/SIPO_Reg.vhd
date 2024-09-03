library ieee;
use ieee.std_logic_1164.all;

--This component is outputing an parral output accourding to the protocol if the data will not start with 0 and end will one 
--it will output an vector of 1 , the reg will only update once it finish receiving the seriel data

entity SIPO_Reg is
  port (
	done : out std_logic;
	clock,ena,data_in,Set_bytes,reset,wdt_bark : in std_logic;
	data_out: out std_logic_vector(8 downto 0)
  );
end entity SIPO_Reg;

architecture arc_SIPO_Reg of SIPO_Reg is
signal temp_byte : std_logic_vector(10 downto 0);
signal ena_zero : std_logic;
signal set_rst :std_logic;
constant renew_byte : std_logic_vector(10 downto 0) := (others =>'1');
begin

ena_zero<= not data_in when (temp_byte = renew_byte) else temp_byte(0);
set_rst <=ena and wdt_bark;

process (clock,reset,Set_bytes)
begin
	if(reset = '1' or Set_bytes='1' or set_rst ='1') then
		temp_byte <=renew_byte;
		elsif (rising_edge(clock)) then
			if(ena='1' and ena_zero='1') then
			temp_byte <= data_in & temp_byte(10 downto 1);
			end if;
	end if;
end process;
-- check if the byte got send correctly by the PS2 protcol start 0 end 1 
data_out <= temp_byte(9 downto 1) when (temp_byte(0) ='0' and temp_byte(10) ='1') else (others=>'0');
done <= not temp_byte(0);

end architecture arc_SIPO_Reg;
