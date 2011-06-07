--------------------------------------------------------------------------------
-- Company: 
-- Engineer:
--
-- Create Date:   18:43:44 06/04/2011
-- Design Name:   
-- Module Name:   /home/lupo/Development/plasma_soc/ise/ddr_tester_s3e/ddr_tester_s3e_tb.vhd
-- Project Name:  ddr_tester_s3e
-- Target Device:  
-- Tool versions:  
-- Description:   
-- 
-- VHDL Test Bench Created by ISE for module: ddr_tester_s3e
-- 
-- Dependencies:
-- 
-- Revision:
-- Revision 0.01 - File Created
-- Additional Comments:
--
-- Notes: 
-- This testbench has been automatically generated using types std_logic and
-- std_logic_vector for the ports of the unit under test.  Xilinx recommends
-- that these types always be used for the top-level I/O of a design in order
-- to guarantee that the testbench will bind correctly to the post-implementation 
-- simulation model.
--------------------------------------------------------------------------------
LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
 
-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--USE ieee.numeric_std.ALL;
 
ENTITY ddr_tester_s3e_tb IS
END ddr_tester_s3e_tb;
 
ARCHITECTURE behavior OF ddr_tester_s3e_tb IS 
 
    -- Component Declaration for the Unit Under Test (UUT)
 
    COMPONENT ddr_tester_s3e
    PORT(
         clk50 : IN  std_logic;
         rst : IN  std_logic;
         strt_pb : IN  std_logic;
         ddr_a : OUT  std_logic_vector(12 downto 0);
         ddr_ba : OUT  std_logic_vector(1 downto 0);
         ddr_cas_n : OUT  std_logic;
         ddr_ck : OUT  std_logic;
         ddr_ck_n : OUT  std_logic;
         ddr_cke : OUT  std_logic;
         ddr_cs_n : OUT  std_logic;
         ddr_dm : OUT  std_logic_vector(1 downto 0);
         ddr_ras_n : OUT  std_logic;
         ddr_we_n : OUT  std_logic;
         error_trig : OUT  std_logic;
         leds : OUT  std_logic_vector(7 downto 0);
         ddr_dq : INOUT  std_logic_vector(15 downto 0);
         ddr_dqs : INOUT  std_logic_vector(1 downto 0)
        );
    END COMPONENT;
	
	COMPONENT ddr_model
	PORT(
		Clk : IN std_logic;
		Clk_n : IN std_logic;
		Cke : IN std_logic;
		Cs_n : IN std_logic;
		Ras_n : IN std_logic;
		Cas_n : IN std_logic;
		We_n : IN std_logic;
		Ba : IN std_logic_vector(1 downto 0);
		Addr : IN std_logic_vector(12 downto 0);
		Dm : IN std_logic_vector(1 downto 0);       
		Dq : INOUT std_logic_vector(15 downto 0);
		Dqs : INOUT std_logic_vector(1 downto 0)
		);
	END COMPONENT;

   --Inputs
   signal clk50 : std_logic := '0';
   signal rst : std_logic := '0';
   signal strt_pb : std_logic := '0';

	--BiDirs
   signal ddr_dq : std_logic_vector(15 downto 0);
   signal ddr_dqs : std_logic_vector(1 downto 0);

 	--Outputs
   signal ddr_a : std_logic_vector(12 downto 0);
   signal ddr_ba : std_logic_vector(1 downto 0);
   signal ddr_cas_n : std_logic;
   signal ddr_ck : std_logic;
   signal ddr_ck_n : std_logic;
   signal ddr_cke : std_logic;
   signal ddr_cs_n : std_logic;
   signal ddr_dm : std_logic_vector(1 downto 0);
   signal ddr_ras_n : std_logic;
   signal ddr_we_n : std_logic;
   signal error_trig : std_logic;
   signal leds : std_logic_vector(7 downto 0);

   -- Clock period definitions
   constant clk50_period : time := 20 ns;
 
BEGIN
 
	-- Instantiate the Unit Under Test (UUT)
   uut: ddr_tester_s3e PORT MAP (
          clk50 => clk50,
          rst => rst,
          strt_pb => strt_pb,
          ddr_a => ddr_a,
          ddr_ba => ddr_ba,
          ddr_cas_n => ddr_cas_n,
          ddr_ck => ddr_ck,
          ddr_ck_n => ddr_ck_n,
          ddr_cke => ddr_cke,
          ddr_cs_n => ddr_cs_n,
          ddr_dm => ddr_dm,
          ddr_ras_n => ddr_ras_n,
          ddr_we_n => ddr_we_n,
          error_trig => error_trig,
          leds => leds,
          ddr_dq => ddr_dq,
          ddr_dqs => ddr_dqs
        );
		
	u_ddr_model: ddr_model PORT MAP(
		Clk => ddr_ck,
		Clk_n => ddr_ck_n,
		Cke => ddr_cke,
		Cs_n => ddr_cs_n,
		Ras_n => ddr_ras_n,
		Cas_n => ddr_cas_n,
		We_n => ddr_we_n,
		Ba => ddr_ba,
		Addr => ddr_a,
		Dm => ddr_dm,
		Dq => ddr_dq,
		Dqs => ddr_dqs
	);

   -- Clock process definitions
   clk50_process :process
   begin
		clk50 <= '0';
		wait for clk50_period/2;
		clk50 <= '1';
		wait for clk50_period/2;
   end process;
 

   -- Stimulus process
   stim_proc: process
   begin		
      -- hold reset state for 100 ns.
      --wait for 100 ns;	

      --wait for clk50_period*10;

      -- insert stimulus here 
	  
		rst <= '0' ;
		strt_pb <= '0' ;
		ddr_dq <= (others => 'Z') ; 
		ddr_dqs <= (others => 'Z') ;
		wait for 100 ns;
		rst <= '1' ;
		wait for 100 ns;
		rst <= '0' ;
		wait for 300 us;
		strt_pb <= '1' ;
		wait for 100 ns;
		strt_pb <= '0' ;

      wait;
   end process;

END;
