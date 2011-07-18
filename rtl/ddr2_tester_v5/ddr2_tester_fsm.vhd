library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;
use ieee.numeric_std.all;

entity ddr2_tester_fsm is
   port( 
		clk0				: in	std_logic;
		rst0				: in	std_logic;
		phy_init_done		: in	std_logic;
		app_af_afull		: in	std_logic;
		app_wdf_afull		: in	std_logic;
		app_af_wren			: out	std_logic;
		app_af_addr			: out	std_logic_vector (24 downto 0);
		app_af_cmd			: out	std_logic_vector (2 downto 0);
		app_wdf_wren		: out	std_logic;
		app_wdf_data		: out	std_logic_vector(127 downto 0);
		app_wdf_mask_data	: out	std_logic_vector(15 downto 0);
		err					: in	std_logic;
		start				: in	std_logic;
		leds				: out	std_logic_vector (7 downto 0);
		read_done			: out	std_logic);
end ddr2_tester_fsm;
 
architecture Behavioral of ddr2_tester_fsm is

	signal bank_counter		: std_logic_vector(1 downto 0);		-- Bank counter
	signal big_dly_count	: std_logic_vector(7 downto 0);		-- Internal counter for big delay
	signal col_counter		: std_logic_vector(9 downto 0);		-- Column counter
	signal data_counter		: std_logic_vector(63 downto 0);	-- Data counter
	signal dly_count		: std_logic_vector(3 downto 0);		-- Internal counter for delay
	signal done_internal	: std_logic;						-- Internal done signal
	signal row_counter		: std_logic_vector(12 downto 0);	-- Row counter
	signal writting			: std_logic;						-- Is high when we are writting

	signal err_reg			: std_logic;

	type rw_sm_state_type is (	ShowNoErr, ShowErr, RstSt, InitSt,
								WStartRowSt, WNewColSt, WIncColSt, WEndRowSt, WaitWTor, WDoneA, WDoneB,
								RStartRowSt, RNewColSt, RIncColSt, REndRowSt, RDone);
	

	type dataw_sm_state_type is (DatWIdle, DatWAct, DatWRst);

	signal rw_sm_current_state : rw_sm_state_type;
	signal rw_sm_next_state : rw_sm_state_type;
	signal dataw_sm_current_state : dataw_sm_state_type;
	signal dataw_sm_next_state : dataw_sm_state_type;

begin

	err_reg_proc : process(clk0)
	begin
		if(clk0'event and clk0 = '1') then
			err_reg <= err;
		end if;
	end process;

	rw_sm_clocked_proc : process (clk0, rst0)
	begin
		if (rst0 = '1') then
			rw_sm_current_state <= RstSt;
			bank_counter <= (others => '0');
			big_dly_count <= (others => '0');
			col_counter <= (others => '0');
			dly_count <= (others => '0');
			done_internal <= '0';
			row_counter <= (others => '0');
		elsif (clk0'EVENT and clk0 = '0') then
			
			rw_sm_current_state <= rw_sm_next_state;

			case rw_sm_current_state is
			
				-- Init
					
				when InitSt => 
					dly_count <= (others => '0');
					row_counter <= (others => '0');
					col_counter <= (others => '0');
					bank_counter <= (others => '0');
					
				-- Writes
					
				when WNewColSt => 
					if (col_counter = "1111111100") then 
					else
						col_counter <= col_counter + "100";
					end if;
				
				when WEndRowSt => 
					col_counter <= (others => '0');
					if (row_counter = "0000000001000") then 
					else 
						row_counter <= row_counter + '1';
					end if;
					
				when WDoneA => 
					big_dly_count <= (others => '0');
					row_counter <= (others => '0');
					col_counter <= (others => '0');
					bank_counter <= (others => '0');
					done_internal <= '0';
					
				when WDoneB => 
					done_internal <= '0';
					
				when WaitWTor => 
					if (not(big_dly_count = "11111111")) then 
						big_dly_count <= big_dly_count + '1';
					end if;
					
				-- Reads
				
				when RNewColSt => 
					if (col_counter = "1111111100") then 
					else
						col_counter <= col_counter + "100";
					end if;
				
				when REndRowSt => 
					col_counter <= (others => '0');
					if (row_counter = "0000000001000") then 
					else
						row_counter <= row_counter + '1';
					end if;
					
				when RDone => 
					done_internal <= '1';
					dly_count <= dly_count + '1';
					
				-- Finish
					
				when ShowNoErr => 
					done_internal <= '0';
					
				when ShowErr => 
					done_internal <= '0';
				
				when others =>
					NULL;
					
			end case;
			
		end if;
		
	end process rw_sm_clocked_proc;
	
 
	rw_sm_nextstate_proc : process (big_dly_count, phy_init_done, col_counter, dly_count, err_reg, row_counter, rw_sm_current_state, start)
	begin

		case rw_sm_current_state is
		
			-- Init
		
			when RstSt => 
				if (phy_init_done = '1' and start = '1') then 
					rw_sm_next_state <= InitSt;
				else
					rw_sm_next_state <= RstSt;
				end if;
				
			when InitSt => 
				if (start = '0') then 
					rw_sm_next_state <= WStartRowSt;
				else	
					rw_sm_next_state <= InitSt;
				end if;
				
			-- Writes
			
			when WStartRowSt => 
				if (app_af_afull = '0' and app_wdf_afull = '0') then 
					rw_sm_next_state <= WNewColSt;
				else
					rw_sm_next_state <= WStartRowSt;
				end if;
			
			when WNewColSt => 
				if ((col_counter = "1111111100") and (row_counter = "0000000001000")) then 
					rw_sm_next_state <= WaitWTor;
				elsif (col_counter = "1111111100") then 
					rw_sm_next_state <= WEndRowSt;
				else
					rw_sm_next_state <= WIncColSt;
				end if;
				
			when WIncColSt => 
				rw_sm_next_state <= WNewColSt;
						
			when WEndRowSt => 
				if (row_counter = "0000000001000") then 
					rw_sm_next_state <= WaitWTor;
				else
					rw_sm_next_state <= WStartRowSt;
				end if;
				
			when WaitWTor => 
				if (big_dly_count = "11111111") then 
					rw_sm_next_state <= WDoneA;
				else
					rw_sm_next_state <= WaitWTor;
				end if;	
			
			when WDoneA => 
				rw_sm_next_state <= WDoneB;
			
			when WDoneB => 
				rw_sm_next_state <= RStartRowSt;
				
			-- Reads
			
			when RStartRowSt => 
				if (app_af_afull = '0') then 
					rw_sm_next_state <= RNewColSt;
				else
					rw_sm_next_state <= RStartRowSt;
				end if;
			
			when RNewColSt => 
				if ((col_counter = "1111111100") and (row_counter = "0000000001000")) then 
					rw_sm_next_state <= RDone;
				elsif (col_counter = "1111111100") then 
					rw_sm_next_state <= REndRowSt;
				else
					rw_sm_next_state <= RIncColSt;
				end if;
				
			when RIncColSt => 
				rw_sm_next_state <= RNewColSt;
						
			when REndRowSt => 
				if (row_counter = "0000000001000") then 
					rw_sm_next_state <= RDone;
				else
					rw_sm_next_state <= RStartRowSt;
				end if;
			
			when RDone => 
				if (dly_count = "1111" and err_reg = '1') then 
					rw_sm_next_state <= ShowErr;
				elsif (dly_count = "1111") then 
					rw_sm_next_state <= ShowNoErr;
				else
					rw_sm_next_state <= RDone;
				end if;
			
			-- Finished
				
			when ShowNoErr => 
				if (phy_init_done = '1' and start = '1') then 
					rw_sm_next_state <= WStartRowSt;
				else
					rw_sm_next_state <= ShowNoErr;
				end if;
				
			when ShowErr => 
				if (phy_init_done = '1' and start = '1') then 
					rw_sm_next_state <= WStartRowSt;
				else
					rw_sm_next_state <= ShowErr;
				end if;
			
			when others =>
				rw_sm_next_state <= RstSt;
				
		end case;
		
	end process rw_sm_nextstate_proc;
 
	rw_sm_output_proc : process (col_counter, row_counter, rw_sm_current_state)
	begin
		case rw_sm_current_state is
		
			-- Init
		
			when RstSt => 
				app_af_cmd <= (others => '0');
				leds <= (others => '0');
				writting <= '0';
				app_af_wren <= '0';
				app_wdf_wren <= '0';
				
			when InitSt => 
				app_af_cmd <= (others => '0');
				leds <= "00101010";
				writting <= '0';
				app_af_wren <= '0';
				app_wdf_wren <= '0';
				
			-- Writes			
	
			when WStartRowSt => 
				app_af_cmd <= "000";
				leds <= "00000001";
				writting <= '1';
				app_af_wren <= '1';
				app_wdf_wren <= '1';
			
			when WNewColSt => 
				app_af_cmd <= "000";
				leds <= "00000001";
				writting <= '1';
				app_af_wren <= '1';
				app_wdf_wren <= '1';
				if (col_counter = "1111111100") then 
					writting <= '0';
					app_af_wren <= '0';
				end if;
				
			when WIncColSt => 
				app_af_cmd <= "000";
				leds <= "00000001";
				writting <= '1';
				app_af_wren <= '1';
				app_wdf_wren <= '1';
		
			when WEndRowSt => 
				app_af_cmd <= "000";
				leds <= "00000001";
				writting <= '0';
				app_af_wren <= '1';
				app_wdf_wren <= '0';
				
			when WDoneA => 
				app_af_cmd <= (others => '0');
				leds <= "00000001";
				writting <= '0';
				app_af_wren <= '0';
				app_wdf_wren <= '0';
				
			when WDoneB => 
				app_af_cmd <= (others => '0');
				leds <= "00000001";
				writting <= '0';
				app_af_wren <= '0';
				app_wdf_wren <= '0';
				
			-- Reads
			
			when RStartRowSt => 
				app_af_cmd <= "001";
				leds <= "00000001";
				writting <= '0';
				app_af_wren <= '1';
				app_wdf_wren <= '0';
			
			when RNewColSt => 
				app_af_cmd <= "001";
				leds <= "00000001";
				writting <= '0';
				app_af_wren <= '1';
				app_wdf_wren <= '0';
				
			when RIncColSt => 
				app_af_cmd <= "001";
				leds <= "00000001";
				writting <= '0';
				app_af_wren <= '1';
				app_wdf_wren <= '0';
		
			when REndRowSt => 
				app_af_cmd <= "001";
				leds <= "00000001";
				writting <= '0';
				app_af_wren <= '1';
				app_wdf_wren <= '0';
			
			when RDone => 
				app_af_cmd <= (others => '0');
				leds <= "00000001";
				writting <= '0';
				app_af_wren <= '0';
				app_wdf_wren <= '0';
				
			-- Finish
				
			when ShowNoErr => 
				app_af_cmd <= (others => '0');
				leds <= "00000010";
				writting <= '0';
				app_af_wren <= '0';
				app_wdf_wren <= '0';
				
			when ShowErr => 
				app_af_cmd <= (others => '0');
				leds <= "00111100";
				writting <= '0';
				app_af_wren <= '0';
				app_wdf_wren <= '0';
			
			when others =>
				NULL;
			
		end case;
		
	end process rw_sm_output_proc;
 
	dataw_sm_clocked_proc : process (clk0, rst0)
	begin
	
		if (rst0 = '1') then
			dataw_sm_current_state <= DatWIdle;
			data_counter <= (others => '0');
		elsif (clk0'EVENT and clk0 = '1') then
			dataw_sm_current_state <= dataw_sm_next_state;

			case dataw_sm_current_state is
		
				when DatWAct => 
					data_counter <= data_counter + "10";
					
				when DatWRst => 
					data_counter <= (others => '0');
					
				when others =>
					NULL;
					
			end case;
		
		end if;
		
	end process dataw_sm_clocked_proc;

	dataw_sm_nextstate_proc : process (dataw_sm_current_state, done_internal, writting)
	begin
	
		case dataw_sm_current_state is
		
			when DatWIdle => 
				if (done_internal = '1') then 
					dataw_sm_next_state <= DatWRst;
				elsif (writting = '1') then 
					dataw_sm_next_state <= DatWAct;
				else
					dataw_sm_next_state <= DatWIdle;
				end if;
			
			when DatWAct => 
				if (writting = '0') then 
					dataw_sm_next_state <= DatWIdle;
				else
					dataw_sm_next_state <= DatWAct;
				end if;
			
			when DatWRst => 
				dataw_sm_next_state <= DatWIdle;
				
			when others =>
				dataw_sm_next_state <= DatWIdle;
				
		end case;
		
	end process dataw_sm_nextstate_proc;

	app_af_addr <= bank_counter & row_counter & col_counter;
	app_wdf_data <= data_counter & (data_counter + '1');
	read_done <= done_internal; 
	app_wdf_mask_data <= (others => '0');
	
end Behavioral;
