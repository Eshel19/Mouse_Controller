library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;

entity WDT is
  port (
		clk : in std_logic;
		reset : in std_logic;
		wdt_en : in std_logic;
		clk_rst : in std_logic;
		WDT_done : out std_logic
		);
end entity WDT;


architecture arc_WDT of WDT is
	signal	cnt : NATURAL range 0 to 150000:=0;
	signal 	startWDT : std_logic;
begin

process(clk,reset)
begin
	if(reset='1') then
		startWDT<='0';
	elsif(rising_edge(clk)) then
		startWDT<=clk_rst;
	end if;
end process;

process(clk,reset,clk_rst,wdt_en)
begin
	if(reset ='1' or wdt_en='0' or clk_rst ='1') then
	cnt <=0;
	WDT_done<='0';
	elsif(rising_edge(clk)) then
	if(startWDT='1' or cnt/=0)then
		if(cnt=150000) then
			WDT_done<='1';
			cnt<=0;
		else
			WDT_done<='0';
			cnt<=cnt+1;
		end if;
		end if;
	end if;
end process;
end architecture arc_WDT;