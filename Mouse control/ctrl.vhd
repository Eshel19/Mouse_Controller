library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;

entity ctrl is
  port (
	Int_ena,Output_buffer_ena,Set_bytes,clock : out std_logic;
	Int_done,DataSended,reset : in std_logic;
	clk_50MHz : in std_logic;
	ena_byte : out std_logic_vector(2 downto 0);
	done_byte : in std_logic_vector(2 downto 0)
  );
end entity ctrl;

architecture arc_ctrl of ctrl is
	type ctrl_state is (poweoff,startup,Receive_data,Byte1,Byte2,Byte3,Finish_Receive,error);
	signal present_state: ctrl_state:=poweoff;
	signal next_state: ctrl_state:=startup;
	signal Int_ena_temp,Output_buffer_ena_temp,Set_bytes_temp : std_logic;
	signal ena_byte_temp : std_logic_vector(2 downto 0);
	signal counter : natural range 0 to 2600 := 0;
	signal clock_temp : std_logic :='0';
begin
outFF : process (clk_50MHz,reset)
begin 
	if (reset='1') then
		present_state<=poweoff;
		Int_ena <='0';
		Output_buffer_ena <='0';
		Set_bytes <='0';
		ena_byte<="000";
		elsif rising_edge(clk_50MHz) then
			present_state<=next_state;
			Int_ena <=Int_ena_temp;
			Output_buffer_ena <=Output_buffer_ena_temp;
			Set_bytes <=Set_bytes_temp;
			ena_byte<=ena_byte_temp;
		end if;
		
end process outFF;

Clk_10khz_generetor : process(clk_50MHz,reset)
begin
	if(reset='1') then 
	counter <=0;
	clock_temp <= '0';
    elsif rising_edge(clk_50MHz) then
        if Int_ena_temp  = '1' then
            if counter = 2600 then -- 50Mhz / 10Khz = 5000 then ever 2600 clk_50MHz ticks we get 10Khz clock with 50 % Duty cycle
                counter <= 0;
                clock_temp <= not clock_temp;
				else
					counter <= counter + 1;
            end if;
				
        end if;
    end if;
end process Clk_10khz_generetor;
clock <= clock_temp;



statmachine : process (present_state,Int_done,done_byte,DataSended,clock_temp)
begin
	Int_ena_temp<='0';
	Output_buffer_ena_temp<='0';
	Set_bytes_temp<='0';
	ena_byte_temp<="000";
	case present_state is
	when poweoff=> next_state<=startup;
	when startup=>	Int_ena_temp<='1';
						if(Int_done='1' and clock_temp='0') then
							next_state<=Receive_data;
							Set_bytes_temp<='1';	
						else
							next_state<=startup;
						end if;
	
	when Receive_data=>
						ena_byte_temp(0)<='1';
						next_state<=Byte1;
	when Byte1=>	
						if(done_byte(0)='1') then
							next_state<=Byte2;
							ena_byte_temp(1)<='1';
						else
							ena_byte_temp(0)<='1';
							next_state<=Byte1;
						end if;
	
	when Byte2=>
						if(done_byte(1)='1') then
							next_state<=Byte3;
							ena_byte_temp(2)<='1';
						else
							ena_byte_temp(1)<='1';
							next_state<=Byte2;
						end if;
	
	when Byte3=>
						if(done_byte(2)='1') then
							next_state<=Finish_Receive;
						else
							ena_byte_temp(2)<='1';
							next_state<=Byte3;
						end if;
	
	when Finish_Receive=>
						if(DataSended='1') then
							next_state<=Receive_data;
							Output_buffer_ena_temp<='0';
							Set_bytes_temp<='1';
						else
							next_state<=Finish_Receive;
							Output_buffer_ena_temp<='1';
						end if;
	when others=> next_state<=error;
	end case;
end process statmachine;

end architecture arc_ctrl;