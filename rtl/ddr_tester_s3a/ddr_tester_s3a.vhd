library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library unisim;
use unisim.vcomponents.all;

entity ddr_tester_s3a is
	port( 
		sys_clk    : in     std_logic;
		sys_rst    : in     std_logic;
		rst_dqs_div_in : in	std_logic;
		rst_dqs_div_out : out std_logic;
		ddr2_address_fpga : out    std_logic_vector (12 downto 0);
		ddr2_ba_fpga     : out    std_logic_vector (1 downto 0);
		ddr2_cas_n_fpga  : out    std_logic;
		ddr2_ck_fpga     : out    std_logic;
		ddr2_ck_n_fpga   : out    std_logic;
		ddr2_cke_fpga    : out    std_logic;
		ddr2_cs_n_fpga   : out    std_logic;
		ddr2_dm_fpga     : out    std_logic_vector (1 downto 0);
		ddr2_ras_n_fpga  : out    std_logic;
		ddr2_we_n_fpga   : out    std_logic;
		ddr2_odt_fpga    : out	std_logic;
		ddr2_dq_fpga     : inout  std_logic_vector (15 downto 0);
		ddr2_dqs_fpga    : inout  std_logic_vector (1 downto 0);
		ddr2_dqs_n_fpga  : inout  std_logic_vector (1 downto 0);
		init		     : out    std_logic;
		error            : out    std_logic;
		start            : in    std_logic;
		leds             : out    std_logic_vector(7 downto 0));
end ddr_tester_s3a ;

architecture arch of ddr_tester_s3a is

  component ddr_ctrl_dcm is
    port (
		CLKIN_IN        : in    std_logic; 
		RST_IN          : in    std_logic; 
		CLKIN_IBUFG_OUT : out   std_logic; 
		CLK0_OUT        : out   std_logic; 
		CLK90_OUT       : out   std_logic; 
		CLK180_OUT      : out   std_logic; 
		LOCKED_OUT      : out   std_logic);
  end component;

  component ddr_ctrl
    port (
      reset_in_n                   : in    std_logic;
      clk_int                      : in    std_logic;
      clk90_int                    : in    std_logic;
      dcm_lock                     : in    std_logic;
      cntrl0_ddr2_a                : out   std_logic_vector(12 downto 0);
      cntrl0_ddr2_ba               : out   std_logic_vector(1 downto 0);
      cntrl0_ddr2_ras_n            : out   std_logic;
      cntrl0_ddr2_cas_n            : out   std_logic;
      cntrl0_ddr2_we_n             : out   std_logic;
      cntrl0_ddr2_cs_n             : out   std_logic;
      cntrl0_ddr2_odt              : out   std_logic;
      cntrl0_ddr2_cke              : out   std_logic;
      cntrl0_ddr2_ck               : out   std_logic_vector(0 downto 0);
      cntrl0_ddr2_ck_n             : out   std_logic_vector(0 downto 0);
      cntrl0_ddr2_dq               : inout std_logic_vector(15 downto 0);
      cntrl0_ddr2_dqs              : inout std_logic_vector(1 downto 0);
      cntrl0_ddr2_dqs_n            : inout std_logic_vector(1 downto 0);
      cntrl0_ddr2_dm               : out   std_logic_vector(1 downto 0);
      cntrl0_burst_done            : in std_logic;
      cntrl0_init_done             : out std_logic;
      cntrl0_ar_done               : out std_logic;
      cntrl0_user_data_valid       : out std_logic;
      cntrl0_auto_ref_req          : out std_logic;
      cntrl0_user_cmd_ack          : out std_logic;
      cntrl0_user_command_register : in  std_logic_vector(2 downto 0);
      cntrl0_clk_tb                : out std_logic;
      cntrl0_clk90_tb              : out std_logic;
      cntrl0_sys_rst_tb            : out std_logic;
      cntrl0_sys_rst90_tb          : out std_logic;
      cntrl0_sys_rst180_tb         : out std_logic;
      cntrl0_user_output_data      : out  std_logic_vector(31 downto 0);
      cntrl0_user_input_data       : in  std_logic_vector(31 downto 0);
      cntrl0_user_input_address    : in  std_logic_vector(24 downto 0);
      cntrl0_user_data_mask        : in  std_logic_vector(3 downto 0);
      cntrl0_rst_dqs_div_in        : in    std_logic;
      cntrl0_rst_dqs_div_out       : out   std_logic
      );
  end component;
  
	component ddr_tester_check is
		port( 
			clk90       : in     std_logic;
			data_valid  : in     std_logic;
			output_data : in     std_logic_vector (31 downto 0);
			read_done   : in     std_logic;
			rst90       : in     std_logic;
			start       : in     std_logic;
			err         : out    std_logic;
			error_trig  : out    std_logic);
	end component;
	

	component ddr_tester_fsm is
		port( 
			clk0        : in     std_logic;
			clk90       : in     std_logic;
			dcm_lock    : in     std_logic;
			rst0            : in     std_logic;
			rst90           : in     std_logic;
			rst180          : in     std_logic;
			dram_ar_done    : in     std_logic;
			dram_ar_req     : in     std_logic;
			dram_cmd_ack    : in     std_logic;
			dram_init_val   : in     std_logic;
			err             : in     std_logic;
			start           : in     std_logic;
			dram_addr       : out    std_logic_vector (24 downto 0);
			dram_burst_done : out    std_logic;
			dram_cmd_reg    : out    std_logic_vector (2 downto 0);
			dram_data_mask  : out    std_logic_vector (3 downto 0);
			dram_data_w     : out    std_logic_vector (31 downto 0);
			leds            : out    std_logic_vector (7 downto 0);
			read_done       : out    std_logic);
	end component;

  component ddr_ctrl_test_bench_0
    port(
      fpga_clk         : in  std_logic;
      fpga_rst90       : in  std_logic;
      fpga_rst180      : in  std_logic;
      clk90            : in  std_logic;
      burst_done       : out std_logic;
      init_done        : in  std_logic;
      auto_ref_req     : in  std_logic;
      ar_done          : in  std_logic;
      u_ack            : in  std_logic;
      u_data_val       : in  std_logic;
      u_data_o         : in  std_logic_vector(31 downto 0);
      u_addr           : out std_logic_vector(24 downto 0);
      u_cmd            : out std_logic_vector(2 downto 0);
      u_data_m         : out std_logic_vector(3 downto 0);
      u_data_i         : out std_logic_vector(31 downto 0);
      led_error_output : out std_logic;
      data_valid_out   : out std_logic
      );
  end component;

  signal init_done             : std_logic;
  signal error_trig            : std_logic;
  signal ddr2_clk_fpga         : std_logic_vector(0 downto 0);
  signal ddr2_clk_n_fpga       : std_logic_vector(0 downto 0);
  signal data_valid_out        : std_logic;
  signal burst_done            : std_logic;
  signal ar_done               : std_logic;
  signal user_data_valid       : std_logic;
  signal auto_ref_req          : std_logic;
  signal user_cmd_ack          : std_logic;
  signal user_command_register : std_logic_vector(2 downto 0);
  signal clk_tb                : std_logic;
  signal clk90_tb              : std_logic;
  signal sys_rst_tb            : std_logic;
  signal sys_rst90_tb          : std_logic;
  signal sys_rst180_tb         : std_logic;
  signal user_data_mask        : std_logic_vector(3 downto 0);
  signal user_output_data      : std_logic_vector(31 downto 0);
  signal user_input_data       : std_logic_vector(31 downto 0);
  signal user_input_address    : std_logic_vector(24 downto 0);
  signal clk0                  : std_logic;
  signal clk90		           : std_logic; 
  signal clk180                : std_logic;  
  signal sys_rst_n             : std_logic;  
  signal dcm_lock              : std_logic;
  signal read_done             : std_logic;
  signal err                   : std_logic;
  signal leds_fsm              : std_logic_vector(7 downto 0);

begin

  sys_rst_n <= not sys_rst;

  ddr2_ck_fpga <= ddr2_clk_fpga(0);
  ddr2_ck_n_fpga <= ddr2_clk_n_fpga(0);
  
  
  init <= init_done;
  error <= error_trig;
  leds(7) <= init_done;
  leds(6) <= error_trig;
  leds(5 downto 0) <= leds_fsm(5 downto 0);
  
  u1_ddr_ctrl_dcm: ddr_ctrl_dcm
	port map(
		CLKin_in => sys_clk,
		RST_in => sys_rst,
		CLKin_IBUFG_out => OPEN,
		CLK0_out => clk0,
		CLK90_out => clk90,
		CLK180_out => clk180,
		LOCKED_out => dcm_lock);

  u2_ddr_ctrl : ddr_ctrl
    port map (
      clk_int                     => clk0,
      clk90_int                    => clk90,
      dcm_lock						=> dcm_lock,
      reset_in_n                   => sys_rst_n,
      cntrl0_ddr2_ras_n            => ddr2_ras_n_fpga,
      cntrl0_ddr2_cas_n            => ddr2_cas_n_fpga,
      cntrl0_ddr2_we_n             => ddr2_we_n_fpga,
      cntrl0_ddr2_cs_n             => ddr2_cs_n_fpga,
      cntrl0_ddr2_cke              => ddr2_cke_fpga,
      cntrl0_ddr2_odt              => ddr2_odt_fpga,
      cntrl0_ddr2_dm               => ddr2_dm_fpga,
      cntrl0_ddr2_dq               => ddr2_dq_fpga,
      cntrl0_ddr2_dqs              => ddr2_dqs_fpga,
      cntrl0_ddr2_dqs_n            => ddr2_dqs_n_fpga,
      cntrl0_ddr2_ck               => ddr2_clk_fpga,
      cntrl0_ddr2_ck_n             => ddr2_clk_n_fpga,
      cntrl0_ddr2_ba               => ddr2_ba_fpga,
      cntrl0_ddr2_a                => ddr2_address_fpga,
      cntrl0_burst_done            => burst_done,
      cntrl0_init_done             => init_done,
      cntrl0_ar_done               => ar_done,
      cntrl0_user_data_valid       => user_data_valid,
      cntrl0_auto_ref_req          => auto_ref_req,
      cntrl0_user_cmd_ack          => user_cmd_ack,
      cntrl0_user_command_register => user_command_register,
      cntrl0_clk_tb                => clk_tb,
      cntrl0_clk90_tb              => clk90_tb,
      cntrl0_sys_rst_tb            => sys_rst_tb,
      cntrl0_sys_rst90_tb          => sys_rst90_tb,
      cntrl0_sys_rst180_tb         => sys_rst180_tb,
      cntrl0_user_output_data      => user_output_data,
      cntrl0_user_input_data       => user_input_data,
      cntrl0_user_input_address    => user_input_address,
      cntrl0_user_data_mask        => user_data_mask,
      cntrl0_rst_dqs_div_in        => rst_dqs_div_in,
      cntrl0_rst_dqs_div_out       => rst_dqs_div_out
      );
	  
	u3_ddr_tester_check : ddr_tester_check
		port map(
			clk90		=> clk90_tb,
			data_valid  => user_data_valid,
			output_data => user_output_data,
			read_done   => read_done,
			rst90		=> sys_rst90_tb,
			start       => start,
			err         => err,
			error_trig  => error_trig);
		
	u4_ddr_tester_fsm : ddr_tester_fsm
		port map(
			clk0        	=> clk_tb,
			clk90      		=> clk90_tb,
			dcm_lock		=> dcm_lock,
			rst0			=> sys_rst_tb,
			rst90			=> sys_rst90_tb,
			rst180			=> sys_rst180_tb,
			dram_ar_done    => ar_done,
			dram_ar_req     => auto_ref_req,
			dram_cmd_ack    => user_cmd_ack,
			dram_init_val   => init_done,
			err             => err,
			start         	=> start,
			dram_addr       => user_input_address,
			dram_burst_done => burst_done,
			dram_cmd_reg    => user_command_register,
			dram_data_mask  => user_data_mask,
			dram_data_w     => user_input_data,
			leds            => leds_fsm,
			read_done       => read_done);

--  test_bench_00 : ddr_ctrl_test_bench_0
--    port map (
--      fpga_clk         => clk0,
--      fpga_rst90       => sys_rst90_tb,
--      fpga_rst180      => sys_rst180_tb,
--      clk90            => clk90,
--      burst_done       => burst_done,
--      init_done        => init_done,
--      auto_ref_req     => auto_ref_req,
--      ar_done          => ar_done,
--      u_ack            => user_cmd_ack,
--      u_data_val       => user_data_valid,
--      u_data_o         => user_output_data,
--      u_addr           => user_input_address,
--      u_cmd            => user_command_register,
--      u_data_m         => user_data_mask,
--      u_data_i         => user_input_data,
--      led_error_output => error_trig,
--      data_valid_out   => data_valid_out
--      );



end architecture;
