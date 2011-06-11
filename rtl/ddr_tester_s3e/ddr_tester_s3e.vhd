library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;
use ieee.numeric_std.all;

entity ddr_tester_s3e is
	port( 
		clk50      : in     std_logic;
		rst        : in     std_logic;
		strt_pb    : in     std_logic;
		ddr_a      : out    std_logic_vector (12 downto 0);
		ddr_ba     : out    std_logic_vector (1 downto 0);
		ddr_cas_n  : out    std_logic;
		ddr_ck     : out    std_logic;
		ddr_ck_n   : out    std_logic;
		ddr_cke    : out    std_logic;
		ddr_cs_n   : out    std_logic;
		ddr_dm     : out    std_logic_vector (1 downto 0);
		ddr_ras_n  : out    std_logic;
		ddr_we_n   : out    std_logic;
		error_trig : out    std_logic;
		leds       : out    std_logic_vector (7 downto 0);
		ddr_dq     : inout  std_logic_vector (15 downto 0);
		ddr_dqs    : inout  std_logic_vector (1 downto 0));
end ddr_tester_s3e ;

architecture Behavioral of ddr_tester_s3e is

	signal clk100_0        : std_logic;
	signal clk100_180      : std_logic;
	signal clk100_90       : std_logic;
	signal clk100_lock     : std_logic;
	signal clk100_lock_n   : std_logic;
	signal cntrl0_ddr_ck   : std_logic_vector(0 downto 0);
	signal cntrl0_ddr_ck_n : std_logic_vector(0 downto 0);
	signal data_valid      : std_logic;
	signal dout            : std_logic;
	signal dram_addr       : std_logic_vector(24 downto 0);
	signal dram_ar_done    : std_logic;
	signal dram_ar_req     : std_logic;
	signal dram_burst_done : std_logic;
	signal dram_cmd_ack    : std_logic;
	signal dram_cmd_reg    : std_logic_vector(2 downto 0);
	signal dram_data_mask  : std_logic_vector(3 downto 0);
	signal dram_data_w     : std_logic_vector(31 downto 0);
	signal dram_init_val   : std_logic;
	signal err             : std_logic;
	signal output_data     : std_logic_vector(31 downto 0);
	signal read_done       : std_logic;
	signal rst_dqs_div     : std_logic;
	signal rst_int         : std_logic;
	
	component ddr_ctrl_dcm
		port(
			U1_CLKin_in : in std_logic;
			U1_RST_in : in std_logic;          
			U1_CLKin_IBUFG_out : out std_logic;
			U1_CLK2X_out : out std_logic;
			U2_CLK0_out : out std_logic;
			U2_CLK90_out : out std_logic;
			U2_CLK180_out : out std_logic;
			U2_LOCKED_out : out std_logic);
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
	
	component ddr_tester_check
		port (
			clk100_90   : in     std_logic ;
			data_valid  : in     std_logic ;
			output_data : in     std_logic_vector (31 downto 0);
			read_done   : in     std_logic ;
			rst_int     : in     std_logic ;
			strt_pb     : in     std_logic ;
			err         : out    std_logic ;
			error_trig  : out    std_logic );
	end component;
	
	component ddr_tester_fsm
		port (
			clk100_0        : in     std_logic ;
			clk100_180      : in     std_logic ;
			clk100_90       : in     std_logic ;
			clk100_lock     : in     std_logic ;
			dram_ar_done    : in     std_logic ;
			dram_ar_req     : in     std_logic ;
			dram_cmd_ack    : in     std_logic ;
			dram_init_val   : in     std_logic ;
			err             : in     std_logic ;
			rst_int         : in     std_logic ;
			strt_pb         : in     std_logic ;
			dram_addr       : out    std_logic_vector (24 downto 0);
			dram_burst_done : out    std_logic ;
			dram_cmd_reg    : out    std_logic_vector (2 downto 0);
			dram_data_mask  : out    std_logic_vector (3 downto 0);
			dram_data_w     : out    std_logic_vector (31 downto 0);
			leds            : out    std_logic_vector (7 downto 0);
			read_done       : out    std_logic );
	end component;

BEGin

	ddr_ck <= cntrl0_ddr_ck(0);
	ddr_ck_n <= cntrl0_ddr_ck_n(0);
	clk100_lock_n <= not(clk100_lock);
	dout <= not(rst);
	rst_int <= rst or clk100_lock_n;
   
	u1_ddr_ctrl_dcm: ddr_ctrl_dcm
		port map(
			U1_CLKin_in => clk50,
			U1_RST_in => rst,
			U1_CLKin_IBUFG_out => OPEN,
			U1_CLK2X_out => OPEN,
			U2_CLK0_out => clk100_0,
			U2_CLK90_out => clk100_90,
			U2_CLK180_out => clk100_180,
			U2_LOCKED_out => clk100_lock);
			
	u2_ddr_ctrl : ddr_ctrl
		port map(
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
		port map(
			clk100_90   => clk100_90,
			data_valid  => data_valid,
			output_data => output_data,
			read_done   => read_done,
			rst_int     => rst_int,
			strt_pb     => strt_pb,
			err         => err,
			error_trig  => error_trig);
		
	u4_ddr_tester_fsm : ddr_tester_fsm
		port map(
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

end Behavioral;
