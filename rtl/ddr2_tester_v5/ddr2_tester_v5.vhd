library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library unisim;
use unisim.vcomponents.all;

entity ddr2_tester_v5 is
	port( 
		sys_clk_p			: in	std_logic;
		sys_clk_n			: in	std_logic;
--		clk200_p			: in	std_logic;
--		clk200_n			: in	std_logic;
		sys_rst_n			: in	std_logic;
		ddr2_address_fpga	: out	std_logic_vector (12 downto 0);
		ddr2_ba_fpga		: out	std_logic_vector (1 downto 0);
		ddr2_cas_n_fpga		: out	std_logic;
		ddr2_ck_fpga		: out	std_logic_vector(1 downto 0);
		ddr2_ck_n_fpga		: out	std_logic_vector(1 downto 0);
		ddr2_cke_fpga		: out	std_logic_vector(0 downto 0);
		ddr2_cs_n_fpga		: out	std_logic_vector(0 downto 0);
		ddr2_dm_fpga		: out	std_logic_vector (7 downto 0);
		ddr2_ras_n_fpga		: out	std_logic;
		ddr2_we_n_fpga		: out	std_logic;
		ddr2_odt_fpga		: out	std_logic_vector(0 downto 0);
		ddr2_dq_fpga		: inout	std_logic_vector (63 downto 0);
		ddr2_dqs_fpga		: inout	std_logic_vector (7 downto 0);
		ddr2_dqs_n_fpga		: inout	std_logic_vector (7 downto 0);
		init_done			: out	std_logic;
		error				: out	std_logic;
--		start				: in	std_logic;
		leds				: out	std_logic_vector(7 downto 0));
end ddr2_tester_v5;

architecture arch of ddr2_tester_v5 is

	constant BANK_WIDTH            : integer := 2;      -- # of memory bank addr bits
	constant CKE_WIDTH             : integer := 1;      -- # of memory clock enable outputs
	constant CLK_WIDTH             : integer := 2;      -- # of clock outputs
	constant CLK_TYPE              : string  := "DIFFERENTIAL";       -- # of clock type
	constant COL_WIDTH             : integer := 10;     -- # of memory column bits
	constant CS_NUM                : integer := 1;      -- # of separate memory chip selects
	constant CS_WIDTH              : integer := 1;      -- # of total memory chip selects
	constant CS_BITS               : integer := 0;      -- set to log2(CS_NUM) (rounded up)
	constant DM_WIDTH              : integer := 8;      -- # of data mask bits
	constant DQ_WIDTH              : integer := 64;     -- # of data width
	constant DQ_PER_DQS            : integer := 8;      -- # of DQ data bits per strobe
	constant DQ_BITS               : integer := 6;      -- set to log2(DQS_WIDTH*DQ_PER_DQS)
	constant DQS_WIDTH             : integer := 8;      -- # of DQS strobes
	constant DQS_BITS              : integer := 3;      -- set to log2(DQS_WIDTH)
	constant HIGH_PERFORMANCE_MODE : boolean := TRUE; -- Sets the performance mode for IODELAY elements
	constant ODT_WIDTH             : integer := 1;      -- # of memory on-die term enables
	constant ROW_WIDTH             : integer := 13;     -- # of memory row & # of addr bits
	constant APPDATA_WIDTH         : integer := 128;     -- # of usr read/write data bus bits
	constant ADDITIVE_LAT          : integer := 0;      -- additive write latency
	constant BURST_LEN             : integer := 4;      -- burst length (in double words)
	constant BURST_TYPE            : integer := 0;      -- burst type (=0 seq; =1 interlved)
	constant CAS_LAT               : integer := 4;      -- CAS latency
	constant ECC_ENABLE            : integer := 0;      -- enable ECC (=1 enable)
	constant MULTI_BANK_EN         : integer := 1;      -- enable bank management
	constant TWO_T_TIME_EN         : integer := 1;      -- 2t timing for unbuffered dimms
	constant ODT_TYPE              : integer := 1;      -- ODT (=0(none),=1(75),=2(150),=3(50))
	constant REDUCE_DRV            : integer := 0;      -- reduced strength mem I/O (=1 yes)
	constant REG_ENABLE            : integer := 0;      -- registered addr/ctrl (=1 yes)
	constant TREFI_NS              : integer := 7800;   -- auto refresh interval (ns)
	constant TRAS                  : integer := 40000;  -- active->precharge delay
	constant TRCD                  : integer := 15000;  -- active->read/write delay
	constant TRFC                  : integer := 105000;  -- ref->ref, ref->active delay
	constant TRP                   : integer := 15000;  -- precharge->command delay
	constant TRTP                  : integer := 7500;   -- read->precharge delay
	constant TWR                   : integer := 15000;  -- used to determine wr->prech
	constant TWTR                  : integer := 7500;  -- write->read delay
	constant SIM_ONLY              : integer := 1;      -- = 0 to allow power up delay
	constant DEBUG_EN              : integer := 0;      -- Enable debug signals/controls
	constant RST_ACT_LOW           : integer := 1;      -- =1 for active low reset, =0 for active high
	constant DLL_FREQ_MODE         : string  := "HIGH"; -- DCM Frequency range
	constant CLK_PERIOD            : integer := 5000;   -- Core/Mem clk period (in ps)

	component ddr2_ctrl_v5 is
    generic (
      BANK_WIDTH            : integer;
      CKE_WIDTH             : integer;
      CLK_WIDTH             : integer;
      COL_WIDTH             : integer;
      CS_NUM                : integer;
      CS_WIDTH              : integer;
      CS_BITS               : integer;
      DM_WIDTH              : integer;
      DQ_WIDTH              : integer;
      DQ_PER_DQS            : integer;
      DQ_BITS               : integer;
      DQS_WIDTH             : integer;
      DQS_BITS              : integer;
      HIGH_PERFORMANCE_MODE : boolean;
      ODT_WIDTH             : integer;
      ROW_WIDTH             : integer;
      APPDATA_WIDTH         : integer;
      ADDITIVE_LAT          : integer;
      BURST_LEN             : integer;
      BURST_TYPE            : integer;
      CAS_LAT               : integer;
      ECC_ENABLE            : integer;
      MULTI_BANK_EN         : integer;
      ODT_TYPE              : integer;
      REDUCE_DRV            : integer;
      REG_ENABLE            : integer;
      TREFI_NS              : integer;
      TRAS                  : integer;
      TRCD                  : integer;
      TRFC                  : integer;
      TRP                   : integer;
      TRTP                  : integer;
      TWR                   : integer;
      TWTR                  : integer;
      SIM_ONLY              : integer;
      RST_ACT_LOW           : integer;
      CLK_TYPE              : string;
      DLL_FREQ_MODE         : string;
      CLK_PERIOD            : integer
      );
    port (
      sys_rst_n             : in    std_logic;
      sys_clk_p             : in    std_logic;
      sys_clk_n             : in    std_logic;
      clk200_p              : in    std_logic;
      clk200_n              : in    std_logic;
      ddr2_a                : out   std_logic_vector(12 downto 0);
      ddr2_ba               : out   std_logic_vector(1 downto 0);
      ddr2_ras_n            : out   std_logic;
      ddr2_cas_n            : out   std_logic;
      ddr2_we_n             : out   std_logic;
      ddr2_cs_n             : out   std_logic_vector(0 downto 0);
      ddr2_odt              : out   std_logic_vector(0 downto 0);
      ddr2_cke              : out   std_logic_vector(0 downto 0);
      ddr2_ck               : out   std_logic_vector(1 downto 0);
      ddr2_ck_n             : out   std_logic_vector(1 downto 0);
      ddr2_dq               : inout std_logic_vector(63 downto 0);
      ddr2_dqs              : inout std_logic_vector(7 downto 0);
      ddr2_dqs_n            : inout std_logic_vector(7 downto 0);
      ddr2_dm               : out   std_logic_vector(7 downto 0);
      
      clk0_tb               : out   std_logic;
      rst0_tb               : out   std_logic;
      app_af_afull          : out   std_logic;
      app_wdf_afull         : out   std_logic;
      rd_data_valid         : out   std_logic;
      rd_data_fifo_out      : out   std_logic_vector(127 downto 0);
      app_af_wren           : in    std_logic;
      app_af_cmd            : in    std_logic_vector(2 downto 0);
      app_af_addr           : in    std_logic_vector(30 downto 0);
      app_wdf_wren          : in    std_logic;
      app_wdf_data          : in    std_logic_vector(127 downto 0);
      app_wdf_mask_data     : in    std_logic_vector(15 downto 0); 
      phy_init_done         : out   std_logic
      );
  end component;

--	component ddr2_tester_check is
--		port( 
--			clk90       : in     std_logic;
--			data_valid  : in     std_logic;
--			output_data : in     std_logic_vector (127 downto 0);
--			read_done   : in     std_logic;
--			rst90       : in     std_logic;
--			start       : in     std_logic;
--			err         : out    std_logic;
--			error_trig  : out    std_logic);
--	end component;
--	
--
--	component ddr2_tester_fsm is
--		port( 
--			clk0				: in	std_logic;
--			rst0				: in	std_logic;
--			phy_init_done		: in	std_logic;
--			app_af_afull		: in	std_logic;
--			app_wdf_afull		: in	std_logic;
--			app_af_wren			: out	std_logic;
--			app_af_addr			: out	std_logic_vector (24 downto 0);
--			app_af_cmd			: out	std_logic_vector (2 downto 0);
--			app_wdf_wren		: out	std_logic;
--			app_wdf_data		: out	std_logic_vector(127 downto 0);
--			app_wdf_mask_data	: out	std_logic_vector(15 downto 0);
--			err					: in	std_logic;
--			start				: in	std_logic;
--			leds				: out	std_logic_vector (7 downto 0);
--			read_done			: out	std_logic);
--	end component;

  component ddr2_tb_top is
    generic (
      BANK_WIDTH        : integer;
      COL_WIDTH         : integer;
      DM_WIDTH          : integer;
      DQ_WIDTH          : integer;
      ROW_WIDTH         : integer;
      APPDATA_WIDTH     : integer;
      ECC_ENABLE        : integer;
      BURST_LEN         : integer
      );
    port (
      clk0              : in  std_logic;
      rst0              : in  std_logic;
      app_af_afull      : in  std_logic;
      app_wdf_afull     : in  std_logic;
      rd_data_valid     : in  std_logic;
      rd_data_fifo_out  : in  std_logic_vector(127 downto 0);
      phy_init_done     : in  std_logic;
      app_af_wren       : out std_logic;
      app_af_cmd        : out std_logic_vector(2 downto 0);
      app_af_addr       : out std_logic_vector(30 downto 0);
      app_wdf_wren      : out std_logic;
      app_wdf_data      : out std_logic_vector(127 downto 0);
      app_wdf_mask_data : out std_logic_vector(15 downto 0);
      error             : out std_logic
      );
  end component;

--	signal sys_rst				: std_logic; 
--	signal err					: std_logic;
--	signal read_done			: std_logic;
--	signal leds_fsm				: std_logic_vector(7 downto 0);

	signal clk200_p				: std_logic;
	signal clk200_n				: std_logic;
    
	signal clk0_tb				: std_logic;
	signal rst0_tb				: std_logic;
	signal app_af_afull			: std_logic;
	signal app_wdf_afull		: std_logic;
	signal rd_data_valid		: std_logic;
	signal rd_data_fifo_out		: std_logic_vector(127 downto 0);
	signal app_af_wren			: std_logic;
	signal app_af_cmd			: std_logic_vector(2 downto 0);
	signal app_af_addr			: std_logic_vector(30 downto 0);
	signal app_wdf_wren			: std_logic;
	signal app_wdf_data			: std_logic_vector(127 downto 0);
	signal app_wdf_mask_data	: std_logic_vector(15 downto 0);
	signal phy_init_done		: std_logic;
	signal error_trig			: std_logic;

begin

	init_done <= phy_init_done;
	error <= error_trig;
	leds(7) <= phy_init_done;
	leds(6) <= error_trig;
	leds(5 downto 0) <= (others => '0');
	
	clk200_p <= sys_clk_p;
	clk200_n <= sys_clk_n;

--  leds(5 downto 0) <= leds_fsm(5 downto 0);
--	app_af_addr(30 downto 25) <= "111111";
--	sys_rst <= not sys_rst_n;
  
  u2_ddr2_ctrl : ddr2_ctrl_v5
    generic map (
      BANK_WIDTH            => BANK_WIDTH,
      CKE_WIDTH             => CKE_WIDTH,
      CLK_WIDTH             => CLK_WIDTH,
      COL_WIDTH             => COL_WIDTH,
      CS_NUM                => CS_NUM,
      CS_WIDTH              => CS_WIDTH,
      CS_BITS               => CS_BITS,
      DM_WIDTH              => DM_WIDTH,
      DQ_WIDTH              => DQ_WIDTH,
      DQ_PER_DQS            => DQ_PER_DQS,
      DQ_BITS               => DQ_BITS,
      DQS_WIDTH             => DQS_WIDTH,
      DQS_BITS              => DQS_BITS,
      HIGH_PERFORMANCE_MODE => HIGH_PERFORMANCE_MODE,
      ODT_WIDTH             => ODT_WIDTH,
      ROW_WIDTH             => ROW_WIDTH,
      APPDATA_WIDTH         => APPDATA_WIDTH,
      ADDITIVE_LAT          => ADDITIVE_LAT,
      BURST_LEN             => BURST_LEN,
      BURST_TYPE            => BURST_TYPE,
      CAS_LAT               => CAS_LAT,
      ECC_ENABLE            => ECC_ENABLE,
      MULTI_BANK_EN         => MULTI_BANK_EN,
      ODT_TYPE              => ODT_TYPE,
      REDUCE_DRV            => REDUCE_DRV,
      REG_ENABLE            => REG_ENABLE,
      TREFI_NS              => TREFI_NS,
      TRAS                  => TRAS,
      TRCD                  => TRCD,
      TRFC                  => TRFC,
      TRP                   => TRP,
      TRTP                  => TRTP,
      TWR                   => TWR,
      TWTR                  => TWTR,
      SIM_ONLY              => SIM_ONLY,
      RST_ACT_LOW           => RST_ACT_LOW,
      CLK_TYPE              => CLK_TYPE,
      DLL_FREQ_MODE         => DLL_FREQ_MODE,
      CLK_PERIOD            => CLK_PERIOD
      )
    port map (
      sys_clk_p         => sys_clk_p,
      sys_clk_n         => sys_clk_n,
      clk200_p          => clk200_p,
      clk200_n          => clk200_n,
      sys_rst_n         => sys_rst_n,
      ddr2_ras_n        => ddr2_ras_n_fpga,
      ddr2_cas_n        => ddr2_cas_n_fpga,
      ddr2_we_n         => ddr2_we_n_fpga,
      ddr2_cs_n         => ddr2_cs_n_fpga,
      ddr2_cke          => ddr2_cke_fpga,
      ddr2_odt          => ddr2_odt_fpga,
      ddr2_dm           => ddr2_dm_fpga,
      ddr2_dq           => ddr2_dq_fpga,
      ddr2_dqs          => ddr2_dqs_fpga,
      ddr2_dqs_n        => ddr2_dqs_n_fpga,
      ddr2_ck           => ddr2_ck_fpga,
      ddr2_ck_n         => ddr2_ck_n_fpga,
      ddr2_ba           => ddr2_ba_fpga,
      ddr2_a            => ddr2_address_fpga,
      
      clk0_tb           => clk0_tb,
      rst0_tb           => rst0_tb,
      app_af_afull      => app_af_afull,
      app_wdf_afull     => app_wdf_afull,
      rd_data_valid     => rd_data_valid,
      rd_data_fifo_out  => rd_data_fifo_out,
      app_af_wren       => app_af_wren,
      app_af_cmd        => app_af_cmd,
      app_af_addr       => app_af_addr,
      app_wdf_wren      => app_wdf_wren,
      app_wdf_data      => app_wdf_data,
      app_wdf_mask_data => app_wdf_mask_data,
      phy_init_done     => phy_init_done
      );
	  
--	u3_ddr2_tester_check : ddr2_tester_check
--		port map(
--			clk90		=> clk0_tb,
--			data_valid  => rd_data_valid,
--			output_data => rd_data_fifo_out,
--			read_done   => read_done,
--			rst90		=> rst0_tb,
--			start       => start,
--			err         => err,
--			error_trig  => error_trig);
--		
--	u4_ddr2_tester_fsm : ddr2_tester_fsm
--		port map(
--			clk0				=> clk0_tb,
--			rst0				=> rst0_tb,
--			phy_init_done		=> phy_init_done,
--			app_af_afull		=> app_af_afull,
--            app_wdf_afull		=> app_wdf_afull,
--			app_af_wren			=> app_af_wren,
--			app_af_addr			=> app_af_addr(24 downto 0),
--			app_af_cmd			=> app_af_cmd,
--			app_wdf_wren		=> app_wdf_wren,
--			app_wdf_mask_data	=> app_wdf_mask_data,
--			app_wdf_data		=> app_wdf_data,
--			err					=> err,
--			start				=> start,
--			leds				=> leds_fsm,
--			read_done			=> read_done);

	u_tb_top : ddr2_tb_top
    generic map (
      BANK_WIDTH    => BANK_WIDTH,
      COL_WIDTH     => COL_WIDTH,
      DM_WIDTH      => DM_WIDTH,
      DQ_WIDTH      => DQ_WIDTH,
      ROW_WIDTH     => ROW_WIDTH,
      APPDATA_WIDTH => APPDATA_WIDTH,
      ECC_ENABLE    => ECC_ENABLE,
      BURST_LEN     => BURST_LEN
      )
    port map (
      clk0              => clk0_tb,
      rst0              => rst0_tb,
      app_af_afull      => app_af_afull,
      app_wdf_afull     => app_wdf_afull,
      rd_data_valid     => rd_data_valid,
      rd_data_fifo_out  => rd_data_fifo_out,
      phy_init_done     => phy_init_done,
      app_af_wren       => app_af_wren,
      app_af_cmd        => app_af_cmd,
      app_af_addr       => app_af_addr,
      app_wdf_wren      => app_wdf_wren,
      app_wdf_data      => app_wdf_data,
      app_wdf_mask_data => app_wdf_mask_data,
      error             => error_trig
      );

end architecture;
