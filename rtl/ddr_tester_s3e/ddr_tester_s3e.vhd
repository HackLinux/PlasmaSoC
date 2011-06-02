LIBRARY ieee;
USE ieee.std_logic_1164.all;
USE ieee.std_logic_arith.all;
USE ieee.std_logic_unsigned.all;
USE ieee.numeric_std.all;

ENTITY ddr_tester_s3e IS
   PORT( 
      clk50      : IN     std_logic;
      rst        : IN     std_logic;
      strt_pb    : IN     std_logic;
      ddr_a      : OUT    std_logic_vector (12 DOWNTO 0);
      ddr_ba     : OUT    std_logic_vector (1 DOWNTO 0);
      ddr_cas_n  : OUT    std_logic;
      ddr_ck     : OUT    std_logic;
      ddr_ck_n   : OUT    std_logic;
      ddr_cke    : OUT    std_logic;
      ddr_cs_n   : OUT    std_logic;
      ddr_dm     : OUT    std_logic_vector (1 DOWNTO 0);
      ddr_ras_n  : OUT    std_logic;
      ddr_we_n   : OUT    std_logic;
      error_trig : OUT    std_logic;
      leds       : OUT    std_logic_vector (7 DOWNTO 0);
      ddr_dq     : INOUT  std_logic_vector (15 DOWNTO 0);
      ddr_dqs    : INOUT  std_logic_vector (1 DOWNTO 0)
   );
END ddr_tester_s3e ;

ARCHITECTURE struct OF ddr_tester_s3e IS

   -- Architecture declarations

   -- Internal signal declarations
   SIGNAL clk100_0        : std_logic;
   SIGNAL clk100_180      : std_logic;
   SIGNAL clk100_90       : std_logic;
   SIGNAL clk100_lock     : std_logic;
   SIGNAL clk100_lock_n   : std_logic;
   SIGNAL cntrl0_ddr_ck   : std_logic_vector(0 DOWNTO 0);
   SIGNAL cntrl0_ddr_ck_n : std_logic_vector(0 DOWNTO 0);
   SIGNAL data_valid      : std_logic;
   SIGNAL dout            : std_logic;
   SIGNAL dram_addr       : std_logic_vector(24 DOWNTO 0);
   SIGNAL dram_ar_done    : std_logic;
   SIGNAL dram_ar_req     : std_logic;
   SIGNAL dram_burst_done : std_logic;
   SIGNAL dram_cmd_ack    : std_logic;
   SIGNAL dram_cmd_reg    : std_logic_vector(2 DOWNTO 0);
   SIGNAL dram_data_mask  : std_logic_vector(3 DOWNTO 0);
   SIGNAL dram_data_w     : std_logic_vector(31 DOWNTO 0);
   SIGNAL dram_init_val   : std_logic;
   SIGNAL err             : std_logic;
   SIGNAL output_data     : std_logic_vector(31 DOWNTO 0);
   SIGNAL read_done       : std_logic;
   SIGNAL rst_dqs_div     : std_logic;
   SIGNAL rst_int         : std_logic;


   -- Component Declarations
	
	component ddr_ctrl_dcm
	port(
		U1_CLKIN_IN : IN std_logic;
		U1_RST_IN : IN std_logic;          
		U1_CLKIN_IBUFG_OUT : OUT std_logic;
		U1_CLK2X_OUT : OUT std_logic;
		U2_CLK0_OUT : OUT std_logic;
		U2_CLK90_OUT : OUT std_logic;
		U2_CLK180_OUT : OUT std_logic;
		U2_LOCKED_OUT : OUT std_logic);
	end component;
		
	component ddr_ctrl
   port(
	   cntrl0_ddr_dq                 : inout std_logic_vector(15 downto 0);
		cntrl0_ddr_a                  : out   std_logic_vector(12 downto 0);
		cntrl0_ddr_ba                 : out   std_logic_vector(1 downto 0);
		cntrl0_ddr_cke                : out   std_logic;
		cntrl0_ddr_cs_n               : out   std_logic;
		cntrl0_ddr_ras_n              : out   std_logic;
		cntrl0_ddr_cas_n              : out   std_logic;
		cntrl0_ddr_we_n               : out   std_logic;
		cntrl0_ddr_dm                 : out   std_logic_vector(1 downto 0);
		cntrl0_rst_dqs_div_in         : in    std_logic;
		cntrl0_rst_dqs_div_out        : out   std_logic;
		reset_in_n                    : in    std_logic;
		cntrl0_burst_done             : in    std_logic;
		cntrl0_init_val               : out   std_logic;
		cntrl0_ar_done                : out   std_logic;
		cntrl0_user_data_valid        : out   std_logic;
		cntrl0_auto_ref_req           : out   std_logic;
		cntrl0_user_cmd_ack           : out   std_logic;
		cntrl0_user_command_register  : in    std_logic_vector(2 downto 0);
		cntrl0_clk_tb                 : out   std_logic;
		cntrl0_clk90_tb               : out   std_logic;
		cntrl0_sys_rst_tb             : out   std_logic;
		cntrl0_sys_rst90_tb           : out   std_logic;
		cntrl0_sys_rst180_tb          : out   std_logic;
		cntrl0_user_data_mask         : in    std_logic_vector(3 downto 0);
		cntrl0_user_output_data       : out   std_logic_vector(31 downto 0);
		cntrl0_user_input_data        : in    std_logic_vector(31 downto 0);
		cntrl0_user_input_address     : in    std_logic_vector(24 downto 0);
		clk_int                       : in    std_logic;
		clk90_int                     : in    std_logic;
		dcm_lock                      : in    std_logic;
		cntrl0_ddr_dqs                : inout std_logic_vector(1 downto 0);
		cntrl0_ddr_ck                 : out   std_logic_vector(0 downto 0);
		cntrl0_ddr_ck_n               : out   std_logic_vector(0 downto 0));
	end component;
	
   COMPONENT ddr_tester_check
   PORT (
      clk100_90   : IN     std_logic ;
      data_valid  : IN     std_logic ;
      output_data : IN     std_logic_vector (31 DOWNTO 0);
      read_done   : IN     std_logic ;
      rst_int     : IN     std_logic ;
      strt_pb     : IN     std_logic ;
      err         : OUT    std_logic ;
      error_trig  : OUT    std_logic 
   );
   END COMPONENT;
	
   COMPONENT ddr_tester_fsm
   PORT (
      clk100_0        : IN     std_logic ;
      clk100_180      : IN     std_logic ;
      clk100_90       : IN     std_logic ;
      clk100_lock     : IN     std_logic ;
      dram_ar_done    : IN     std_logic ;
      dram_ar_req     : IN     std_logic ;
      dram_cmd_ack    : IN     std_logic ;
      dram_init_val   : IN     std_logic ;
      err             : IN     std_logic ;
      rst_int         : IN     std_logic ;
      strt_pb         : IN     std_logic ;
      dram_addr       : OUT    std_logic_vector (24 DOWNTO 0);
      dram_burst_done : OUT    std_logic ;
      dram_cmd_reg    : OUT    std_logic_vector (2 DOWNTO 0);
      dram_data_mask  : OUT    std_logic_vector (3 DOWNTO 0);
      dram_data_w     : OUT    std_logic_vector (31 DOWNTO 0);
      leds            : OUT    std_logic_vector (7 DOWNTO 0);
      read_done       : OUT    std_logic 
   );
   END COMPONENT;

BEGIN
   -- Architecture concurrent statements
   -- HDL Embedded Text Block 1 eb1
   -- eb1 1  
   ddr_ck <= cntrl0_ddr_ck (0);
   ddr_ck_n <= cntrl0_ddr_ck_n (0);


   -- ModuleWare code(v1.7) for instance 'U_2' of 'inv'
   clk100_lock_n <= NOT(clk100_lock);

   -- ModuleWare code(v1.7) for instance 'U_7' of 'inv'
   dout <= NOT(rst);

   -- ModuleWare code(v1.7) for instance 'U_3' of 'or'
   rst_int <= rst OR clk100_lock_n;

   -- Instance port mappings.
		
	u1_ddr_ctrl_dcm: ddr_ctrl_dcm
	port map(
			U1_CLKIN_IN => clk50,
			U1_RST_IN => rst,
			U1_CLKIN_IBUFG_OUT => OPEN,
			U1_CLK2X_OUT => OPEN,
			U2_CLK0_OUT => clk100_0,
			U2_CLK90_OUT => clk100_90,
			U2_CLK180_OUT => clk100_180,
			U2_LOCKED_OUT => clk100_lock);
			
	u2_ddr_ctrl : ddr_ctrl
		port map (
			cntrl0_ddr_dq                 => ddr_dq,
			cntrl0_ddr_a                  => ddr_a,
			cntrl0_ddr_ba                 => ddr_ba,
			cntrl0_ddr_cke                => ddr_cke,
			cntrl0_ddr_cs_n               => ddr_cs_n,
			cntrl0_ddr_ras_n              => ddr_ras_n,
			cntrl0_ddr_cas_n              => ddr_cas_n,
			cntrl0_ddr_we_n               => ddr_we_n,
			cntrl0_ddr_dm                 => ddr_dm,
			cntrl0_rst_dqs_div_in         => rst_dqs_div,
			cntrl0_rst_dqs_div_out        => rst_dqs_div,
			reset_in_n                    => dout,
			cntrl0_burst_done             => dram_burst_done,
			cntrl0_init_val               => dram_init_val,
			cntrl0_ar_done                => dram_ar_done,
			cntrl0_user_data_valid        => data_valid,
			cntrl0_auto_ref_req           => dram_ar_req,
			cntrl0_user_cmd_ack           => dram_cmd_ack,
			cntrl0_user_command_register  => dram_cmd_reg,
			cntrl0_clk_tb                 => OPEN,
			cntrl0_clk90_tb               => OPEN,
			cntrl0_sys_rst_tb             => OPEN,
			cntrl0_sys_rst90_tb           => OPEN,
			cntrl0_sys_rst180_tb          => OPEN,
			cntrl0_user_data_mask         => dram_data_mask,
			cntrl0_user_output_data       => output_data,
			cntrl0_user_input_data        => dram_data_w,
			cntrl0_user_input_address     => dram_addr,
			clk_int                       => clk100_0,
			clk90_int                     => clk100_90,
			dcm_lock                      => clk100_lock,
			cntrl0_ddr_dqs                => ddr_dqs,
			cntrl0_ddr_ck                 => cntrl0_ddr_ck,
			cntrl0_ddr_ck_n               => cntrl0_ddr_ck_n);
			
		
   u3_ddr_tester_check : ddr_tester_check
      PORT MAP (
         clk100_90   => clk100_90,
         data_valid  => data_valid,
         output_data => output_data,
         read_done   => read_done,
         rst_int     => rst_int,
         strt_pb     => strt_pb,
         err         => err,
         error_trig  => error_trig);
		
   u4_ddr_tester_fsm : ddr_tester_fsm
      PORT MAP (
         clk100_0        => clk100_0,
         clk100_180      => clk100_180,
         clk100_90       => clk100_90,
         clk100_lock     => clk100_lock,
         dram_ar_done    => dram_ar_done,
         dram_ar_req     => dram_ar_req,
         dram_cmd_ack    => dram_cmd_ack,
         dram_init_val   => dram_init_val,
         err             => err,
         rst_int         => rst_int,
         strt_pb         => strt_pb,
         dram_addr       => dram_addr,
         dram_burst_done => dram_burst_done,
         dram_cmd_reg    => dram_cmd_reg,
         dram_data_mask  => dram_data_mask,
         dram_data_w     => dram_data_w,
         leds            => leds,
         read_done       => read_done);

END struct;
