library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity ParallelToSerial is

port (
	clk   : in  std_logic;
	reset : in  std_logic;
	ena   : in  std_logic;
	data  : in  std_logic_vector(10 downto 0);
	valid : out std_logic;
	serial_out : out std_logic
    );
end entity ParallelToSerial;

architecture arc_ParallelToSerial of ParallelToSerial is
    signal data_reg     : std_logic_vector(10 downto 0);
    signal bit_counter  : natural range 0 to 11 :=0 ;
    signal valid_reg    : std_logic;
begin
process (clk,reset)
variable shift_reg : std_logic_vector(10 downto 0);
variable tmp_cnt  : natural range 0 to 11 :=0;
begin
	if(reset='1') then
	tmp_cnt:= 0;
	serial_out<='1';
	valid<='0';
	shift_reg:= (others=>'0');
	elsif(rising_edge(clk)) then
		if(bit_counter=0) then valid<='0';
		elsif(bit_counter=10) then valid<='1';
		
		end if;
			if(ena='1') then
				tmp_cnt:=bit_counter;
				if(tmp_cnt=0) then
					shift_reg := data;
				else
					shift_reg := data_reg;
				end if;
				serial_out<=shift_reg(0);
				shift_reg:='0' & shift_reg(10 downto 1);
				tmp_cnt:= tmp_cnt+1;
				if(tmp_cnt=11) then	
					valid<='1';
					tmp_cnt:= 0;	
				end if;	
		end if;
	end if;
	data_reg<=shift_reg;
	bit_counter<=tmp_cnt;
end process;
end arc_ParallelToSerial;
