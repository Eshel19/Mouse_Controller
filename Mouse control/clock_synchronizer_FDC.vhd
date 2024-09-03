library ieee;
use ieee.std_logic_1164.all;

entity clock_synchronizer_FDC is
  port (
    reset,en,clk_50MHz,clock_in : in std_logic;
    clock_out : out std_logic
  );
end entity clock_synchronizer_FDC;

architecture arc_clock_synchronizer_FDC of clock_synchronizer_FDC is
signal q_out: std_logic_vector(2 downto 0);
begin
process(reset,clk_50MHz)
begin
	if(reset='1') then
	q_out<=(others=>'0');
	elsif(rising_edge(clk_50MHz)) then
			
		if(en='1') then
			q_out(0) <=clock_in;
			q_out(1) <=q_out(0);
			q_out(2) <=q_out(1);
		end if;
	end if;
end process;
clock_out <= q_out(2) and not q_out(1);

end architecture arc_clock_synchronizer_FDC;