LIBRARY ieee;
USE ieee.std_logic_1164.all;
USE ieee.std_logic_arith.all;
USE ieee.std_logic_unsigned.all;
USE ieee.numeric_std.all;

ENTITY ddr_tester_fsm IS
   PORT( 
      clk100_0        : IN     std_logic;
      clk100_180      : IN     std_logic;
      clk100_90       : IN     std_logic;
      clk100_lock     : IN     std_logic;
      dram_ar_done    : IN     std_logic;
      dram_ar_req     : IN     std_logic;
      dram_cmd_ack    : IN     std_logic;
      dram_init_val   : IN     std_logic;
      err             : IN     std_logic;
      rst_int         : IN     std_logic;
      strt_pb         : IN     std_logic;
      dram_addr       : OUT    std_logic_vector (24 DOWNTO 0);
      dram_burst_done : OUT    std_logic;
      dram_cmd_reg    : OUT    std_logic_vector (2 DOWNTO 0);
      dram_data_mask  : OUT    std_logic_vector (3 DOWNTO 0);
      dram_data_w     : OUT    std_logic_vector (31 DOWNTO 0);
      leds            : OUT    std_logic_vector (7 DOWNTO 0);
      read_done       : OUT    std_logic);
END ddr_tester_fsm;
 
ARCHITECTURE fsm OF ddr_tester_fsm IS

   -- Architecture Declarations
   SIGNAL ar_done_internal : std_logic;  -- Signals internally when the AR command is done
   SIGNAL bank_counter : std_logic_vector( 1 DOWNTO 0 );  -- Bank counter
   SIGNAL big_dly_count : std_logic_vector( 7 DOWNTO 0 );  -- Internal counter for big delay
   SIGNAL col_counter : std_logic_vector( 9 DOWNTO 0 );  -- Column counter
   SIGNAL data_counter : std_logic_vector( 15 DOWNTO 0 );  -- Data counter
   SIGNAL dly_count : std_logic_vector( 3 DOWNTO 0 );  -- Internal counter for delay
   SIGNAL done_internal : std_logic;  -- Internal done signal
   SIGNAL row_counter : std_logic_vector( 12 DOWNTO 0 );  -- Row counter
   SIGNAL writting : std_logic;  -- Is high when we are writting

   TYPE RW_SM_STATE_TYPE IS (
      ShowNoErr,
      Init,
      WPBRls,
      WDoneA,
      WDoneB,
      RDone,
      ShowErr,
      RstSt,
      WCmdAd,
      WAdAs1,
      WAdAs2,
      WAdInc,
      WAdAs3,
      WARBurst,
      WARBstAss,
      WARBDeAss,
      WRefCmd,
      WARDnHld1,
      WARDnHld2,
      WARDnHld3,
      WBrstDone,
      WBrstAs,
      WBrstDeAss,
      RCmdAd,
      RAdAs1,
      RAdAs2,
      RAdInc,
      RAdAs3,
      RARBurst,
      RARBstAss,
      RARBDeAss,
      RRefCmd,
      RARDnHld1,
      RARDnHld2,
      RARDnHld3,
      RBrstDone,
      RBrstAs,
      RBrstDeAss,
      WaitWToR
   );
   TYPE ARDONE_SM_STATE_TYPE IS (
      ARIdle,
      ARDone,
      ARAss1,
      ARAss2
   );
   TYPE DATAW_SM_STATE_TYPE IS (
      DatWIdle,
      DatWAct,
      DatWRst
   );
 
   -- Declare current and next state signals
   SIGNAL rw_sm_current_state : RW_SM_STATE_TYPE;
   SIGNAL rw_sm_next_state : RW_SM_STATE_TYPE;
   SIGNAL ardone_sm_current_state : ARDONE_SM_STATE_TYPE;
   SIGNAL ardone_sm_next_state : ARDONE_SM_STATE_TYPE;
   SIGNAL dataw_sm_current_state : DATAW_SM_STATE_TYPE;
   SIGNAL dataw_sm_next_state : DATAW_SM_STATE_TYPE;

BEGIN

   -----------------------------------------------------------------
   rw_sm_clocked_proc : PROCESS ( 
      clk100_0,
      rst_int
   )
   -----------------------------------------------------------------
   BEGIN
      IF (rst_int = '1') THEN
         rw_sm_current_state <= RstSt;
         -- Default Reset Values
         bank_counter <= (others => '0');
         big_dly_count <= (others => '0');
         col_counter <= (others => '0');
         dly_count <= (others => '0');
         done_internal <= '0';
         row_counter <= (others => '0');
      ELSIF (clk100_0'EVENT AND clk100_0 = '0') THEN
         rw_sm_current_state <= rw_sm_next_state;

         -- Combined Actions
         CASE rw_sm_current_state IS
            WHEN ShowNoErr => 
               done_internal <= '0';
            WHEN WPBRls => 
               dly_count <= (others => '0');
               row_counter <= (others => '0');
               col_counter <= (others => '0');
               bank_counter <= (others => '0');
            WHEN WDoneA => 
               big_dly_count <= (others => '0');
               row_counter <= (others => '0');
               col_counter <= (others => '0');
               bank_counter <= (others => '0');
               done_internal <= '1';
            WHEN WDoneB => 
               done_internal <= '0';
            WHEN RDone => 
               done_internal <= '1';
               dly_count <= dly_count + '1' ;
            WHEN ShowErr => 
               done_internal <= '0';
            WHEN WAdAs2 => 
               IF (col_counter = "1111111100") THEN 
               ELSE
                  col_counter <= col_counter + "100";
               END IF;
            WHEN WAdAs3 => 
               IF (dram_ar_req = '1') THEN 
               ELSIF (col_counter = "1111111100") THEN 
               ELSE
                  col_counter <= col_counter + "100";
               END IF;
            WHEN WARDnHld3 => 
               IF ((col_counter = "1111111100") AND (row_counter = "0000000001000")) THEN 
               ELSIF (col_counter = "1111111100") THEN 
                  row_counter <= row_counter + '1';
               ELSE
                  col_counter <= col_counter + "100";
               END IF;
            WHEN WBrstDone => 
               col_counter <= (others => '0');
            WHEN WBrstDeAss => 
               IF ((dram_cmd_ack = '0') AND (row_counter = "0000000001000")) THEN 
               ELSIF (dram_cmd_ack = '0') THEN 
                  row_counter <= row_counter + '1';
               END IF;
            WHEN RAdAs2 => 
               IF (col_counter = "1111111100") THEN 
               ELSE
                  col_counter <= col_counter + "100";
               END IF;
            WHEN RAdAs3 => 
               IF (dram_ar_req = '1') THEN 
               ELSIF (col_counter = "1111111100") THEN 
               ELSE
                  col_counter <= col_counter + "100";
               END IF;
            WHEN RARDnHld3 => 
               IF ((col_counter = "1111111100") AND (row_counter = "0000000001000")) THEN 
               ELSIF (col_counter = "1111111100") THEN 
                  row_counter <= row_counter + '1';
               ELSE
                  col_counter <= col_counter + "100";
               END IF;
            WHEN RBrstDone => 
               col_counter <= (others => '0');
            WHEN RBrstDeAss => 
               IF ((dram_cmd_ack = '0') AND (row_counter = "0000000001000")) THEN 
               ELSIF (dram_cmd_ack = '0') THEN 
                  row_counter <= row_counter + '1';
               END IF;
            WHEN WaitWToR => 
               IF (NOT(big_dly_count = "11111111")) THEN 
                  big_dly_count <= big_dly_count + '1';
               END IF;
            WHEN OTHERS =>
               NULL;
         END CASE;
      END IF;
   END PROCESS rw_sm_clocked_proc;
 
   -----------------------------------------------------------------
   rw_sm_nextstate_proc : PROCESS ( 
      ar_done_internal,
      big_dly_count,
      clk100_lock,
      col_counter,
      dly_count,
      dram_ar_req,
      dram_cmd_ack,
      dram_init_val,
      err,
      row_counter,
      rw_sm_current_state,
      strt_pb
   )
   -----------------------------------------------------------------
   BEGIN
      CASE rw_sm_current_state IS
         WHEN ShowNoErr => 
            IF (clk100_lock = '1' AND strt_pb = '1') THEN 
               rw_sm_next_state <= WPBRls;
            ELSE
               rw_sm_next_state <= ShowNoErr;
            END IF;
         WHEN Init => 
            IF (dram_init_val = '1') THEN 
               rw_sm_next_state <= WCmdAd;
            ELSE
               rw_sm_next_state <= Init;
            END IF;
         WHEN WPBRls => 
            IF (strt_pb = '0') THEN 
               rw_sm_next_state <= Init;
            ELSE
               rw_sm_next_state <= WPBRls;
            END IF;
         WHEN WDoneA => 
            rw_sm_next_state <= WDoneB;
         WHEN WDoneB => 
            rw_sm_next_state <= RCmdAd;
         WHEN RDone => 
            IF (dly_count = "1111" AND err = '1') THEN 
               rw_sm_next_state <= ShowErr;
            ELSIF (dly_count = "1111") THEN 
               rw_sm_next_state <= ShowNoErr;
            ELSE
               rw_sm_next_state <= RDone;
            END IF;
         WHEN ShowErr => 
            IF (clk100_lock = '1' AND strt_pb = '1') THEN 
               rw_sm_next_state <= WPBRls;
            ELSE
               rw_sm_next_state <= ShowErr;
            END IF;
         WHEN RstSt => 
            IF (clk100_lock = '1' AND strt_pb = '1') THEN 
               rw_sm_next_state <= WPBRls;
            ELSE
               rw_sm_next_state <= RstSt;
            END IF;
         WHEN WCmdAd => 
            IF (dram_cmd_ack = '1') THEN 
               rw_sm_next_state <= WAdAs1;
            ELSE
               rw_sm_next_state <= WCmdAd;
            END IF;
         WHEN WAdAs1 => 
            rw_sm_next_state <= WAdAs2;
         WHEN WAdAs2 => 
            IF (col_counter = "1111111100") THEN 
               rw_sm_next_state <= WBrstDone;
            ELSE
               rw_sm_next_state <= WAdInc;
            END IF;
         WHEN WAdInc => 
            rw_sm_next_state <= WAdAs3;
         WHEN WAdAs3 => 
            IF (dram_ar_req = '1') THEN 
               rw_sm_next_state <= WARBurst;
            ELSIF (col_counter = "1111111100") THEN 
               rw_sm_next_state <= WBrstDone;
            ELSE
               rw_sm_next_state <= WAdInc;
            END IF;
         WHEN WARBurst => 
            rw_sm_next_state <= WARBstAss;
         WHEN WARBstAss => 
            rw_sm_next_state <= WARBDeAss;
         WHEN WARBDeAss => 
            IF (dram_cmd_ack = '1') THEN 
               rw_sm_next_state <= WRefCmd;
            ELSE
               rw_sm_next_state <= WARBDeAss;
            END IF;
         WHEN WRefCmd => 
            IF (ar_done_internal = '1') THEN 
               rw_sm_next_state <= WARDnHld1;
            ELSE
               rw_sm_next_state <= WRefCmd;
            END IF;
         WHEN WARDnHld1 => 
            rw_sm_next_state <= WARDnHld2;
         WHEN WARDnHld2 => 
            rw_sm_next_state <= WARDnHld3;
         WHEN WARDnHld3 => 
            IF ((col_counter = "1111111100") AND (row_counter = "0000000001000")) THEN 
               rw_sm_next_state <= WaitWToR;
            ELSIF (col_counter = "1111111100") THEN 
               rw_sm_next_state <= WCmdAd;
            ELSE
               rw_sm_next_state <= WCmdAd;
            END IF;
         WHEN WBrstDone => 
            rw_sm_next_state <= WBrstAs;
         WHEN WBrstAs => 
            rw_sm_next_state <= WBrstDeAss;
         WHEN WBrstDeAss => 
            IF ((dram_cmd_ack = '0') AND (row_counter = "0000000001000")) THEN 
               rw_sm_next_state <= WaitWToR;
            ELSIF (dram_cmd_ack = '0') THEN 
               rw_sm_next_state <= WCmdAd;
            ELSE
               rw_sm_next_state <= WBrstDeAss;
            END IF;
         WHEN RCmdAd => 
            IF (dram_cmd_ack = '1') THEN 
               rw_sm_next_state <= RAdAs1;
            ELSE
               rw_sm_next_state <= RCmdAd;
            END IF;
         WHEN RAdAs1 => 
            rw_sm_next_state <= RAdAs2;
         WHEN RAdAs2 => 
            IF (col_counter = "1111111100") THEN 
               rw_sm_next_state <= RBrstDone;
            ELSE
               rw_sm_next_state <= RAdInc;
            END IF;
         WHEN RAdInc => 
            rw_sm_next_state <= RAdAs3;
         WHEN RAdAs3 => 
            IF (dram_ar_req = '1') THEN 
               rw_sm_next_state <= RARBurst;
            ELSIF (col_counter = "1111111100") THEN 
               rw_sm_next_state <= RBrstDone;
            ELSE
               rw_sm_next_state <= RAdInc;
            END IF;
         WHEN RARBurst => 
            rw_sm_next_state <= RARBstAss;
         WHEN RARBstAss => 
            rw_sm_next_state <= RARBDeAss;
         WHEN RARBDeAss => 
            IF (dram_cmd_ack = '1') THEN 
               rw_sm_next_state <= RRefCmd;
            ELSE
               rw_sm_next_state <= RARBDeAss;
            END IF;
         WHEN RRefCmd => 
            IF (ar_done_internal = '1') THEN 
               rw_sm_next_state <= RARDnHld1;
            ELSE
               rw_sm_next_state <= RRefCmd;
            END IF;
         WHEN RARDnHld1 => 
            rw_sm_next_state <= RARDnHld2;
         WHEN RARDnHld2 => 
            rw_sm_next_state <= RARDnHld3;
         WHEN RARDnHld3 => 
            IF ((col_counter = "1111111100") AND (row_counter = "0000000001000")) THEN 
               rw_sm_next_state <= RDone;
            ELSIF (col_counter = "1111111100") THEN 
               rw_sm_next_state <= RCmdAd;
            ELSE
               rw_sm_next_state <= RCmdAd;
            END IF;
         WHEN RBrstDone => 
            rw_sm_next_state <= RBrstAs;
         WHEN RBrstAs => 
            rw_sm_next_state <= RBrstDeAss;
         WHEN RBrstDeAss => 
            IF ((dram_cmd_ack = '0') AND (row_counter = "0000000001000")) THEN 
               rw_sm_next_state <= RDone;
            ELSIF (dram_cmd_ack = '0') THEN 
               rw_sm_next_state <= RCmdAd;
            ELSE
               rw_sm_next_state <= RBrstDeAss;
            END IF;
         WHEN WaitWToR => 
            IF (big_dly_count = "11111111") THEN 
               rw_sm_next_state <= WDoneA;
            ELSE
               rw_sm_next_state <= WaitWToR;
            END IF;
         WHEN OTHERS =>
            rw_sm_next_state <= RstSt;
      END CASE;
   END PROCESS rw_sm_nextstate_proc;
 
   -----------------------------------------------------------------
   rw_sm_output_proc : PROCESS ( 
      col_counter,
      dram_ar_req,
      dram_cmd_ack,
      row_counter,
      rw_sm_current_state
   )
   -----------------------------------------------------------------
   BEGIN

      -- Combined Actions
      CASE rw_sm_current_state IS
         WHEN ShowNoErr => 
            dram_burst_done <= '0';
            dram_cmd_reg <= (others => '0');
            leds <= "00000010";
            writting <= '0';
         WHEN Init => 
            dram_burst_done <= '0';
            dram_cmd_reg <= "010";
            leds <= "00000001";
            writting <= '0';
         WHEN WPBRls => 
            dram_burst_done <= '0';
            dram_cmd_reg <= (others => '0');
            leds <= "10101010";
            writting <= '0';
         WHEN WDoneA => 
            dram_burst_done <= '0';
            dram_cmd_reg <= (others => '0');
            leds <= "00000001";
            writting <= '0';
         WHEN WDoneB => 
            dram_burst_done <= '0';
            dram_cmd_reg <= (others => '0');
            leds <= "00000001";
            writting <= '0';
         WHEN RDone => 
            dram_burst_done <= '0';
            dram_cmd_reg <= (others => '0');
            leds <= "00000001";
            writting <= '0';
         WHEN ShowErr => 
            dram_burst_done <= '0';
            dram_cmd_reg <= (others => '0');
            leds <= "11111100";
            writting <= '0';
         WHEN RstSt => 
            dram_burst_done <= '0';
            dram_cmd_reg <= (others => '0');
            leds <= (others => '0');
            writting <= '0';
         WHEN WCmdAd => 
            dram_burst_done <= '0';
            dram_cmd_reg <= "100";
            leds <= "00000001";
            writting <= '0';
            IF (dram_cmd_ack = '1') THEN 
               writting <= '1';
            END IF;
         WHEN WAdAs1 => 
            dram_burst_done <= '0';
            dram_cmd_reg <= "100";
            leds <= "00000001";
            writting <= '1';
         WHEN WAdAs2 => 
            dram_burst_done <= '0';
            dram_cmd_reg <= "100";
            leds <= "00000001";
            writting <= '1';
            IF (col_counter = "1111111100") THEN 
               writting <= '0';
            END IF;
         WHEN WAdInc => 
            dram_burst_done <= '0';
            dram_cmd_reg <= "100";
            leds <= "00000001";
            writting <= '1';
         WHEN WAdAs3 => 
            dram_burst_done <= '0';
            dram_cmd_reg <= "100";
            leds <= "00000001";
            writting <= '1';
            IF (dram_ar_req = '1') THEN 
               writting <= '0';
            ELSIF (col_counter = "1111111100") THEN 
               writting <= '0';
            END IF;
         WHEN WARBurst => 
            dram_burst_done <= '1';
            dram_cmd_reg <= "100";
            leds <= "00000001";
            writting <= '0';
         WHEN WARBstAss => 
            dram_burst_done <= '1';
            dram_cmd_reg <= "000";
            leds <= "00000001";
            writting <= '0';
         WHEN WARBDeAss => 
            dram_burst_done <= '0';
            dram_cmd_reg <= "000";
            leds <= "00000001";
            writting <= '0';
         WHEN WRefCmd => 
            dram_burst_done <= '0';
            dram_cmd_reg <= "010";
            leds <= "00000001";
            writting <= '0';
         WHEN WARDnHld1 => 
            dram_burst_done <= '0';
            dram_cmd_reg <= "010";
            leds <= "00000001";
            writting <= '0';
         WHEN WARDnHld2 => 
            dram_burst_done <= '0';
            dram_cmd_reg <= "010";
            leds <= "00000001";
            writting <= '0';
         WHEN WARDnHld3 => 
            dram_burst_done <= '0';
            dram_cmd_reg <= "010";
            leds <= "00000001";
            writting <= '0';
            IF ((col_counter = "1111111100") AND (row_counter = "0000000001000")) THEN 
               writting <= '0';
            ELSIF (col_counter = "1111111100") THEN 
               writting <= '0';
            ELSE
            END IF;
         WHEN WBrstDone => 
            dram_burst_done <= '1';
            dram_cmd_reg <= "100";
            leds <= "00000001";
            writting <= '0';
         WHEN WBrstAs => 
            dram_burst_done <= '1';
            dram_cmd_reg <= "000";
            leds <= "00000001";
            writting <= '0';
         WHEN WBrstDeAss => 
            dram_burst_done <= '0';
            dram_cmd_reg <= "000";
            leds <= "00000001";
            writting <= '0';
         WHEN RCmdAd => 
            dram_burst_done <= '0';
            dram_cmd_reg <= "110";
            leds <= "00000001";
            writting <= '0';
         WHEN RAdAs1 => 
            dram_burst_done <= '0';
            dram_cmd_reg <= "110";
            leds <= "00000001";
            writting <= '0';
         WHEN RAdAs2 => 
            dram_burst_done <= '0';
            dram_cmd_reg <= "110";
            leds <= "00000001";
            writting <= '0';
         WHEN RAdInc => 
            dram_burst_done <= '0';
            dram_cmd_reg <= "110";
            leds <= "00000001";
            writting <= '0';
         WHEN RAdAs3 => 
            dram_burst_done <= '0';
            dram_cmd_reg <= "110";
            leds <= "00000001";
            writting <= '0';
         WHEN RARBurst => 
            dram_burst_done <= '1';
            dram_cmd_reg <= "110";
            leds <= "00000001";
            writting <= '0';
         WHEN RARBstAss => 
            dram_burst_done <= '1';
            dram_cmd_reg <= "000";
            leds <= "00000001";
            writting <= '0';
         WHEN RARBDeAss => 
            dram_burst_done <= '0';
            dram_cmd_reg <= "000";
            leds <= "00000001";
            writting <= '0';
         WHEN RRefCmd => 
            dram_burst_done <= '0';
            dram_cmd_reg <= "010";
            leds <= "00000001";
            writting <= '0';
         WHEN RARDnHld1 => 
            dram_burst_done <= '0';
            dram_cmd_reg <= "010";
            leds <= "00000001";
            writting <= '0';
         WHEN RARDnHld2 => 
            dram_burst_done <= '0';
            dram_cmd_reg <= "010";
            leds <= "00000001";
            writting <= '0';
         WHEN RARDnHld3 => 
            dram_burst_done <= '0';
            dram_cmd_reg <= "010";
            leds <= "00000001";
            writting <= '0';
         WHEN RBrstDone => 
            dram_burst_done <= '1';
            dram_cmd_reg <= "110";
            leds <= "00000001";
            writting <= '0';
         WHEN RBrstAs => 
            dram_burst_done <= '1';
            dram_cmd_reg <= "000";
            leds <= "00000001";
            writting <= '0';
         WHEN RBrstDeAss => 
            dram_burst_done <= '0';
            dram_cmd_reg <= "000";
            leds <= "00000001";
            writting <= '0';
         WHEN OTHERS =>
            NULL;
      END CASE;
   END PROCESS rw_sm_output_proc;
 
   -----------------------------------------------------------------
   ardone_sm_clocked_proc : PROCESS ( 
      clk100_180,
      rst_int
   )
   -----------------------------------------------------------------
   BEGIN
      IF (rst_int = '1') THEN
         ardone_sm_current_state <= ARIdle;
      ELSIF (clk100_180'EVENT AND clk100_180 = '1') THEN
         ardone_sm_current_state <= ardone_sm_next_state;
      END IF;
   END PROCESS ardone_sm_clocked_proc;
 
   -----------------------------------------------------------------
   ardone_sm_nextstate_proc : PROCESS ( 
      ardone_sm_current_state,
      dram_ar_done
   )
   -----------------------------------------------------------------
   BEGIN
      CASE ardone_sm_current_state IS
         WHEN ARIdle => 
            IF (dram_ar_done = '1') THEN 
               ardone_sm_next_state <= ARDone;
            ELSE
               ardone_sm_next_state <= ARIdle;
            END IF;
         WHEN ARDone => 
            ardone_sm_next_state <= ARAss1;
         WHEN ARAss1 => 
            ardone_sm_next_state <= ARAss2;
         WHEN ARAss2 => 
            ardone_sm_next_state <= ARIdle;
         WHEN OTHERS =>
            ardone_sm_next_state <= ARIdle;
      END CASE;
   END PROCESS ardone_sm_nextstate_proc;
 
   -----------------------------------------------------------------
   ardone_sm_output_proc : PROCESS ( 
      ardone_sm_current_state
   )
   -----------------------------------------------------------------
   BEGIN

      -- Combined Actions
      CASE ardone_sm_current_state IS
         WHEN ARIdle => 
            ar_done_internal <= '0' ;
         WHEN ARDone => 
            ar_done_internal <= '1' ;
         WHEN ARAss1 => 
            ar_done_internal <= '1' ;
         WHEN ARAss2 => 
            ar_done_internal <= '1' ;
         WHEN OTHERS =>
            NULL;
      END CASE;
   END PROCESS ardone_sm_output_proc;
 
   -----------------------------------------------------------------
   dataw_sm_clocked_proc : PROCESS ( 
      clk100_90,
      rst_int
   )
   -----------------------------------------------------------------
   BEGIN
      IF (rst_int = '1') THEN
         dataw_sm_current_state <= DatWIdle;
         -- Default Reset Values
         data_counter <= (others => '0');
      ELSIF (clk100_90'EVENT AND clk100_90 = '1') THEN
         dataw_sm_current_state <= dataw_sm_next_state;

         -- Combined Actions
         CASE dataw_sm_current_state IS
            WHEN DatWAct => 
               data_counter <= data_counter + "10";
            WHEN DatWRst => 
               data_counter <= (others => '0');
            WHEN OTHERS =>
               NULL;
         END CASE;
      END IF;
   END PROCESS dataw_sm_clocked_proc;
 
   -----------------------------------------------------------------
   dataw_sm_nextstate_proc : PROCESS ( 
      dataw_sm_current_state,
      done_internal,
      writting
   )
   -----------------------------------------------------------------
   BEGIN
      CASE dataw_sm_current_state IS
         WHEN DatWIdle => 
            IF (done_internal = '1') THEN 
               dataw_sm_next_state <= DatWRst;
            ELSIF (writting = '1') THEN 
               dataw_sm_next_state <= DatWAct;
            ELSE
               dataw_sm_next_state <= DatWIdle;
            END IF;
         WHEN DatWAct => 
            IF (writting = '0') THEN 
               dataw_sm_next_state <= DatWIdle;
            ELSE
               dataw_sm_next_state <= DatWAct;
            END IF;
         WHEN DatWRst => 
            dataw_sm_next_state <= DatWIdle;
         WHEN OTHERS =>
            dataw_sm_next_state <= DatWIdle;
      END CASE;
   END PROCESS dataw_sm_nextstate_proc;
 
   -- Concurrent Statements
   dram_addr <= row_counter & col_counter & bank_counter ;
   dram_data_w <= data_counter & (data_counter + '1');
   read_done <= done_internal; 
   dram_data_mask <= (others => '0');
	
END fsm;
