LIBRARY ieee;
USE ieee.std_logic_1164.all;
USE ieee.std_logic_arith.all;
USE ieee.std_logic_unsigned.all;
USE ieee.numeric_std.all;

ENTITY ddr_tester_check IS
   PORT( 
      clk100_90   : IN     std_logic;
      data_valid  : IN     std_logic;
      output_data : IN     std_logic_vector (31 DOWNTO 0);
      read_done   : IN     std_logic;
      rst_int     : IN     std_logic;
      strt_pb     : IN     std_logic;
      err         : OUT    std_logic;
      error_trig  : OUT    std_logic);
END ddr_tester_check;

ARCHITECTURE flow OF ddr_tester_check IS

   -- Architecture declarations
   SIGNAL data_count : std_logic_vector (15 DOWNTO 0); -- Internal data counter
   SIGNAL expected : std_logic_vector (31 DOWNTO 0); -- Data expected
   SIGNAL expected_old : std_logic_vector (31 DOWNTO 0); -- Data expected, old value
   SIGNAL received : std_logic_vector (31 DOWNTO 0); -- Data received
   SIGNAL received_old : std_logic_vector (31 DOWNTO 0); -- Data received, old value
   SIGNAL check_ena : std_logic; -- Checker enable
   SIGNAL check_ena_old : std_logic; -- Checker enable, old value
   SIGNAL error_count : std_logic_vector (23 DOWNTO 0); -- Error counter

BEGIN

   -----------------------------------------------------------------
   datacount_proc : PROCESS (clk100_90, rst_int)
   -----------------------------------------------------------------
   BEGIN
      -- Asynchronous Reset
      IF (rst_int = '1') THEN
         -- Reset Actions
         data_count <= (others => '0') ;

      ELSIF (clk100_90'EVENT AND clk100_90 = '1') THEN
         IF strt_pb = '1'  THEN
            data_count <= (others => '0') ;
         ELSIF data_valid = '1'  THEN
            data_count <= data_count + "10";
         END IF;
      END IF;
   END PROCESS datacount_proc;

   -----------------------------------------------------------------
   expecteddata_proc : PROCESS (clk100_90, rst_int)
   -----------------------------------------------------------------
   BEGIN
      -- Asynchronous Reset
      IF (rst_int = '1') THEN
         -- Reset Actions
         expected <= (others => '0');
         expected_old <= (others => '0');
         received <= (others => '0');
         received_old <= (others => '0');
         check_ena <= '0';
         check_ena_old <= '0';

      ELSIF (clk100_90'EVENT AND clk100_90 = '1') THEN
         expected <= expected_old;
         expected_old <= data_count & (data_count + '1');
         received <= received_old;
         received_old <= output_data ;
         check_ena <= check_ena_old;
         check_ena_old <= data_valid;
      END IF;
   END PROCESS expecteddata_proc;

   -----------------------------------------------------------------
   compare_proc : PROCESS (clk100_90, rst_int)
   -----------------------------------------------------------------
   BEGIN
      -- Asynchronous Reset
      IF (rst_int = '1') THEN
         -- Reset Actions
         error_count <= (others => '0');
         error_trig <= '0' ;

      ELSIF (clk100_90'EVENT AND clk100_90 = '1') THEN
         IF strt_pb = '1' THEN
            error_count <= (others => '0');
            error_trig <= '0' ;
         ELSIF check_ena = '1' THEN
            IF expected /= received THEN
               error_count <= error_count + '1';
               error_trig <= '1' ;
            END IF;
         END IF;
      END IF;
   END PROCESS compare_proc;

   -----------------------------------------------------------------
   showerror_proc : PROCESS (clk100_90, rst_int)
   -----------------------------------------------------------------
   BEGIN
      -- Asynchronous Reset
      IF (rst_int = '1') THEN
         -- Reset Actions
         err <= '0' ;

      ELSIF (clk100_90'EVENT AND clk100_90 = '1') THEN
         IF strt_pb = '1'  THEN
            err <= '0' ;
         ELSIF read_done = '1'  THEN
            IF error_count /= "000000000000000000000000" THEN
               err <= '1' ;
            ELSE
               err <= '0' ;
            END IF;
         END IF;
      END IF;
   END PROCESS showerror_proc;

END flow;
