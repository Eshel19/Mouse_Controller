library ieee;
use ieee.std_logic_1164.all;

entity Output_buffer is
  port (
        Output_buffer_ena, reset, clk_50MHz: in std_logic;
        byte1, byte2, byte3: in std_logic_vector(8 downto 0);
        x_mov, y_mov: out std_logic_vector(8 downto 0);
        valid: buffer std_logic;
		  FinishProcc: out std_logic
    );
end entity Output_buffer;

architecture arc_Output_buffer of Output_buffer is

    signal ena : std_logic := '0';
    signal Output_buffer_ena_prev, valid_prev : std_logic:= '0';
    signal xordataB1,xordataB2,xordataB3, parityout: std_logic;

begin
	
xordataB1 <= ((byte1(7) xnor byte1(6)) xnor (byte1(5) xnor byte1(4))) xnor( (byte1(3) xnor byte1(2)) xnor (byte1(1) xnor byte1(0)));
xordataB2 <= ((byte2(7) xnor byte2(6)) xnor (byte2(5) xnor byte2(4))) xnor( (byte2(3) xnor byte2(2)) xnor (byte2(1) xnor byte2(0)));
xordataB3 <= ((byte3(7) xnor byte3(6)) xnor (byte3(5) xnor byte3(4))) xnor( (byte3(3) xnor byte3(2)) xnor (byte3(1) xnor byte3(0)));

parityout <= ((xordataB1 xnor byte1(8)) and (xordataB2 xnor byte2(8))) and (xordataB3 xnor byte3(8));

FinishProcc <= (valid or reset) or ((not parityout) or (not byte1(3)));

    -- Process to control the ena signal
    Process_Ena_Control: process(clk_50MHz, reset, Output_buffer_ena, parityout)
    begin
        if reset = '1' or parityout = '0' or byte1(3) = '0' then
            ena <= '0';
            Output_buffer_ena_prev <= '0';  
        elsif rising_edge(clk_50MHz) then
            if Output_buffer_ena = '0'  then
                ena <= '0';
                Output_buffer_ena_prev <= '0';
            elsif Output_buffer_ena = '1' and ena = '0' then
                ena <= '1';
            elsif Output_buffer_ena = '1' and ena = '1' then
                ena <= '0';
                Output_buffer_ena_prev <= '1';
            end if;
        end if;
    end process Process_Ena_Control;

    -- Process to assign values to x_mov and y_mov
    Process_XY_Assignment: process(clk_50MHz, reset, parityout)
    begin
        if reset = '1'  or parityout = '0' or byte1(3) = '0' then
            x_mov <= (others => '0');
            y_mov <= (others => '0');
			elsif rising_edge(clk_50MHz) then
				if(byte1(6) = '1') then
					x_mov <= (others => '0');
				else
					x_mov <= byte1(4) & byte2(7 downto 0);
				end if;
				if(byte1(7) = '1') then
					y_mov <= (others => '0');
				else
					y_mov <= byte1(5) & byte3(7 downto 0);
				end if;
		end if;
    end process Process_XY_Assignment;

    -- Process to control the valid signal
    Process_Output_buffer_Control: process(clk_50MHz, reset, ena, valid_prev, parityout)
    begin
        if reset = '1' or parityout = '0' or byte1(3) = '0' then
            valid <= '0';
				valid_prev <= '0';
        elsif rising_edge(clk_50MHz) then
            if ena = '1' and Output_buffer_ena = '1' and Output_buffer_ena_prev = '0' then
                if valid_prev = '0' then
                    valid <= '1';
                    valid_prev <= '1';
                else
                    valid <= '0';
                    valid_prev <= '0';
                end if;
            else
                valid <= '0';
                valid_prev <= '0';
            end if;
        end if;
    end process Process_Output_buffer_Control;

end architecture arc_Output_buffer;