library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;
use ieee.numeric_std.all;

entity ddr_ctrl_fsm is
	port( 
		clk0			: in	std_logic;
		clk90			: in	std_logic;
		dcm_lock		: in	std_logic;
		rst0			: in	std_logic;
		rst90			: in	std_logic;
		rst180			: in	std_logic;
		dram_ar_done	: in	std_logic;
		dram_ar_req		: in	std_logic;
		dram_cmd_ack	: in	std_logic;
		dram_init_done	: in	std_logic;
		dram_data_valid	: in	std_logic;
		err				: in	std_logic;
		no_ddr_start	: in	std_logic;
		no_ddr_stop		: in	std_logic;
		active			: in	std_logic;
		byte_we			: in	std_logic_vector(3 downto 0);
		dram_addr		: out	std_logic_vector (24 downto 0);
		dram_burst_done	: out	std_logic;
		dram_cmd_reg	: out	std_logic_vector (2 downto 0);
		dram_data_mask	: out	std_logic_vector (3 downto 0);
		dram_data_r		: in	std_logic_vector (31 downto 0);
		dram_data_w		: out	std_logic_vector (31 downto 0);
		leds			: out	std_logic_vector (7 downto 0);
		pause			: out	std_logic);
end ddr_ctrl_fsm;
 
architecture Behavioral of ddr_ctrl_fsm is

	signal ar_done_internal	: std_logic;						-- Signals internally when the AR command is done
	signal bank_counter		: std_logic_vector(1 downto 0);		-- Bank counter
	signal big_dly_count	: std_logic_vector(7 downto 0);		-- Internal counter for big delay
	signal col_counter		: std_logic_vector(9 downto 0);		-- Column counter
	signal data_counter		: std_logic_vector(15 downto 0);	-- Data counter
	signal dly_count		: std_logic_vector(3 downto 0);		-- Internal counter for delay
	signal done_internal	: std_logic;						-- Internal done signal
	signal row_counter		: std_logic_vector(12 downto 0);	-- Row counter
	signal writting			: std_logic;						-- Is high when we are writting

	signal err_reg			: std_logic;

	type ddr_state_type is (ShowNoErr, init, init2, WPBRls, WDoneA, WDoneB, RDone, ShowErr, RstSt, WCmdAd, WAdAs1, WAdAs2,
								WAdinc, WAdAs3, WARBurst, WARBstAss, WARBDeAss, WRefCmd, WARDnHld1, WARDnHld2, WARDnHld3,
								WBrstDone, WBrstAs, WBrstDeAss, RCmdAd, RAdAs1, RAdAs2, RAdinc, RAdAs3, RARBurst, RARBstAss,
								RARBDeAss, RRefCmd, RARDnHld1, RARDnHld2, RARDnHld3, RBrstDone, RBrstAs, RBrstDeAss, WaitWTor);
	
	type ardone_sm_state_type is (ARIdle, ARDone, ARAss1, ARAss2);
	

	type dataw_sm_state_type is (DatWIdle, DatWAct, DatWRst);

	signal ddr_current_state : ddr_state_type;
	signal ddr_next_state : ddr_state_type;
	signal ardone_sm_current_state : ardone_sm_state_type;
	signal ardone_sm_next_state : ardone_sm_state_type;
	signal dataw_sm_current_state : dataw_sm_state_type;
	signal dataw_sm_next_state : dataw_sm_state_type;

begin

	err_reg_proc : process(clk0)
	begin
		if(clk0'event and clk0 = '1') then
			err_reg <= err;
		end if;
	end process;

	ddr_clocked_proc : process (clk0, rst0)
	begin
		if (rst0 = '1') then
			ddr_current_state <= RstSt;
			--bank_counter <= (others => '0');
			--big_dly_count <= (others => '0');
			--col_counter <= (others => '0');
			--dly_count <= (others => '0');
			--done_internal <= '0';
			--row_counter <= (others => '0');
		elsif (clk0'EVENT and clk0 = '0') then
			
			ddr_current_state <= ddr_next_state;

			case ddr_current_state is
			
				-- Init
					
				when WPBRls => 
					dly_count <= (others => '0');
					row_counter <= (others => '0');
					col_counter <= (others => '0');
					bank_counter <= (others => '0');
					
				-- Writes
					
				when WAdAs2 => 
					if (col_counter = "1111111100") then 
					else
						col_counter <= col_counter + "100";
					end if;
					
				when WAdAs3 => 
					if (dram_ar_req = '1') then 
					elsif (col_counter = "1111111100") then 
					else
						col_counter <= col_counter + "100";
					end if;
					
				when WARDnHld3 => 
					if ((col_counter = "1111111100") and (row_counter = "0000000001000")) then 
					elsif (col_counter = "1111111100") then 
						row_counter <= row_counter + '1';
					else
						col_counter <= col_counter + "100";
					end if;
					
				when WBrstDone => 
					col_counter <= (others => '0');
				
				when WBrstDeAss => 
					if ((dram_cmd_ack = '0') and (row_counter = "0000000001000")) then 
					elsif (dram_cmd_ack = '0') then 
						row_counter <= row_counter + '1';
					end if;
					
				when WDoneA => 
					big_dly_count <= (others => '0');
					row_counter <= (others => '0');
					col_counter <= (others => '0');
					bank_counter <= (others => '0');
					done_internal <= '1';
					
				when WDoneB => 
					done_internal <= '0';
					
				when WaitWTor => 
					if (not(big_dly_count = "11111111")) then 
						big_dly_count <= big_dly_count + '1';
					end if;
					
				-- Reads
				
				when RAdAs2 => 
					if (col_counter = "1111111100") then 
					else
						col_counter <= col_counter + "100";
					end if;
				
				when RAdAs3 => 
					if (dram_ar_req = '1') then 
					elsif (col_counter = "1111111100") then 
					else
						col_counter <= col_counter + "100";
					end if;
					
				when RARDnHld3 => 
					if ((col_counter = "1111111100") and (row_counter = "0000000001000")) then 
					elsif (col_counter = "1111111100") then 
						row_counter <= row_counter + '1';
					else
						col_counter <= col_counter + "100";
					end if;
					
				when RBrstDone => 
					col_counter <= (others => '0');
				
				when RBrstDeAss => 
					if ((dram_cmd_ack = '0') and (row_counter = "0000000001000")) then 
					elsif (dram_cmd_ack = '0') then 
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
		
	end process ddr_clocked_proc;
	
 
	ddr_nextstate_proc : process (ar_done_internal, big_dly_count, dcm_lock, col_counter, dly_count, dram_ar_req,
							dram_cmd_ack, dram_init_done, err_reg, row_counter, ddr_current_state, start)
	begin

		case ddr_current_state is
		
			-- Init
		
			when ResetSt => 
				if (rst0 = '0' and active = '1') then 
					ddr_next_state <= ActiveSt;
				else
					ddr_next_state <= ResetSt;
				end if;
				
			when ActiveSt => 
				if (active = '1') then 
					ddr_next_state <= InitStartSt;
				else	
					ddr_next_state <= ActiveSt;
				end if;
						
			when InitStartSt => 
				ddr_next_state <= InitFinishSt;
			
			when InitFinishSt => 
				if (dram_init_done = '1') then 
					ddr_next_state <= CmdAddSt;
				else
					ddr_next_state <= InitFinishSt;
				end if;
				
			when CmdAddSt =>
				if(active = '1') then
					if (byte_we = "0000" then
						ddr_next_state <= ReadStartSt;
					else
						ddr_next_state <= WriteStartSt
					end if;
				else
					ddr_next_state <= CmdAddSt;
				end if;		
					
			
			when WriteStartSt => 
				if (dram_cmd_ack = '1') then 
					ddr_next_state <= WriteDo1St;
				else
					ddr_next_state <= WriteStartSt;
				end if;
				
			when WriteDo1St => 
				rw_sm_next_state <= WriteDo2St;

			
			when WriteDo2St => 
				if (col_counter = "1111111100") then 
					ddr_next_state <= WriteBurstDoneSt;
				else
					ddr_next_state <= WriteIncSt;
				end if;
			
			when WAdinc => 
				ddr_next_state <= WAdAs3;
			
			when WAdAs3 => 
				if (dram_ar_req = '1') then 
					ddr_next_state <= WARBurst;
				elsif (col_counter = "1111111100") then 
					ddr_next_state <= WBrstDone;
				else
					ddr_next_state <= WAdinc;
				end if;
			
			when WriteARBurstSt => 
				ddr_next_state <= WriteARBurstAssSt;
			
			when WriteARBurstAssSt => 
				ddr_next_state <= WriteARBurstDeAssSt;
			
			when WriteARBurstDeAssSt => 
				if (dram_cmd_ack = '1') then 
					ddr_next_state <= WRefCmd;
				else
					ddr_next_state <= WARBDeAss;
				end if;
			
			when WRefCmd => 
				if (ar_done_internal = '1') then 
					ddr_next_state <= WARDnHld1;
				else
					ddr_next_state <= WRefCmd;
				end if;
			
			when WARDnHld1 => 
				ddr_next_state <= WARDnHld2;
			
			when WARDnHld2 => 
				ddr_next_state <= WARDnHld3;
			
			when WARDnHld3 => 
				if ((col_counter = "1111111100") and (row_counter = "0000000001000")) then 
					ddr_next_state <= WaitWTor;
				elsif (col_counter = "1111111100") then 
					ddr_next_state <= WCmdAd;
				else
					ddr_next_state <= WCmdAd;
				end if;
			
			when WBrstDone => 
				ddr_next_state <= WBrstAs;
			
			when WBrstAs => 
				ddr_next_state <= WBrstDeAss;
			
			when WBrstDeAss => 
				if ((dram_cmd_ack = '0') and (row_counter = "0000000001000")) then 
					ddr_next_state <= WaitWTor;
				elsif (dram_cmd_ack = '0') then 
					ddr_next_state <= WCmdAd;
				else
					ddr_next_state <= WBrstDeAss;
				end if;
				
			when WaitWTor => 
				if (big_dly_count = "11111111") then 
					ddr_next_state <= WDoneA;
				else
					ddr_next_state <= WaitWTor;
				end if;	
			
			when WDoneA => 
				ddr_next_state <= WDoneB;
			
			when WDoneB => 
				ddr_next_state <= RCmdAd;
				
			-- Reads
			
			when RCmdAd => 
				if (dram_cmd_ack = '1') then 
					ddr_next_state <= RAdAs1;
				else
					ddr_next_state <= RCmdAd;
				end if;
			
			when RAdAs1 => 
				ddr_next_state <= RAdAs2;
			
			when RAdAs2 => 
				if (col_counter = "1111111100") then 
					ddr_next_state <= RBrstDone;
				else
					ddr_next_state <= RAdinc;
				end if;
			
			when RAdinc => 
				ddr_next_state <= RAdAs3;
			
			when RAdAs3 => 
				if (dram_ar_req = '1') then 
					ddr_next_state <= RARBurst;
				elsif (col_counter = "1111111100") then 
					ddr_next_state <= RBrstDone;
				else
					ddr_next_state <= RAdinc;
				end if;
			
			when RARBurst => 
				ddr_next_state <= RARBstAss;
			
			when RARBstAss => 
				ddr_next_state <= RARBDeAss;
			
			when RARBDeAss => 
				if (dram_cmd_ack = '1') then 
					ddr_next_state <= RRefCmd;
				else
					ddr_next_state <= RARBDeAss;
				end if;
			
			when RRefCmd => 
				if (ar_done_internal = '1') then 
					ddr_next_state <= RARDnHld1;
				else
					ddr_next_state <= RRefCmd;
				end if;
			
			when RARDnHld1 => 
				ddr_next_state <= RARDnHld2;
			
			when RARDnHld2 => 
				ddr_next_state <= RARDnHld3;
			
			when RARDnHld3 => 
				if ((col_counter = "1111111100") and (row_counter = "0000000001000")) then 
					ddr_next_state <= RDone;
				elsif (col_counter = "1111111100") then 
					ddr_next_state <= RCmdAd;
				else
					ddr_next_state <= RCmdAd;
				end if;
			
			when RBrstDone => 
				ddr_next_state <= RBrstAs;
			
			when RBrstAs => 
				ddr_next_state <= RBrstDeAss;
			
			when RBrstDeAss => 
				if ((dram_cmd_ack = '0') and (row_counter = "0000000001000")) then 
					ddr_next_state <= RDone;
				elsif (dram_cmd_ack = '0') then 
					ddr_next_state <= RCmdAd;
				else
					ddr_next_state <= RBrstDeAss;
				end if;
			
			when RDone => 
				if (dly_count = "1111" and err_reg = '1') then 
					ddr_next_state <= ShowErr;
				elsif (dly_count = "1111") then 
					ddr_next_state <= ShowNoErr;
				else
					ddr_next_state <= RDone;
				end if;
			
			-- Finished
				
			when ShowNoErr => 
				if (dcm_lock = '1' and start = '1') then 
					ddr_next_state <= WPBRls;
				else
					ddr_next_state <= ShowNoErr;
				end if;
				
			when ShowErr => 
				if (dcm_lock = '1' and start = '1') then 
					ddr_next_state <= WPBRls;
				else
					ddr_next_state <= ShowErr;
				end if;
			
			when others =>
				ddr_next_state <= RstSt;
				
		end case;
		
	end process ddr_nextstate_proc;
 
	ddr_output_proc : process (col_counter, dram_ar_req, dram_cmd_ack, row_counter, ddr_current_state)
	begin
		case ddr_current_state is
		
			-- Init
		
			when RstSt => 
				dram_burst_done <= '0';
				dram_cmd_reg <= (others => '0');
				leds <= (others => '0');
				writting <= '0';
				
			when WPBRls => 
				dram_burst_done <= '0';
				dram_cmd_reg <= (others => '0');
				leds <= "00101010";
				writting <= '0';
				
			when init => 
				dram_burst_done <= '0';
				dram_cmd_reg <= "010";
				leds <= "00000001";
				writting <= '0';
				
			when init2 => 
				dram_burst_done <= '0';
				dram_cmd_reg <= "000";
				leds <= "00000001";
				writting <= '0';
				
			-- Writes			
	
			when WCmdAd => 
				dram_burst_done <= '0';
				dram_cmd_reg <= "100";
				leds <= "00000001";
				writting <= '0';
				if (dram_cmd_ack = '1') then 
					writting <= '1';
				end if;
				
			when WAdAs1 => 
				dram_burst_done <= '0';
				dram_cmd_reg <= "100";
				leds <= "00000001";
				writting <= '1';
			
			when WAdAs2 => 
				dram_burst_done <= '0';
				dram_cmd_reg <= "100";
				leds <= "00000001";
				writting <= '1';
				if (col_counter = "1111111100") then 
					writting <= '0';
				end if;
			
			when WAdinc => 
				dram_burst_done <= '0';
				dram_cmd_reg <= "100";
				leds <= "00000001";
				writting <= '1';
			
			when WAdAs3 => 
				dram_burst_done <= '0';
				dram_cmd_reg <= "100";
				leds <= "00000001";
				writting <= '1';
				if (dram_ar_req = '1') then 
					writting <= '0';
				elsif (col_counter = "1111111100") then 
					writting <= '0';
				end if;
			
			when WARBurst => 
				dram_burst_done <= '1';
				dram_cmd_reg <= "100";
				leds <= "00000001";
				writting <= '0';
			
			when WARBstAss => 
				dram_burst_done <= '1';
				dram_cmd_reg <= "000";
				leds <= "00000001";
				writting <= '0';
			
			when WARBDeAss => 
				dram_burst_done <= '0';
				dram_cmd_reg <= "000";
				leds <= "00000001";
				writting <= '0';
			
			when WRefCmd => 
				dram_burst_done <= '0';
				dram_cmd_reg <= "000";
				leds <= "00000001";
				writting <= '0';
			
			when WARDnHld1 => 
				dram_burst_done <= '0';
				dram_cmd_reg <= "000";
				leds <= "00000001";
				writting <= '0';
			
			when WARDnHld2 => 
				dram_burst_done <= '0';
				dram_cmd_reg <= "000";
				leds <= "00000001";
				writting <= '0';
			
			when WARDnHld3 => 
				dram_burst_done <= '0';
				dram_cmd_reg <= "000";
				leds <= "00000001";
				writting <= '0';
				if ((col_counter = "1111111100") and (row_counter = "0000000001000")) then 
					writting <= '0';
				elsif (col_counter = "1111111100") then 
					writting <= '0';
				else
				end if;
			
			when WBrstDone => 
				dram_burst_done <= '1';
				dram_cmd_reg <= "100";
				leds <= "00000001";
				writting <= '0';
			
			when WBrstAs => 
				dram_burst_done <= '1';
				dram_cmd_reg <= "000";
				leds <= "00000001";
				writting <= '0';
			
			when WBrstDeAss => 
				dram_burst_done <= '0';
				dram_cmd_reg <= "000";
				leds <= "00000001";
				writting <= '0';
				
			when WDoneA => 
				dram_burst_done <= '0';
				dram_cmd_reg <= (others => '0');
				leds <= "00000001";
				writting <= '0';
				
			when WDoneB => 
				dram_burst_done <= '0';
				dram_cmd_reg <= (others => '0');
				leds <= "00000001";
				writting <= '0';
				
			-- Reads
			
			when RCmdAd => 
				dram_burst_done <= '0';
				dram_cmd_reg <= "110";
				leds <= "00000001";
				writting <= '0';
			
			when RAdAs1 => 
				dram_burst_done <= '0';
				dram_cmd_reg <= "110";
				leds <= "00000001";
				writting <= '0';
			
			when RAdAs2 => 
				dram_burst_done <= '0';
				dram_cmd_reg <= "110";
				leds <= "00000001";
				writting <= '0';
			
			when RAdinc => 
				dram_burst_done <= '0';
				dram_cmd_reg <= "110";
				leds <= "00000001";
				writting <= '0';
			
			when RAdAs3 => 
				dram_burst_done <= '0';
				dram_cmd_reg <= "110";
				leds <= "00000001";
				writting <= '0';
			
			when RARBurst => 
				dram_burst_done <= '1';
				dram_cmd_reg <= "110";
				leds <= "00000001";
				writting <= '0';
			
			when RARBstAss => 
				dram_burst_done <= '1';
				dram_cmd_reg <= "000";
				leds <= "00000001";
				writting <= '0';
			
			when RARBDeAss => 
				dram_burst_done <= '0';
				dram_cmd_reg <= "000";
				leds <= "00000001";
				writting <= '0';
			
			when RRefCmd => 
				dram_burst_done <= '0';
				dram_cmd_reg <= "000";
				leds <= "00000001";
				writting <= '0';
			
			when RARDnHld1 => 
				dram_burst_done <= '0';
				dram_cmd_reg <= "000";
				leds <= "00000001";
				writting <= '0';
			
			when RARDnHld2 => 
				dram_burst_done <= '0';
				dram_cmd_reg <= "000";
				leds <= "00000001";
				writting <= '0';
			
			when RARDnHld3 => 
				dram_burst_done <= '0';
				dram_cmd_reg <= "000";
				leds <= "00000001";
				writting <= '0';
			
			when RBrstDone => 
				dram_burst_done <= '1';
				dram_cmd_reg <= "110";
				leds <= "00000001";
				writting <= '0';
			
			when RBrstAs => 
				dram_burst_done <= '1';
				dram_cmd_reg <= "000";
				leds <= "00000001";
				writting <= '0';
			
			when RBrstDeAss => 
				dram_burst_done <= '0';
				dram_cmd_reg <= "000";
				leds <= "00000001";
				writting <= '0';
			
			when RDone => 
				dram_burst_done <= '0';
				dram_cmd_reg <= (others => '0');
				leds <= "00000001";
				writting <= '0';
				
			-- Finish
				
			when ShowNoErr => 
				dram_burst_done <= '0';
				dram_cmd_reg <= (others => '0');
				leds <= "00000010";
				writting <= '0';
				
			when ShowErr => 
				dram_burst_done <= '0';
				dram_cmd_reg <= (others => '0');
				leds <= "00111100";
				writting <= '0';
			
			when others =>
				NULL;
			
		end case;
		
	end process ddr_output_proc;
 
	ardone_sm_clocked_proc : process (clk0, rst0)
	begin
	
		if (rst0 = '1') then
			ardone_sm_current_state <= ARIdle;
		elsif (clk0'EVENT and clk0 = '1') then
			ardone_sm_current_state <= ardone_sm_next_state;
		end if;
		
	end process ardone_sm_clocked_proc;
	
 
	ardone_sm_nextstate_proc : process (ardone_sm_current_state, dram_ar_done)
	begin
		case ardone_sm_current_state is
		
			when ARIdle => 
				if (dram_ar_done = '1') then 
					ardone_sm_next_state <= ARDone;
				else
					ardone_sm_next_state <= ARIdle;
				end if;
			
			when ARDone =>
				ardone_sm_next_state <= ARAss1;
				
			when ARAss1 =>
				ardone_sm_next_state <= ARAss2;
				
			when ARAss2 =>
				ardone_sm_next_state <= ARIdle;
				
			when others =>
				ardone_sm_next_state <= ARIdle;
			
		end case;
		
	end process ardone_sm_nextstate_proc;

	ardone_sm_output_proc : process (ardone_sm_current_state)
	begin
	
		case ardone_sm_current_state is
		
			when ARIdle => 
				ar_done_internal <= '0';
				
			when ARDone => 
				ar_done_internal <= '1';
				
			when ARAss1 => 
				ar_done_internal <= '1';
				
			when ARAss2 => 
				ar_done_internal <= '1';
				
			when others =>
				NULL;
			
		end case;
		
	end process ardone_sm_output_proc;
 
	dataw_sm_clocked_proc : process (clk90, rst90)
	begin
	
		if (rst90 = '1') then
			dataw_sm_current_state <= DatWIdle;
			data_counter <= (others => '0');
		elsif (clk90'EVENT and clk90 = '1') then
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

	dram_addr <= row_counter & col_counter & bank_counter ;
	dram_data_w <= data_counter & (data_counter + '1');
	read_done <= done_internal; 
	dram_data_mask <= (others => '0');
	
end Behavioral;
