library ieee;
use ieee.std_logic_1164.all;

entity Mouse_control_tb is
end entity Mouse_control_tb;

architecture arc_Mouse_control_tb of Mouse_control_tb is
signal clk_50Mhz,clk_50Mhz_en,clk_10khz,clk_10khz_en : std_logic:= '0';
signal byte1,byte2,byte3,byte_out : std_logic_vector(10 downto 0);
signal data_from_unit : std_logic_vector(7 downto 0);
signal reset,clock_in,clock_out,data_in,data_out,clock,ndone_reciving,data,reciving,recivingdata,clock_in_sync,done_reciving,send_byte,reset_sender,finishToSend : std_logic;
signal x_mov : std_logic_vector(8 downto 0);
signal y_mov : std_logic_vector(8 downto 0);
signal data_in_Paralle : std_logic_vector(8 downto 0);
signal valid : std_logic;

component Mouse_control is
    port (
		clk_50MHz : in std_logic;
		reset : in std_logic;
		data : inout std_logic;
		clock : inout std_logic;
		x_mov : out std_logic_vector(8 downto 0);
		y_mov : out std_logic_vector(8 downto 0);
		valid : out std_logic );
end component Mouse_control;

component SIPO_Reg is
  port (
	done : out std_logic;
	clock,ena,data_in,Set_bytes,reset,wdt_bark : in std_logic;
	data_out: out std_logic_vector(8 downto 0)
  );
end component SIPO_Reg;

component ParallelToSerial is
    port (
		clk   : in  std_logic;
		reset : in  std_logic;
		ena   : in  std_logic;
		data  : in  std_logic_vector(10 downto 0);
		valid : out std_logic;
		serial_out : out std_logic
    );
end component ParallelToSerial;

component clock_synchronizer_FDC is
  port (
    reset,en,clk_50MHz,clock_in : in std_logic;
    clock_out : out std_logic
  );
end component clock_synchronizer_FDC;

begin


clk_50MHZ_generetor : process -- generetor 50mhz clock 
begin
	clk_50mhz <= not clk_50mhz;
	wait for 10 ns;
end process clk_50MHZ_generetor;

clk_10khz_generetor : process -- generetor 10.2khz clock 
begin
	clk_10khz <= not clk_10khz;
	wait for 49 us;
end process clk_10khz_generetor;

Mouse_control_unit : Mouse_control port map(
		clk_50MHz =>clk_50MHz,
		reset=>reset,
		data =>data,
		clock =>clock,
		x_mov => x_mov,
		y_mov => y_mov,
		valid =>valid
		);
		
		
ndone_reciving<= (not done_reciving);
synchronizer :clock_synchronizer_FDC port map(
	 reset=>reset,
	 en =>ndone_reciving,
	 clk_50MHz =>clk_50MHz,
	 clock_in =>clock_in,
    clock_out => clock_in_sync);

ParallelToSerial_send_unit : ParallelToSerial port map(
		clk =>clk_10khz,
		reset =>reset_sender,
		ena =>send_byte,
		data =>byte_out,
		valid => finishToSend,
		serial_out=>data_out
	);
	 
recieve_reg : SIPO_Reg port map(
		done=>done_reciving,
		clock=>clock_in_sync,
		ena=>reciving,
		data_in=>data_in,
		Set_bytes=>reset,
		reset=>reset,
		data_out=>data_in_Paralle,
		wdt_bark => '0'
	);


data <= data_out when (reciving='0') else 'Z';
data_in <= data when (reciving='1') else 'Z';
clock <= (clk_10khz and clk_10khz_en) when (reciving='0') else 'Z';
clock_in <= clock when (reciving='1') else 'Z';

test_run : process
begin
	data_from_unit<=(others=>'0');
	send_byte<='0';
	reset <='1';
	wait for 1 us;
	reset <='0';
	reciving <='1';
	wait until done_reciving ='1';
	data_from_unit<= data_in_Paralle(7 downto 0);
	assert data_in_Paralle="111110110" report "Test fail didnt send x'F6" severity error;
	wait until falling_edge(clk_10khz);
	reciving <='0';
	clk_10khz_en<='1';
--case 1 send correct byte set of bytes Valid-OK no overflow
	reset_sender<='1';
	send_byte<='0';
	byte1 <="11001111110";
	byte2	<="11111111110";
	byte3	<="11111111110";
	wait for 20 ns;
	reset_sender<='0';
	wait for 20 ns;
	send_byte<='1';
	byte_out<=byte1;
	wait until finishToSend='1';
	reset_sender<='1';
	send_byte<='0';
	wait for 20 ns;
	reset_sender<='0';
	wait for 20 ns;
	send_byte<='1';
	byte_out<=byte2;
	wait until finishToSend='1';
	reset_sender<='1';
	send_byte<='0';
	wait for 20 ns;
	reset_sender<='0';
	wait for 20 ns;
	send_byte<='1';
	byte_out<=byte3;
	wait until finishToSend='1';
	wait until valid='1';
	assert (y_mov=byte1(6) & byte3(8 downto 1)) and (x_mov=byte1(5) & byte2(8 downto 1)) report "Test fail Valid-OK no overflow" severity error;
	wait until valid='0';
	wait for 100 ns;

--case 2 send correct byte set of bytes Valid-OK Y-overflow
	reset_sender<='1';
	send_byte<='0';
	byte1 <="10101111110";
	byte2	<="11111111000";
	byte3	<="11111111000";
	wait for 20 ns;
	reset_sender<='0';
	wait for 20 ns;
	send_byte<='1';
	byte_out<=byte1;
	wait until finishToSend='1';
	reset_sender<='1';
	send_byte<='0';
	wait for 20 ns;
	reset_sender<='0';
	wait for 20 ns;
	send_byte<='1';
	byte_out<=byte2;
	wait until finishToSend='1';
	reset_sender<='1';
	send_byte<='0';
	wait for 20 ns;
	reset_sender<='0';
	wait for 20 ns;
	send_byte<='1';
	byte_out<=byte3;
	wait until finishToSend='1';
	wait until valid='1';
	assert (y_mov="000000000") and (x_mov=byte1(5) & byte2(8 downto 1)) report "Test fail Valid-OK ; Y-overflow" severity error;
	wait until valid='0';
	wait for 100 ns;

--case 3 send correct byte set of bytes Valid-OK X-overflow
	reset_sender<='1';
	send_byte<='0';
	byte1 <="10011111110";
	byte2	<="11111100110";
	byte3	<="11111100110";
	wait for 20 ns;
	reset_sender<='0';
	wait for 20 ns;
	send_byte<='1';
	byte_out<=byte1;
	wait until finishToSend='1';
	reset_sender<='1';
	send_byte<='0';
	wait for 20 ns;
	reset_sender<='0';
	wait for 20 ns;
	send_byte<='1';
	byte_out<=byte2;
	wait until finishToSend='1';
	reset_sender<='1';
	send_byte<='0';
	wait for 20 ns;
	reset_sender<='0';
	wait for 20 ns;
	send_byte<='1';
	byte_out<=byte3;
	wait until finishToSend='1';
	wait until valid='1';
	assert (y_mov=byte1(6) & byte3(8 downto 1)) and (x_mov="000000000") report "Test fail Valid-OK X-overflow" severity error;
	wait until valid='0';
	wait for 100 ns;
		
--case 4 send correct byte set of bytes Valid-OK ; X&Y-overflow
	reset_sender<='1';
	send_byte<='0';
	byte1 <="11111111110";
	byte2	<="11110011110";
	byte3	<="11110011110";
	wait for 20 ns;
	reset_sender<='0';
	wait for 20 ns;
	send_byte<='1';
	byte_out<=byte1;
	wait until finishToSend='1';
	reset_sender<='1';
	send_byte<='0';
	wait for 20 ns;
	reset_sender<='0';
	wait for 20 ns;
	send_byte<='1';
	byte_out<=byte2;
	wait until finishToSend='1';
	reset_sender<='1';
	send_byte<='0';
	wait for 20 ns;
	reset_sender<='0';
	wait for 20 ns;
	send_byte<='1';
	byte_out<=byte3;
	wait until finishToSend='1';
	wait until valid='1';
	assert (y_mov="000000000") and (x_mov="000000000") report "Test fail Valid-OK ; X&Y-overflow" severity error;
	wait until valid='0';
	wait for 100 ns;
	
--case 5 send correct byte set of bytes Valid-X ; paritty b1 problem
	wait until falling_edge(clk_10khz);
	reset_sender<='1';
	send_byte<='0';
	byte1 <="10001111110";
	byte2	<="11111111110";
	byte3	<="11111111110";
	wait for 20 ns;
	reset_sender<='0';
	wait for 20 ns;
	send_byte<='1';
	byte_out<=byte1;
	wait until finishToSend='1';
	reset_sender<='1';
	send_byte<='0';
	wait for 20 ns;
	reset_sender<='0';
	wait for 20 ns;
	send_byte<='1';
	byte_out<=byte2;
	wait until finishToSend='1';
	reset_sender<='1';
	send_byte<='0';
	wait for 20 ns;
	reset_sender<='0';
	wait for 20 ns;
	send_byte<='1';
	byte_out<=byte3;
	wait until finishToSend='1';
	wait for 10 us;
	
	
--case 6 send correct byte set of bytes Valid-X ; b1(3) problem
	wait until falling_edge(clk_10khz);
	reset_sender<='1';
	send_byte<='0';
	byte1 <="10001101110";
	byte2	<="11111111000";
	byte3	<="11111111000";
	wait for 20 ns;
	reset_sender<='0';
	wait for 20 ns;
	send_byte<='1';
	byte_out<=byte1;
	wait until finishToSend='1';
	reset_sender<='1';
	send_byte<='0';
	wait for 20 ns;
	reset_sender<='0';
	wait for 20 ns;
	send_byte<='1';
	byte_out<=byte2;
	wait until finishToSend='1';
	reset_sender<='1';
	send_byte<='0';
	wait for 20 ns;
	reset_sender<='0';
	wait for 20 ns;
	send_byte<='1';
	byte_out<=byte3;
	wait until finishToSend='1';
	wait for 10 us;

		
--case 7 send correct byte set of bytes Valid-X ; paritty b2 problem
	wait until falling_edge(clk_10khz);
	reset_sender<='1';
	send_byte<='0';
	byte1 <="11001111110";
	byte2	<="10111100110";
	byte3	<="11111100110";
	wait for 20 ns;
	reset_sender<='0';
	wait for 20 ns;
	send_byte<='1';
	byte_out<=byte1;
	wait until finishToSend='1';
	reset_sender<='1';
	send_byte<='0';
	wait for 20 ns;
	reset_sender<='0';
	wait for 20 ns;
	send_byte<='1';
	byte_out<=byte2;
	wait until finishToSend='1';
	reset_sender<='1';
	send_byte<='0';
	wait for 20 ns;
	reset_sender<='0';
	wait for 20 ns;
	send_byte<='1';
	byte_out<=byte3;
	wait until finishToSend='1';
	wait for 10 us;
	
--case 8 send correct byte set of bytes Valid-X ; Valid-X ; paritty b3 problem
	wait until falling_edge(clk_10khz);
	reset_sender<='1';
	send_byte<='0';
	byte1 <="11001111110";
	byte2	<="11110011110";
	byte3	<="10110011110";
	wait for 20 ns;
	reset_sender<='0';
	wait for 20 ns;
	send_byte<='1';
	byte_out<=byte1;
	wait until finishToSend='1';
	reset_sender<='1';
	send_byte<='0';
	wait for 20 ns;
	reset_sender<='0';
	wait for 20 ns;
	send_byte<='1';
	byte_out<=byte2;
	wait until finishToSend='1';
	reset_sender<='1';
	send_byte<='0';
	wait for 20 ns;
	reset_sender<='0';
	wait for 20 ns;
	send_byte<='1';
	byte_out<=byte3;
	wait until finishToSend='1';
	wait for 10 us;
	
--case 9 checking if the unit collect that if a byte will start with one
	wait until falling_edge(clk_10khz);
	reset_sender<='1';
	send_byte<='0';
	byte1 <="11001111110";
	byte2	<="11111111110";
	byte3	<="11111111110";
	wait for 20 ns;
	reset_sender<='0';
	wait for 20 ns;
	send_byte<='1';
	byte_out<=byte1;
	wait until finishToSend='1';
	reset_sender<='1';
	send_byte<='0';
	wait for 20 ns;
	reset_sender<='0';
	wait for 20 ns;
	send_byte<='1';
	byte_out<=byte2;
	wait until finishToSend='1';
	reset_sender<='1';
	send_byte<='0';
	wait for 20 ns;
	reset_sender<='0';
	wait for 20 ns;
	send_byte<='1';
--sending 1 byte and seeing if it effet the output
	byte_out<=(others=>'1');
	wait until finishToSend='1';
	reset_sender<='1';
	send_byte<='0';
	wait for 20 ns;
	reset_sender<='0';
	wait for 20 ns;
	send_byte<='1';
	byte_out<=byte3;
	wait until finishToSend='1';
	wait until valid='1';
	assert (y_mov=byte1(6) & byte3(8 downto 1)) and (x_mov=byte1(5) & byte2(8 downto 1)) report "Test fail to start collecting bytes" severity error;
	wait until valid='0';

	reset_sender<='1';
	send_byte<='0';
	byte1 <="11001111110";
	byte2	<="11111111110";
	byte3	<="11111111110";
	wait for 20 ns;
	reset_sender<='0';
	wait for 20 ns;
	send_byte<='1';
	byte_out<=byte1;
	wait until finishToSend='1';
	reset_sender<='1';
	send_byte<='0';
	wait for 20 ns;
	reset_sender<='0';
	wait for 20 ns;
	send_byte<='1';
	byte_out<=byte2;
	wait until finishToSend='1';
	reset_sender<='1';
	send_byte<='0';
	wait for 20 ns;
	reset_sender<='0';
	wait for 20 ns;
--case 10 stoping the clock and sending date to see if it effect the output
	send_byte<='1';
	byte_out<="11110001010";
	wait for 500 us;
	clk_10khz_en<='0';
	wait until finishToSend='1';
	reset_sender<='1';
	send_byte<='0';
	wait for 20 ns;
	reset_sender<='0';
	wait for 20 ns;
	send_byte<='1';
	byte_out<="11110001010";
	wait until finishToSend='1';
	reset_sender<='1';
	send_byte<='0';
	wait for 20 ns;
	reset_sender<='0';
	wait for 20 ns;
	send_byte<='1';
	byte_out<="11110001010";
	wait until finishToSend='1';
	reset_sender<='1';
	send_byte<='0';
	wait for 20 ns;
	reset_sender<='0';
	wait for 20 ns;
	send_byte<='1';
	byte_out<="11110001010";
	wait until finishToSend='1';
	reset_sender<='1';
	send_byte<='0';
	wait for 20 ns;
	reset_sender<='0';
	wait for 20 ns;
	send_byte<='1';
	byte_out<=byte2;
	wait until finishToSend='1';
	reset_sender<='1';
	send_byte<='0';
	wait for 20 ns;
	reset_sender<='0';
	wait for 20 ns;
	send_byte<='1';
	byte_out<="11110001010";
	wait until finishToSend='1';
	clk_10khz_en<='1';
	reset_sender<='1';
	send_byte<='0';
	wait for 20 ns;
	reset_sender<='0';
	wait for 20 ns;
	send_byte<='1';
	byte_out<=byte3;
	wait until finishToSend='1';
	wait until valid='1';
	assert (y_mov=byte1(6) & byte3(8 downto 1)) and (x_mov=byte1(5) & byte2(8 downto 1)) report "Test fail WDT" severity error;
	wait until valid='0';
	
	
end process test_run;

end architecture arc_Mouse_control_tb;