library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
library unisim;
use unisim.vcomponents.all;

entity ddr2_tester_tb is
end entity ddr2_tester_tb;

architecture arch of ddr2_tester_tb is

  constant DEVICE_WIDTH    : integer := 16;      -- Memory device data width
  constant CLK_PERIOD_NS   : real := 5000.0 / 1000.0;
  constant TCYC_SYS        : real := CLK_PERIOD_NS/2.0;
  constant TCYC_SYS_0      : time := CLK_PERIOD_NS * 1 ns;
  constant TCYC_SYS_DIV2   : time := TCYC_SYS * 1 ns;
  constant TEMP2           : real := 5.0/2.0;
  constant TCYC_200        : time := TEMP2 * 1 ns;
  constant TPROP_DQS          : time := 0.01 ns;  -- Delay for DQS signal during Write Operation
  constant TPROP_DQS_RD       : time := 0.01 ns;  -- Delay for DQS signal during Read Operation
  constant TPROP_PCB_CTRL     : time := 0.01 ns;  -- Delay for Address and Ctrl signals
  constant TPROP_PCB_DATA     : time := 0.01 ns;  -- Delay for data signal during Write operation
  constant TPROP_PCB_DATA_RD  : time := 0.01 ns;  -- Delay for data signal during Read operation

	component ddr2_tester_v5 is
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
	end component;

  component ddr2_model is
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

  component WireDelay
    generic (
      Delay_g : time;
      Delay_rd : time);
    port (
      A : inout Std_Logic;
      B : inout Std_Logic;
     reset : in Std_Logic);
  end component;

	signal sys_clk                  : std_logic := '0';
	signal sys_clk_n                : std_logic;
	signal sys_clk_p                : std_logic;
	signal sys_clk200               : std_logic:= '0';
--	signal clk200_n                 : std_logic;
--	signal clk200_p                 : std_logic;
	signal sys_rst_n                : std_logic := '0';

	signal ddr2_dq_sdram            : std_logic_vector(63 downto 0);
	signal ddr2_dqs_sdram           : std_logic_vector(7 downto 0);
	signal ddr2_dqs_n_sdram         : std_logic_vector(7 downto 0);
	signal ddr2_dm_sdram            : std_logic_vector(7 downto 0);
	signal ddr2_ck_sdram            : std_logic_vector(1 downto 0);
	signal ddr2_ck_n_sdram          : std_logic_vector(1 downto 0);
	signal ddr2_address_sdram       : std_logic_vector(12 downto 0);
	signal ddr2_ba_sdram            : std_logic_vector(1 downto 0);
	signal ddr2_ras_n_sdram         : std_logic;
	signal ddr2_cas_n_sdram         : std_logic;
	signal ddr2_we_n_sdram          : std_logic;
	signal ddr2_cs_n_sdram          : std_logic_vector(0 downto 0);
	signal ddr2_cke_sdram           : std_logic_vector(0 downto 0);
	signal ddr2_odt_sdram           : std_logic_vector(0 downto 0);

	signal ddr2_dq_fpga             : std_logic_vector(63 downto 0);
	signal ddr2_dqs_fpga            : std_logic_vector(7 downto 0);
	signal ddr2_dqs_n_fpga          : std_logic_vector(7 downto 0);
	signal ddr2_dm_fpga             : std_logic_vector(7 downto 0);
	signal ddr2_ck_fpga             : std_logic_vector(1 downto 0);
	signal ddr2_ck_n_fpga           : std_logic_vector(1 downto 0);
	signal ddr2_address_fpga        : std_logic_vector(12 downto 0);
	signal ddr2_ba_fpga             : std_logic_vector(1 downto 0);
	signal ddr2_ras_n_fpga          : std_logic;
	signal ddr2_cas_n_fpga          : std_logic;
	signal ddr2_we_n_fpga           : std_logic;
	signal ddr2_cs_n_fpga           : std_logic_vector(0 downto 0);
	signal ddr2_cke_fpga            : std_logic_vector(0 downto 0);
	signal ddr2_odt_fpga            : std_logic_vector(0 downto 0);

	signal init_done				: std_logic;
	signal error					: std_logic;
	signal leds						: std_logic_vector(7 downto 0);
--	signal start					: std_logic;

begin

   --***************************************************************************
   -- Clock generation and reset
   --***************************************************************************
  process
  begin
    sys_clk <= not sys_clk;
    wait for (TCYC_SYS_DIV2);
  end process;

   sys_clk_p <= sys_clk;
   sys_clk_n <= not sys_clk;

--   process
--   begin
--     sys_clk200 <= not sys_clk200;
--     wait for (TCYC_200);
--   end process;
--
--   clk200_p <= sys_clk200;
--   clk200_n <= not sys_clk200;

   process
   begin
		sys_rst_n <= '0';
		--start <= '0';
		wait for 200 ns;
		sys_rst_n <= '1';
		--wait for 80 us;
		-- We add this so that we are in a high clock edge
		--wait for (TCYC_SYS_DIV2);
		--start <= '1';
		--wait for 100 ns;
		--start <= '0';	
		wait;
   end process;

  --***************************************************************************
  -- Delay insertion modules for each signal
  --***************************************************************************
  -- Use standard non-inertial (transport) delay mechanism for unidirectional
  -- signals from FPGA to SDRAM
  ddr2_address_sdram  <= TRANSPORT ddr2_address_fpga after TPROP_PCB_CTRL;
  ddr2_ba_sdram       <= TRANSPORT ddr2_ba_fpga      after TPROP_PCB_CTRL;
  ddr2_ras_n_sdram    <= TRANSPORT ddr2_ras_n_fpga   after TPROP_PCB_CTRL;
  ddr2_cas_n_sdram    <= TRANSPORT ddr2_cas_n_fpga   after TPROP_PCB_CTRL;
  ddr2_we_n_sdram     <= TRANSPORT ddr2_we_n_fpga    after TPROP_PCB_CTRL;
  ddr2_cs_n_sdram     <= TRANSPORT ddr2_cs_n_fpga    after TPROP_PCB_CTRL;
  ddr2_cke_sdram      <= TRANSPORT ddr2_cke_fpga     after TPROP_PCB_CTRL;
  ddr2_odt_sdram      <= TRANSPORT ddr2_odt_fpga     after TPROP_PCB_CTRL;
  ddr2_ck_sdram       <= TRANSPORT ddr2_ck_fpga      after TPROP_PCB_CTRL;
  ddr2_ck_n_sdram     <= TRANSPORT ddr2_ck_n_fpga    after TPROP_PCB_CTRL;
  ddr2_dm_sdram       <= TRANSPORT ddr2_dm_fpga      after TPROP_PCB_DATA;

  dq_delay: for i in 0 to 63 generate
    u_delay_dq: WireDelay
      generic map (
        Delay_g => TPROP_PCB_DATA,
        Delay_rd => TPROP_PCB_DATA_RD)
      port map(
        A => ddr2_dq_fpga(i),
        B => ddr2_dq_sdram(i),
        reset => sys_rst_n);
  end generate;

  dqs_delay: for i in 0 to 7 generate
    u_delay_dqs: WireDelay
      generic map (
        Delay_g => TPROP_DQS,
        Delay_rd => TPROP_DQS_RD)
      port map(
        A => ddr2_dqs_fpga(i),
        B => ddr2_dqs_sdram(i),
        reset => sys_rst_n);
  end generate;

  dqs_n_delay: for i in 0 to 7 generate
    u_delay_dqs: WireDelay
      generic map (
        Delay_g => TPROP_DQS,
        Delay_rd => TPROP_DQS_RD)
      port map(
        A => ddr2_dqs_n_fpga(i),
        B => ddr2_dqs_n_sdram(i),
        reset => sys_rst_n);
  end generate;


      gen: for i in 0 to 3 generate
          u_mem0: ddr2_model
            port map (
              ck        => ddr2_ck_sdram(0),
              ck_n      => ddr2_ck_n_sdram(0),
              cke       => ddr2_cke_sdram(0),
              cs_n      => ddr2_cs_n_sdram(0),
              ras_n     => ddr2_ras_n_sdram,
              cas_n     => ddr2_cas_n_sdram,
              we_n      => ddr2_we_n_sdram,
              dm_rdqs   => ddr2_dm_sdram((2*(i+1))-1 downto i*2),
              ba        => ddr2_ba_sdram,
              addr      => ddr2_address_sdram,
              dq        => ddr2_dq_sdram((16*(i+1))-1 downto i*16),
              dqs       => ddr2_dqs_sdram((2*(i+1))-1 downto i*2),
              dqs_n     => ddr2_dqs_n_sdram((2*(i+1))-1 downto i*2),
              rdqs_n    => open,
              odt       => ddr2_odt_sdram(0)
              );
        end generate gen;
  
  u_tester: ddr2_tester_v5 PORT MAP (
		sys_clk_p => sys_clk_p,
		sys_clk_n => sys_clk_n,
--		clk200_p => clk200_p,
--		clk200_n => clk200_n,
		sys_rst_n => sys_rst_n,
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
		init_done => init_done,
		error => error,
--		start => start,
		leds => leds
		);

end architecture;
