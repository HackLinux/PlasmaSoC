library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;
use ieee.numeric_std.all;

entity ddr_tester_fsm is
   port( 
      clk100_0        : in     std_logic;
      clk100_180      : in     std_logic;
      clk100_90       : in     std_logic;
      clk100_lock     : in     std_logic;
      dram_ar_done    : in     std_logic;
      dram_ar_req     : in     std_logic;
      dram_cmd_ack    : in     std_logic;
      dram_init_val   : in     std_logic;
      err             : in     std_logic;
      rst_int         : in     std_logic;
      strt_pb         : in     std_logic;
      dram_addr       : out    std_logic_vector (24 downto 0);
      dram_burst_done : out    std_logic;
      dram_cmd_reg    : out    std_logic_vector (2 downto 0);
      dram_data_mask  : out    std_logic_vector (3 downto 0);
      dram_data_w     : out    std_logic_vector (31 downto 0);
      leds            : out    std_logic_vector (7 downto 0);
      read_done       : out    std_logic);
end ddr_tester_fsm;
 
architecture Behavioral of ddr_tester_fsm is

   signal ar_done_internal	: std_logic;							-- Signals internally when the AR command is done
   signal bank_counter		: std_logic_vector(1 downto 0);	-- Bank counter
   signal big_dly_count		: std_logic_vector(7 downto 0);	-- Internal counter for big delay
   signal col_counter		: std_logic_vector(9 downto 0);	-- Column counter
   signal data_counter		: std_logic_vector(15 downto 0);	-- Data counter
   signal dly_count			: std_logic_vector(3 downto 0);	-- Internal counter for delay
   signal done_internal		: std_logic;							-- Internal done signal
   signal row_counter		: std_logic_vector(12 downto 0);	-- Row counter
   signal writting			: std_logic;							-- Is high when we are writting

   type rw_sm_state_type is (ShowNoErr, init, WPBRls, WDoneA, WDoneB, RDone, ShowErr, RstSt, WCmdAd, WAdAs1, WAdAs2,
										WAdinc, WAdAs3, WARBurst, WARBstAss, WARBDeAss, WRefCmd, WARDnHld1, WARDnHld2, WARDnHld3,
										WBrstDone, WBrstAs, WBrstDeAss, RCmdAd, RAdAs1, RAdAs2, RAdinc, RAdAs3, RARBurst, RARBstAss,
										RARBDeAss, RRefCmd, RARDnHld1, RARDnHld2, RARDnHld3, RBrstDone, RBrstAs, RBrstDeAss, WaitWTor);
   type ardone_sm_state_type is (ARIdle, ARDone, ARAss1, ARAss2);
   
	type dataw_sm_state_type is (DatWIdle, DatWAct, DatWRst);
 
   signal rw_sm_current_state : rw_sm_state_type;
   signal rw_sm_next_state : rw_sm_state_type;
   signal ardone_sm_current_state : ardone_sm_state_type;
   signal ardone_sm_next_state : ardone_sm_state_type;
   signal dataw_sm_current_state : dataw_sm_state_type;
   signal dataw_sm_next_state : dataw_sm_state_type;

begin

   rw_sm_clocked_proc : process (clk100_0, rst_int)
   begin
      if (rst_int = '1') then
         rw_sm_current_state <= RstSt;
         bank_counter <= (others => '0');
         big_dly_count <= (others => '0');
         col_counter <= (others => '0');
         dly_count <= (others => '0');
         done_internal <= '0';
         row_counter <= (others => '0');
      elsif (clk100_0'EVENT and clk100_0 = '0') then
         rw_sm_current_state <= rw_sm_next_state;

         case rw_sm_current_state is
            when ShowNoErr => 
               done_internal <= '0';
            when WPBRls => 
               dly_count <= (others => '0');
               row_counter <= (others => '0');
               col_counter <= (others => '0');
               bank_counter <= (others => '0');
            when WDoneA => 
               big_dly_count <= (others => '0');
               row_counter <= (others => '0');
               col_counter <= (others => '0');
               bank_counter <= (others => '0');
               done_internal <= '1';
            when WDoneB => 
               done_internal <= '0';
            when RDone => 
               done_internal <= '1';
               dly_count <= dly_count + '1' ;
            when ShowErr => 
               done_internal <= '0';
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
            when WaitWTor => 
               if (not(big_dly_count = "11111111")) then 
                  big_dly_count <= big_dly_count + '1';
               end if;
            when others =>
               NULL;
         end case;
      end if;
   end process rw_sm_clocked_proc;
 
   rw_sm_nextstate_proc : process (ar_done_internal, big_dly_count, clk100_lock, col_counter, dly_count, dram_ar_req,
												dram_cmd_ack, dram_init_val, err, row_counter, rw_sm_current_state, strt_pb)
   begin
      case rw_sm_current_state is
         when ShowNoErr => 
            if (clk100_lock = '1' and strt_pb = '1') then 
               rw_sm_next_state <= WPBRls;
            else
               rw_sm_next_state <= ShowNoErr;
            end if;
         when init => 
            if (dram_init_val = '1') then 
               rw_sm_next_state <= WCmdAd;
            else
               rw_sm_next_state <= init;
            end if;
         when WPBRls => 
            if (strt_pb = '0') then 
               rw_sm_next_state <= init;
            else
               rw_sm_next_state <= WPBRls;
            end if;
         when WDoneA => 
            rw_sm_next_state <= WDoneB;
         when WDoneB => 
            rw_sm_next_state <= RCmdAd;
         when RDone => 
            if (dly_count = "1111" and err = '1') then 
               rw_sm_next_state <= ShowErr;
            elsif (dly_count = "1111") then 
               rw_sm_next_state <= ShowNoErr;
            else
               rw_sm_next_state <= RDone;
            end if;
         when ShowErr => 
            if (clk100_lock = '1' and strt_pb = '1') then 
               rw_sm_next_state <= WPBRls;
            else
               rw_sm_next_state <= ShowErr;
            end if;
         when RstSt => 
            if (clk100_lock = '1' and strt_pb = '1') then 
               rw_sm_next_state <= WPBRls;
            else
               rw_sm_next_state <= RstSt;
            end if;
         when WCmdAd => 
            if (dram_cmd_ack = '1') then 
               rw_sm_next_state <= WAdAs1;
            else
               rw_sm_next_state <= WCmdAd;
            end if;
         when WAdAs1 => 
            rw_sm_next_state <= WAdAs2;
         when WAdAs2 => 
            if (col_counter = "1111111100") then 
               rw_sm_next_state <= WBrstDone;
            else
               rw_sm_next_state <= WAdinc;
            end if;
         when WAdinc => 
            rw_sm_next_state <= WAdAs3;
         when WAdAs3 => 
            if (dram_ar_req = '1') then 
               rw_sm_next_state <= WARBurst;
            elsif (col_counter = "1111111100") then 
               rw_sm_next_state <= WBrstDone;
            else
               rw_sm_next_state <= WAdinc;
            end if;
         when WARBurst => 
            rw_sm_next_state <= WARBstAss;
         when WARBstAss => 
            rw_sm_next_state <= WARBDeAss;
         when WARBDeAss => 
            if (dram_cmd_ack = '1') then 
               rw_sm_next_state <= WRefCmd;
            else
               rw_sm_next_state <= WARBDeAss;
            end if;
         when WRefCmd => 
            if (ar_done_internal = '1') then 
               rw_sm_next_state <= WARDnHld1;
            else
               rw_sm_next_state <= WRefCmd;
            end if;
         when WARDnHld1 => 
            rw_sm_next_state <= WARDnHld2;
         when WARDnHld2 => 
            rw_sm_next_state <= WARDnHld3;
         when WARDnHld3 => 
            if ((col_counter = "1111111100") and (row_counter = "0000000001000")) then 
               rw_sm_next_state <= WaitWTor;
            elsif (col_counter = "1111111100") then 
               rw_sm_next_state <= WCmdAd;
            else
               rw_sm_next_state <= WCmdAd;
            end if;
         when WBrstDone => 
            rw_sm_next_state <= WBrstAs;
         when WBrstAs => 
            rw_sm_next_state <= WBrstDeAss;
         when WBrstDeAss => 
            if ((dram_cmd_ack = '0') and (row_counter = "0000000001000")) then 
               rw_sm_next_state <= WaitWTor;
            elsif (dram_cmd_ack = '0') then 
               rw_sm_next_state <= WCmdAd;
            else
               rw_sm_next_state <= WBrstDeAss;
            end if;
         when RCmdAd => 
            if (dram_cmd_ack = '1') then 
               rw_sm_next_state <= RAdAs1;
            else
               rw_sm_next_state <= RCmdAd;
            end if;
         when RAdAs1 => 
            rw_sm_next_state <= RAdAs2;
         when RAdAs2 => 
            if (col_counter = "1111111100") then 
               rw_sm_next_state <= RBrstDone;
            else
               rw_sm_next_state <= RAdinc;
            end if;
         when RAdinc => 
            rw_sm_next_state <= RAdAs3;
         when RAdAs3 => 
            if (dram_ar_req = '1') then 
               rw_sm_next_state <= RARBurst;
            elsif (col_counter = "1111111100") then 
               rw_sm_next_state <= RBrstDone;
            else
               rw_sm_next_state <= RAdinc;
            end if;
         when RARBurst => 
            rw_sm_next_state <= RARBstAss;
         when RARBstAss => 
            rw_sm_next_state <= RARBDeAss;
         when RARBDeAss => 
            if (dram_cmd_ack = '1') then 
               rw_sm_next_state <= RRefCmd;
            else
               rw_sm_next_state <= RARBDeAss;
            end if;
         when RRefCmd => 
            if (ar_done_internal = '1') then 
               rw_sm_next_state <= RARDnHld1;
            else
               rw_sm_next_state <= RRefCmd;
            end if;
         when RARDnHld1 => 
            rw_sm_next_state <= RARDnHld2;
         when RARDnHld2 => 
            rw_sm_next_state <= RARDnHld3;
         when RARDnHld3 => 
            if ((col_counter = "1111111100") and (row_counter = "0000000001000")) then 
               rw_sm_next_state <= RDone;
            elsif (col_counter = "1111111100") then 
               rw_sm_next_state <= RCmdAd;
            else
               rw_sm_next_state <= RCmdAd;
            end if;
         when RBrstDone => 
            rw_sm_next_state <= RBrstAs;
         when RBrstAs => 
            rw_sm_next_state <= RBrstDeAss;
         when RBrstDeAss => 
            if ((dram_cmd_ack = '0') and (row_counter = "0000000001000")) then 
               rw_sm_next_state <= RDone;
            elsif (dram_cmd_ack = '0') then 
               rw_sm_next_state <= RCmdAd;
            else
               rw_sm_next_state <= RBrstDeAss;
            end if;
         when WaitWTor => 
            if (big_dly_count = "11111111") then 
               rw_sm_next_state <= WDoneA;
            else
               rw_sm_next_state <= WaitWTor;
            end if;
         when others =>
            rw_sm_next_state <= RstSt;
      end case;
   end process rw_sm_nextstate_proc;
 
   rw_sm_output_proc : process (col_counter, dram_ar_req, dram_cmd_ack, row_counter, rw_sm_current_state)
   begin
      case rw_sm_current_state is
         when ShowNoErr => 
            dram_burst_done <= '0';
            dram_cmd_reg <= (others => '0');
            leds <= "00000010";
            writting <= '0';
         when init => 
            dram_burst_done <= '0';
            dram_cmd_reg <= "010";
            leds <= "00000001";
            writting <= '0';
         when WPBRls => 
            dram_burst_done <= '0';
            dram_cmd_reg <= (others => '0');
            leds <= "10101010";
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
         when RDone => 
            dram_burst_done <= '0';
            dram_cmd_reg <= (others => '0');
            leds <= "00000001";
            writting <= '0';
         when ShowErr => 
            dram_burst_done <= '0';
            dram_cmd_reg <= (others => '0');
            leds <= "11111100";
            writting <= '0';
         when RstSt => 
            dram_burst_done <= '0';
            dram_cmd_reg <= (others => '0');
            leds <= (others => '0');
            writting <= '0';
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
            dram_cmd_reg <= "010";
            leds <= "00000001";
            writting <= '0';
         when WARDnHld1 => 
            dram_burst_done <= '0';
            dram_cmd_reg <= "010";
            leds <= "00000001";
            writting <= '0';
         when WARDnHld2 => 
            dram_burst_done <= '0';
            dram_cmd_reg <= "010";
            leds <= "00000001";
            writting <= '0';
         when WARDnHld3 => 
            dram_burst_done <= '0';
            dram_cmd_reg <= "010";
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
            dram_cmd_reg <= "010";
            leds <= "00000001";
            writting <= '0';
         when RARDnHld1 => 
            dram_burst_done <= '0';
            dram_cmd_reg <= "010";
            leds <= "00000001";
            writting <= '0';
         when RARDnHld2 => 
            dram_burst_done <= '0';
            dram_cmd_reg <= "010";
            leds <= "00000001";
            writting <= '0';
         when RARDnHld3 => 
            dram_burst_done <= '0';
            dram_cmd_reg <= "010";
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
         when others =>
            NULL;
      end case;
   end process rw_sm_output_proc;
 
   ardone_sm_clocked_proc : process (clk100_180, rst_int)
   begin
      if (rst_int = '1') then
         ardone_sm_current_state <= ARIdle;
      elsif (clk100_180'EVENT and clk100_180 = '1') then
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
            ar_done_internal <= '0' ;
         when ARDone => 
            ar_done_internal <= '1' ;
         when ARAss1 => 
            ar_done_internal <= '1' ;
         when ARAss2 => 
            ar_done_internal <= '1' ;
         when others =>
            NULL;
      end case;
   end process ardone_sm_output_proc;
 
   dataw_sm_clocked_proc : process (clk100_90, rst_int)
   begin
      if (rst_int = '1') then
         dataw_sm_current_state <= DatWIdle;
         data_counter <= (others => '0');
      elsif (clk100_90'EVENT and clk100_90 = '1') then
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
