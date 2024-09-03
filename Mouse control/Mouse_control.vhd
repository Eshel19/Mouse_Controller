library ieee;
use ieee.std_logic_1164.all;

entity Mouse_control is
  port (
    clk_50MHz : in std_logic;
    reset : in std_logic;
    data : inout std_logic;
    clock : inout std_logic;
    x_mov : out std_logic_vector(8 downto 0);
    y_mov : out std_logic_vector(8 downto 0);
    valid : out std_logic
  );
end entity Mouse_control;

architecture arc_Mouse_control of Mouse_control is
  signal clock_in,Int_ena_temp,Int_ena, clock_out,clock_in_sync,en_sync,wdt_bark, Int_done, Set_bytes, Output_buffer_ena, DataSended, data_in, data_out : std_logic;
  signal byte1, byte2, byte3 : std_logic_vector(8 downto 0);
  signal ena_byte, done_Byte : std_logic_vector(2 downto 0);

component ctrl is
    port (
      Int_ena, Output_buffer_ena, Set_bytes,clock : out std_logic;
      Int_done, DataSended, reset : in std_logic;
      clk_50MHz : in std_logic;
      ena_byte : out std_logic_vector(2 downto 0);
      done_byte : in std_logic_vector(2 downto 0)
    );
end component ctrl;


component WDT is
  port (
		clk : in std_logic;
		reset : in std_logic;
		wdt_en : in std_logic;
		clk_rst : in std_logic;
		WDT_done : out std_logic
		);
end component WDT;

component clock_synchronizer_FDC is
  port (
    reset,en,clk_50MHz,clock_in : in std_logic;
    clock_out : out std_logic
  );
end component clock_synchronizer_FDC;  
  
component Output_buffer is
    port (
	 Output_buffer_ena, reset, clk_50MHz: in std_logic;
    byte1, byte2, byte3: in std_logic_vector(8 downto 0);
    x_mov, y_mov: out std_logic_vector(8 downto 0);
    valid: buffer std_logic;
	 FinishProcc: out std_logic
    );
end component Output_buffer;

component SIPO_Reg is
  port (
	done : out std_logic;
	clock,ena,data_in,Set_bytes,reset,wdt_bark : in std_logic;
	data_out: out std_logic_vector(8 downto 0)
  );
end component SIPO_Reg;

component Int is
  port (
    reset, Int_ena, clock : in std_logic;
    data, Int_done : out std_logic
    );
end component Int;
begin
data <= data_out when (Int_ena='1') else 'Z';
data_in <= data when (Int_ena='0') else 'Z';
clock <= clock_out when (Int_ena='1') else 'Z';
clock_in <= clock when (Int_ena='0') else 'Z';

en_sync <=(ena_byte(0) or ena_byte(1) or ena_byte(2));

synchronizer :clock_synchronizer_FDC port map(
	 reset=>reset,
	 en =>en_sync,
	 clk_50MHz =>clk_50MHz,
	 clock_in => clock_in,
    clock_out => clock_in_sync);

CRTL_unit: ctrl port map(
	clk_50MHz => clk_50MHz,
	ena_byte => ena_byte,
	done_Byte => done_Byte,
	Output_buffer_ena => Output_buffer_ena,
	DataSended =>DataSended,
	Int_done =>Int_done,
	Int_ena =>Int_ena,
	clock =>clock_out,
	reset=>reset,
	Set_bytes=>Set_bytes );

Output_buffer_unit : Output_buffer port map(
	FinishProcc =>DataSended,
	valid =>valid,
   Output_buffer_ena => Output_buffer_ena,
	reset =>reset,
   clk_50MHz =>clk_50MHz,
   byte1 =>byte1,
	byte2 =>byte2,
	byte3 =>byte3,
   y_mov => y_mov,
	x_mov => x_mov );
	
Int_unit : Int port map(
	reset =>reset, 
	Int_ena =>Int_ena,
   data => data_out, 
	Int_done =>Int_done, 
	clock => clock_out );

SIPO_Reg1: SIPO_Reg port map(
	done=>done_byte(0),
	clock=>clock_in_sync,
	ena=>ena_byte(0),
	data_in=>data_in,
	Set_bytes=>Set_bytes,
	reset=>reset,
	wdt_bark=>wdt_bark,
   data_out=>byte1);
	
SIPO_Reg2: SIPO_Reg port map(
	done=>done_byte(1),
	clock=>clock_in_sync,
	ena=>ena_byte(1),
	data_in=>data_in,
	Set_bytes=>Set_bytes,
	reset=>reset,
	wdt_bark=>wdt_bark,
   data_out=>byte2);	
	
SIPO_Reg3: SIPO_Reg port map(
	done=>done_byte(2),
	clock=>clock_in_sync,
	ena=>ena_byte(2),
	data_in=>data_in,
	Set_bytes=>Set_bytes,
	reset=>reset,
	wdt_bark=>wdt_bark,
   data_out=>byte3);
	
	
WDT_unit : WDT port map(
	clk => clk_50mhz,
	reset =>reset,
	wdt_en => en_sync,
	clk_rst => clock_in_sync,
	WDT_done => wdt_bark
	);


end architecture arc_Mouse_control;
