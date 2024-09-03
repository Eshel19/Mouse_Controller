library ieee;
use ieee.std_logic_1164.all;

entity Int is
  port (
    reset, Int_ena, clock : in std_logic;
    data, Int_done : out std_logic
  );
end entity Int;

architecture arc_Int of Int is
  signal temp_byte : std_logic_vector(10 downto 0);
  signal temp_Int_done : std_logic;
  constant byteZeroes : std_logic_vector(10 downto 0) := (others => '0');

begin
Int_ff : process (clock, reset)
constant outbyte : std_logic_vector := "11111101100";
begin
  if reset = '1' then
	data<='1';
	temp_byte <= outbyte;
  elsif rising_edge(clock) then 
		if Int_ena = '1' and (temp_byte /= byteZeroes) then
        data <= temp_byte(0);
        temp_byte <= '0' & temp_byte(10 downto 1);
		end if;
  end if;
end process Int_ff;

temp_Int_done<='1' when temp_byte = byteZeroes else '0';

process (clock,reset)
begin
	if(reset='1') then
		Int_done<='0';
	elsif(falling_edge(clock)) then
		Int_done<= temp_Int_done and Int_ena;
	end if;
end process;



end architecture arc_Int;
