---------------------------------------------------------------------
-- TITLE: Plamsa Interface (clock divider and interface to FPGA board)
-- AUTHOR: Steve Rhoads (rhoadss@yahoo.com)
-- DATE CREATED: 9/15/07
-- FILENAME: plasma_3e.vhd
-- PROJECT: Plasma CPU core
-- COPYRIGHT: Software placed into the public domain by the author.
--    Software 'as is' without warranty.  Author liable for nothing.
-- DESCRIPTION:
--    This entity divides the clock by two and interfaces to the 
--    Xilinx Spartan-3E XC3S200FT256-4 FPGA with DDR.
---------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.std_logic_arith.all;
--use work.mlite_pack.all;

entity plasma_s3a is
	port(
		CLK_133MHZ  : in std_logic;
		RS232_DCE_RXD : in std_logic;
        RS232_DCE_TXD : out std_logic;

        SD_CK_P    : out std_logic;     --DDR SDRAM clock_positive
        SD_CK_N    : out std_logic;     --clock_negative
        SD_CKE     : out std_logic;     --clock_enable
        SD_BA      : out std_logic_vector(1 downto 0);  --bank_address
        SD_A       : out std_logic_vector(12 downto 0); --address(row or col)
        SD_CS      : out std_logic;     --chip_select
        SD_RAS     : out std_logic;     --row_address_strobe
        SD_CAS     : out std_logic;     --column_address_strobe
        SD_WE      : out std_logic;     --write_enable
        SD_DQ      : inout std_logic_vector(15 downto 0); --data
        SD_UDM     : out std_logic;     --upper_byte_enable
        SD_UDQS_P  : inout std_logic;   --upper_data_strobe positive
		SD_UDQS_N  : inout std_logic;   --upper_data_strobe negative
        SD_LDM     : out std_logic;     --low_byte_enable
        SD_LDQS_P  : inout std_logic;   --low_data_strobe positive
	    SD_LDQS_N  : inout std_logic;   --low_data_strobe negative
		SD_LOOP_IN : in std_logic;
		SD_LOOP_OUT : out std_logic;
		SD_ODT		: out std_logic;

        E_MDC      : out std_logic;     --Ethernet PHY
        E_MDIO     : inout std_logic;   --management data in/out
        E_RX_CLK   : in std_logic;      --receive clock
        E_RX_DV    : in std_logic;      --data valid
        E_RXD      : in std_logic_vector(3 downto 0);
        E_TX_CLK   : in std_logic;      --transmit clock
        E_TX_EN    : out std_logic;     --data valid
        E_TXD      : out std_logic_vector(3 downto 0);

--        SF_CE0     : out std_logic;     --NOR flash
--        SF_OE      : out std_logic;
--        SF_WE      : out std_logic;
--        SF_BYTE    : out std_logic;
--        SF_STS     : in std_logic;      --status
--        SF_A       : out std_logic_vector(24 downto 0);
--        SF_D       : inout std_logic_vector(15 downto 1);
--        SPI_MISO   : inout std_logic;

        VGA_VSYNC  : out std_logic;     --VGA port
        VGA_HSYNC  : out std_logic;
        VGA_RED    : out std_logic;
        VGA_GREEN  : out std_logic;
        VGA_BLUE   : out std_logic;

        PS2_CLK    : in std_logic;      --Keyboard
        PS2_DATA   : in std_logic;

        LED        : out std_logic_vector(7 downto 0);
        ROT_CENTER : in std_logic;
        ROT_A      : in std_logic;
        ROT_B      : in std_logic;
        BTN_EAST   : in std_logic;
        BTN_NORTH  : in std_logic;
        BTN_SOUTH  : in std_logic;
        BTN_WEST   : in std_logic;
        SW         : in std_logic_vector(3 downto 0));
end; --entity plasma_s3a


architecture logic of plasma_s3a is

	component plasma
	generic(memory_type : string := "XILINX_16X"; --"DUAL_PORT_" "ALTERA_LPM";
			log_file    : string := "UNUSED";
			ethernet    : std_logic := '0';
			use_cache   : std_logic := '0');
	port(clk          : in std_logic;
			reset        : in std_logic;
			uart_write   : out std_logic;
			uart_read    : in std_logic;

			address      : out std_logic_vector(31 downto 2);
			byte_we      : out std_logic_vector(3 downto 0); 
			data_write   : out std_logic_vector(31 downto 0);
			data_read    : in std_logic_vector(31 downto 0);
			mem_pause_in : in std_logic;
			no_ddr_start : out std_logic;
			no_ddr_stop  : out std_logic;

			gpio0_out    : out std_logic_vector(31 downto 0);
			gpioA_in     : in std_logic_vector(31 downto 0));
	end component; --plasma

--   component ddr_ctrl
--      port(clk      : in std_logic;
--           clk_2x   : in std_logic;
--           reset_in : in std_logic;
--
--           address  : in std_logic_vector(25 downto 2);
--           byte_we  : in std_logic_vector(3 downto 0);
--           data_w   : in std_logic_vector(31 downto 0);
--           data_r   : out std_logic_vector(31 downto 0);
--           active   : in std_logic;
--           no_start : in std_logic;
--           no_stop  : in std_logic;
--           pause    : out std_logic;
--
--           SD_CK_P  : out std_logic;     --clock_positive
--           SD_CK_N  : out std_logic;     --clock_negative
--           SD_CKE   : out std_logic;     --clock_enable
--
--           SD_BA    : out std_logic_vector(1 downto 0);  --bank_address
--           SD_A     : out std_logic_vector(12 downto 0); --address(row or col)
--           SD_CS    : out std_logic;     --chip_select
--           SD_RAS   : out std_logic;     --row_address_strobe
--           SD_CAS   : out std_logic;     --column_address_strobe
--           SD_WE    : out std_logic;     --write_enable
--
--           SD_DQ    : inout std_logic_vector(15 downto 0); --data
--           SD_UDM   : out std_logic;     --upper_byte_enable
--           SD_UDQS  : inout std_logic;   --upper_data_strobe
--           SD_LDM   : out std_logic;     --low_byte_enable
--           SD_LDQS  : inout std_logic);  --low_data_strobe
--   end component; --ddr

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
		cntrl0_rst_dqs_div_out       : out   std_logic);
	end component;
  
	component ddr_ctrl_fsm is
	port( 
		clk0			: in	std_logic;
		clk90			: in	std_logic;
		dcm_lock		: in	std_logic;
		rst0			: in	std_logic;
		rst90			: in	std_logic;
		rst180			: in	std_logic;
		dram_ar_done	: in	std_logic;
		dram_ar_req		: in	std_logic;
		dram_cmd_ack	: in	std_logic;
		dram_init_done	: in	std_logic;
		dram_data_valid	: in	std_logic;
		err				: in	std_logic;
		no_ddr_start	: in	std_logic;
		no_ddr_stop		: in	std_logic;
		active			: in	std_logic;
		byte_we			: in	std_logic_vector(3 downto 0);
		dram_addr		: out	std_logic_vector (24 downto 0);
		dram_burst_done	: out	std_logic;
		dram_cmd_reg	: out	std_logic_vector (2 downto 0);
		dram_data_mask	: out	std_logic_vector (3 downto 0);
		dram_data_r		: in	std_logic_vector (31 downto 0);
		dram_data_w		: out	std_logic_vector (31 downto 0);
		leds			: out	std_logic_vector (7 downto 0);
		pause			: out	std_logic);
	end component;

	signal clk_reg      : std_logic;
	signal address      : std_logic_vector(31 downto 2);
	signal data_write   : std_logic_vector(31 downto 0);
	signal data_read    : std_logic_vector(31 downto 0);
	signal data_r_ddr   : std_logic_vector(31 downto 0);
	signal byte_we      : std_logic_vector(3 downto 0);
	signal write_enable : std_logic;
	signal pause_ddr    : std_logic;
	signal pause        : std_logic;
	signal no_ddr_start : std_logic;
	signal no_ddr_stop  : std_logic;
	signal ddr_active   : std_logic;
	signal flash_active : std_logic;
	signal flash_cnt    : std_logic_vector(1 downto 0);
	signal flash_we     : std_logic;
	signal reset        : std_logic;
	signal reset_n      : std_logic;
	signal gpio0_out    : std_logic_vector(31 downto 0);
	signal gpio0_in     : std_logic_vector(31 downto 0);

	signal init_done             : std_logic;
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
	signal dcm_lock              : std_logic;
	signal err						: std_logic;
	signal leds_fsm					: std_logic_vector(7 downto 0);
	signal ddr2_ck_fpga				: std_logic_vector(0 downto 0);
	signal ddr2_ck_n_fpga			: std_logic_vector(0 downto 0);	
	signal ddr2_dqs_fpga			: std_logic_vector(1 downto 0);
	signal ddr2_dqs_n_fpga			: std_logic_vector(1 downto 0);
	signal ddr2_dm_fpga				: std_logic_vector(1 downto 0);
   
begin  --architecture

	--Divide 133 MHz clock by two
	clk_div: process(reset, clk0, clk_reg)
	begin
		if reset = '1' then
			clk_reg <= '0';
		elsif rising_edge(clk0) then
			clk_reg <= not clk_reg;
		end if;
	end process; --clk_div

	reset <= ROT_CENTER;
	E_TX_EN   <= gpio0_out(28);  --Ethernet
	E_TXD     <= gpio0_out(27 downto 24);
	E_MDC     <= gpio0_out(23);
	E_MDIO    <= gpio0_out(21) when gpio0_out(22) = '1' else 'Z';
	VGA_VSYNC <= gpio0_out(20);
	VGA_HSYNC <= gpio0_out(19);
	VGA_RED   <= gpio0_out(18);
	VGA_GREEN <= gpio0_out(17);
	VGA_BLUE  <= gpio0_out(16);
	LED <= gpio0_out(7 downto 0);
	gpio0_in(31 downto 21) <= (others => '0');
	gpio0_in(20 downto 13) <= E_RX_CLK & E_RX_DV & E_RXD & E_TX_CLK & E_MDIO;
	gpio0_in(12 downto 10) <= '0' & PS2_CLK & PS2_DATA; -- SF_STS & PS2_CLK & PS2_DATA;
	gpio0_in(9 downto 0) <= ROT_A & ROT_B & BTN_EAST & BTN_NORTH & BTN_SOUTH & BTN_WEST & SW;
	ddr_active <= '1' when address(31 downto 28) = "0001" else '0';
	flash_active <= '0'; --'1' when address(31 downto 28) = "0011" else '0';
	write_enable <= '1' when byte_we /= "0000" else '0';

	data_read <= user_output_data;
	user_input_data <= data_write;

	pause_ddr <= user_cmd_ack;
	
	reset_n <= not reset;

	SD_CK_P <= ddr2_ck_fpga(0);
	SD_CK_N <= ddr2_ck_n_fpga(0);
	
	SD_UDM <= ddr2_dm_fpga(1);
	SD_LDM <= ddr2_dm_fpga(0);
	
	SD_UDQS_P <= ddr2_dqs_fpga(1);
	SD_LDQS_P <= ddr2_dqs_fpga(0);
	
	SD_UDQS_N <= ddr2_dqs_n_fpga(1);
	SD_LDQS_N <= ddr2_dqs_n_fpga(0);
	
	u0_plama: plasma 
	generic map (
		memory_type => "XILINX_16X",
		log_file    => "UNUSED",
		ethernet    => '1',
		use_cache   => '1')
	port map (
		clk          => clk_reg,
		reset        => reset,
		uart_write   => RS232_DCE_TXD,
		uart_read    => RS232_DCE_RXD,

		address      => address,
		byte_we      => byte_we,
		data_write   => data_write,
		data_read    => data_read,
		mem_pause_in => pause,
		no_ddr_start => no_ddr_start,
		no_ddr_stop  => no_ddr_stop,

		gpio0_out    => gpio0_out,
		gpioA_in     => gpio0_in);
         
--   u2_ddr: ddr_ctrl
--      port map (
--         clk      => clk_reg,
--         clk_2x   => CLK_50MHZ,
--         reset_in => reset,
--
--         address  => address(25 downto 2),
--         byte_we  => byte_we,
--         data_w   => data_write,
--         data_r   => data_r_ddr,
--         active   => ddr_active,
--         no_start => no_ddr_start,
--         no_stop  => no_ddr_stop,
--         pause    => pause_ddr,
--
--         SD_CK_P  => SD_CK_P,    --clock_positive
--         SD_CK_N  => SD_CK_N,    --clock_negative
--         SD_CKE   => SD_CKE,     --clock_enable
--   
--         SD_BA    => SD_BA,      --bank_address
--         SD_A     => SD_A,       --address(row or col)
--         SD_CS    => SD_CS,      --chip_select
--         SD_RAS   => SD_RAS,     --row_address_strobe
--         SD_CAS   => SD_CAS,     --column_address_strobe
--         SD_WE    => SD_WE,      --write_enable
--
--         SD_DQ    => SD_DQ,      --data
--         SD_UDM   => SD_UDM,     --upper_byte_enable
--         SD_UDQS  => SD_UDQS,    --upper_data_strobe
--         SD_LDM   => SD_LDM,     --low_byte_enable
--         SD_LDQS  => SD_LDQS);   --low_data_strobe
   
   
	u1_ddr_ctrl_dcm: ddr_ctrl_dcm
	port map(
		CLKin_in => CLK_133MHZ,
		RST_in => reset,
		CLKin_IBUFG_out => OPEN,
		CLK0_out => clk0,
		CLK90_out => clk90,
		CLK180_out => clk180,
		LOCKED_out => dcm_lock);

	u2_ddr_ctrl : ddr_ctrl
	port map (
		clk_int							=> clk0,
		clk90_int						=> clk90,
		dcm_lock						=> dcm_lock,
		reset_in_n						=> reset_n,
		cntrl0_ddr2_ras_n				=> SD_RAS,
		cntrl0_ddr2_cas_n				=> SD_CAS,
		cntrl0_ddr2_we_n				=> SD_WE,
		cntrl0_ddr2_cs_n				=> SD_CS,
		cntrl0_ddr2_cke					=> SD_CKE,
		cntrl0_ddr2_odt					=> SD_ODT,
		cntrl0_ddr2_dm					=> ddr2_dm_fpga,
		cntrl0_ddr2_dq					=> SD_DQ,
		cntrl0_ddr2_dqs					=> ddr2_dqs_fpga,
		cntrl0_ddr2_dqs_n				=> ddr2_dqs_n_fpga,
		cntrl0_ddr2_ck					=> ddr2_ck_fpga,
		cntrl0_ddr2_ck_n				=> ddr2_ck_n_fpga,
		cntrl0_ddr2_ba					=> SD_BA,
		cntrl0_ddr2_a					=> SD_A,
		cntrl0_burst_done				=> burst_done,
		cntrl0_init_done				=> init_done,
		cntrl0_ar_done					=> ar_done,
		cntrl0_user_data_valid			=> user_data_valid,
		cntrl0_auto_ref_req				=> auto_ref_req,
		cntrl0_user_cmd_ack				=> user_cmd_ack,
		cntrl0_user_command_register	=> user_command_register,
		cntrl0_clk_tb					=> clk_tb,
		cntrl0_clk90_tb					=> clk90_tb,
		cntrl0_sys_rst_tb				=> sys_rst_tb,
		cntrl0_sys_rst90_tb				=> sys_rst90_tb,
		cntrl0_sys_rst180_tb			=> sys_rst180_tb,
		cntrl0_user_output_data			=> user_output_data,
		cntrl0_user_input_data			=> user_input_data,
		cntrl0_user_input_address		=> user_input_address,
		cntrl0_user_data_mask			=> user_data_mask,
		cntrl0_rst_dqs_div_in			=> SD_LOOP_IN,
		cntrl0_rst_dqs_div_out			=> SD_LOOP_OUT);
		
	u3_ddr_ctrl_fsm : ddr_ctrl_fsm
	port map(
		clk0        	=> clk_tb,
		clk90      		=> clk90_tb,
		dcm_lock		=> dcm_lock,
		rst0			=> sys_rst_tb,
		rst90			=> sys_rst90_tb,
		rst180			=> sys_rst180_tb,
		dram_ar_done	=> ar_done,
		dram_ar_req		=> auto_ref_req,
		dram_cmd_ack	=> user_cmd_ack,
		dram_init_done	=> init_done,
		dram_data_valid	=> user_data_valid,
		err				=> err,
		no_ddr_start	=> no_ddr_start,
		no_ddr_stop		=> no_ddr_stop,
		active			=> active,
		byte_we			=> byte_we,
		dram_addr		=> user_input_address,
		dram_burst_done	=> burst_done,
		dram_cmd_reg	=> user_command_register,
		dram_data_mask	=> user_data_mask,
		dram_data_r		=> user_output_data,
		dram_data_w		=> user_input_data,
		leds			=> leds_fsm,
		pause			=> pause);

--   Flash control (only lower 16-bit data lines connected)
--   flash_ctrl: process(reset, clk_reg, flash_active, write_enable, 
--                       flash_cnt, pause_ddr)
--   begin
--      if reset = '1' then
--         flash_cnt <= "00";
--         flash_we <= '1';
--      elsif rising_edge(clk_reg) then
--         if flash_active = '0' then
--            flash_cnt <= "00";
--            flash_we <= '1';
--         else
--            if write_enable = '1' and flash_cnt(1) = '0' then
--               flash_we <= '0';
--            else
--               flash_we <= '1';
--            end if;
--            if flash_cnt /= "11" then
--               flash_cnt <= flash_cnt + 1;
--            end if;
--         end if;
--      end if;  --rising_edge(clk_reg)
--      if pause_ddr = '1' or (flash_active = '1' and flash_cnt /= "11") then
--         pause <= '1';
--      else
--         pause <= '0';
--      end if;
--   end process; --flash_ctrl

--   SF_CE0  <= not flash_active;
--   SF_OE   <= write_enable or not flash_active;
--   SF_WE   <= flash_we;
--   SF_BYTE <= '1';  --16-bit access
--   SF_A    <= address(25 downto 2) & '0' when flash_active = '1' else
--              "0000000000000000000000000";
--   SF_D    <= data_write(15 downto 1) when 
--              flash_active = '1' and write_enable = '1'
--              else "ZZZZZZZZZZZZZZZ";
--   SPI_MISO <= data_write(0) when 
--              flash_active = '1' and write_enable = '1'
--              else 'Z';
--   data_read(31 downto 16) <= data_r_ddr(31 downto 16);
--   data_read(15 downto 0) <= data_r_ddr(15 downto 0) when flash_active = '0' 
--                             else SF_D & SPI_MISO;
         
end; --architecture logic

