--------------------------------------------------------------------------------
-- Company: 
-- Engineer:
--
-- Create Date:   20:23:31 07/06/2011
-- Design Name:   
-- Module Name:   E:/Documents/UoA/Ptyxiakh/plasma_soc/ise/ddr_tester_s3a/ddr_tester_s3a_tb.vhd
-- Project Name:  ddr_tester_s3a
-- Target Device:  
-- Tool versions:  
-- Description:   
-- 
-- VHDL Test Bench Created by ISE for module: ddr_tester_s3a
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
 
ENTITY ddr_tester_s3a_tb IS
END ddr_tester_s3a_tb;
 
ARCHITECTURE behavior OF ddr_tester_s3a_tb IS 
 
    -- Component Declaration for the Unit Under Test (UUT)
 
	COMPONENT ddr_tester_s3a
	PORT(
		sys_clk : IN  std_logic;
		sys_rst : IN  std_logic;
		rst_dqs_div_in : IN  std_logic;
		rst_dqs_div_out : OUT  std_logic;
		ddr2_address_fpga : OUT  std_logic_vector(12 downto 0);
		ddr2_ba_fpga : OUT  std_logic_vector(1 downto 0);
		ddr2_cas_n_fpga : OUT  std_logic;
		ddr2_ck_fpga : OUT  std_logic;
		ddr2_ck_n_fpga : OUT  std_logic;
		ddr2_cke_fpga : OUT  std_logic;
		ddr2_cs_n_fpga : OUT  std_logic;
		ddr2_dm_fpga : OUT  std_logic_vector(1 downto 0);
		ddr2_ras_n_fpga : OUT  std_logic;
		ddr2_we_n_fpga : OUT  std_logic;
		ddr2_odt_fpga : OUT  std_logic;
		ddr2_dq_fpga : INOUT  std_logic_vector(15 downto 0);
		ddr2_dqs_fpga : INOUT  std_logic_vector(1 downto 0);
		ddr2_dqs_n_fpga : INOUT  std_logic_vector(1 downto 0);
		init : OUT  std_logic;
		error : OUT  std_logic;
		start : IN  std_logic;
		leds : OUT  std_logic_vector(7 downto 0)
		);
	END COMPONENT;
	
	component ddr2_model
	port (
		ck      : in    std_logic;
		ck_n    : in    std_logic;
		cke     : in    std_logic;
		cs_n    : in    std_logic;
		ras_n   : in    std_logic;
		cas_n   : in    std_logic;
		we_n    : in    std_logic;
		dm_rdqs : inout std_logic_vector(1 downto 0);
		ba      : in    std_logic_vector(1 downto 0);
		addr    : in    std_logic_vector(12 downto 0);
		dq      : inout std_logic_vector(15 downto 0);
		dqs     : inout std_logic_vector(1 downto 0);
		dqs_n   : inout std_logic_vector(1 downto 0);
		rdqs_n  : out   std_logic_vector(1 downto 0);
		odt     : in    std_logic
		);
	end component;
    

   --Inputs
   signal sys_clk : std_logic := '0';
   signal sys_rst : std_logic := '0';
--   signal rst_dqs_div_in : std_logic := '0';
   signal start : std_logic := '0';

	--BiDirs
   signal ddr2_dq_fpga : std_logic_vector(15 downto 0);
   signal ddr2_dqs_fpga : std_logic_vector(1 downto 0);
   signal ddr2_dqs_n_fpga : std_logic_vector(1 downto 0);

 	--Outputs
--   signal rst_dqs_div_out : std_logic;
   signal ddr2_address_fpga : std_logic_vector(12 downto 0);
   signal ddr2_ba_fpga : std_logic_vector(1 downto 0);
   signal ddr2_cas_n_fpga : std_logic;
   signal ddr2_ck_fpga : std_logic;
   signal ddr2_ck_n_fpga : std_logic;
   signal ddr2_cke_fpga : std_logic;
   signal ddr2_cs_n_fpga : std_logic;
   signal ddr2_dm_fpga : std_logic_vector(1 downto 0);
   signal ddr2_ras_n_fpga : std_logic;
   signal ddr2_we_n_fpga : std_logic;
   signal ddr2_odt_fpga : std_logic;
   signal init : std_logic;
   signal error : std_logic;
   signal leds : std_logic_vector(7 downto 0);
   
   signal rst_dqs_div_loop : std_logic;

   -- Clock period definitions
   constant sys_clk_period : time := 7.519 ns;
 
BEGIN
 
	-- Instantiate the Unit Under Test (UUT)
	uut: ddr_tester_s3a PORT MAP (
		sys_clk => sys_clk,
		sys_rst => sys_rst,
		rst_dqs_div_in => rst_dqs_div_loop,
		rst_dqs_div_out => rst_dqs_div_loop,
		ddr2_address_fpga => ddr2_address_fpga,
		ddr2_ba_fpga => ddr2_ba_fpga,
		ddr2_cas_n_fpga => ddr2_cas_n_fpga,
		ddr2_ck_fpga => ddr2_ck_fpga,
		ddr2_ck_n_fpga => ddr2_ck_n_fpga,
		ddr2_cke_fpga => ddr2_cke_fpga,
		ddr2_cs_n_fpga => ddr2_cs_n_fpga,
		ddr2_dm_fpga => ddr2_dm_fpga,
		ddr2_ras_n_fpga => ddr2_ras_n_fpga,
		ddr2_we_n_fpga => ddr2_we_n_fpga,
		ddr2_odt_fpga => ddr2_odt_fpga,
		ddr2_dq_fpga => ddr2_dq_fpga,
		ddr2_dqs_fpga => ddr2_dqs_fpga,
		ddr2_dqs_n_fpga => ddr2_dqs_n_fpga,
		init => init,
		error => error,
		start => start,
		leds => leds
		);
		
	u_memory : ddr2_model PORT MAP (
		ck      => ddr2_ck_fpga,
		ck_n    => ddr2_ck_n_fpga,
		cke     => ddr2_cke_fpga,
		cs_n    => ddr2_cs_n_fpga,
		ras_n   => ddr2_ras_n_fpga,
		cas_n   => ddr2_cas_n_fpga,
		we_n    => ddr2_we_n_fpga,
		dm_rdqs => ddr2_dm_fpga(1 downto 0),
		ba      => ddr2_ba_fpga,
		addr    => ddr2_address_fpga,
		dq      => ddr2_dq_fpga(15 downto 0),
		dqs     => ddr2_dqs_fpga(1 downto 0),
		dqs_n   => ddr2_dqs_n_fpga(1 downto 0),
		rdqs_n  => open,
		odt     => ddr2_odt_fpga
		);

   -- Clock process definitions
   sys_clk_process :process
   begin
		sys_clk <= '0';
		wait for sys_clk_period/2;
		sys_clk <= '1';
		wait for sys_clk_period/2;
   end process;
 

   -- Stimulus process
   stim_proc: process
   begin		
      -- hold reset state for 100 ns.
      --wait for 100 ns;	
      --wait for sys_clk_period*10;

      -- insert stimulus here 
	  
		sys_rst <= '1';
		start <= '0';
		wait for 200 ns;
		sys_rst <= '0';
		wait for 260 us;
		-- We add this so that we are in a high clock edge
		wait for sys_clk_period/2;
		start <= '1';
		wait for 100 ns;
		start <= '0';	

      wait;
   end process;

END;
