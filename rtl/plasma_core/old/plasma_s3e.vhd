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

entity plasma_s3e is
   port(CLK_50MHZ  : in std_logic;
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
        SD_UDQS    : inout std_logic;   --upper_data_strobe
        SD_LDM     : out std_logic;     --low_byte_enable
        SD_LDQS    : inout std_logic;   --low_data_strobe

        E_MDC      : out std_logic;     --Ethernet PHY
        E_MDIO     : inout std_logic;   --management data in/out
        E_RX_CLK   : in std_logic;      --receive clock
        E_RX_DV    : in std_logic;      --data valid
        E_RXD      : in std_logic_vector(3 downto 0);
        E_TX_CLK   : in std_logic;      --transmit clock
        E_TX_EN    : out std_logic;     --data valid
        E_TXD      : out std_logic_vector(3 downto 0);

        SF_CE0     : out std_logic;     --NOR flash
        SF_OE      : out std_logic;
        SF_WE      : out std_logic;
        SF_BYTE    : out std_logic;
        SF_STS     : in std_logic;      --status
        SF_A       : out std_logic_vector(24 downto 0);
        SF_D       : inout std_logic_vector(15 downto 1);
        SPI_MISO   : inout std_logic;

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
end; --entity plasma_if


architecture logic of plasma_s3e is

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
   signal gpio0_out    : std_logic_vector(31 downto 0);
   signal gpio0_in     : std_logic_vector(31 downto 0);

	signal clk100_0			: std_logic;
	signal clk100_90			: std_logic;
	signal clk100_180			: std_logic;
	signal clk100_lock		: std_logic;
	signal clk100_lock_n		: std_logic;
	signal cntrl0_ddr_ck		: std_logic_vector(0 downto 0);
	signal cntrl0_ddr_ck_n	: std_logic_vector(0 downto 0);
	
	signal dram_burst_done	: std_logic;
	signal dram_cmd_reg		: std_logic_vector(2 downto 0);
	signal dram_data_mask	: std_logic_vector(3 downto 0);
	
	signal rst_dqs_div		: std_logic;
	signal rst_int				: std_logic;
	signal dout					: std_logic;
	
--	signal data_valid			: std_logic;
--	signal dram_addr			: std_logic_vector(24 downto 0);
--	signal dram_ar_done		: std_logic;
--	signal dram_ar_req		: std_logic;
	signal dram_cmd_ack		: std_logic;
--	signal dram_data_w		: std_logic_vector(31 downto 0);
--	signal dram_init_val		: std_logic;
--	signal output_data		: std_logic_vector(31 downto 0);
   
begin  --architecture
   --Divide 50 MHz clock by two
   clk_div: process(reset, CLK_50MHZ, clk_reg)
   begin
      if reset = '1' then
         clk_reg <= '0';
      elsif rising_edge(CLK_50MHZ) then
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
   gpio0_in(12 downto 10) <= SF_STS & PS2_CLK & PS2_DATA;
   gpio0_in(9 downto 0) <= ROT_A & ROT_B & BTN_EAST & BTN_NORTH & 
                           BTN_SOUTH & BTN_WEST & SW;
   ddr_active <= '1' when address(31 downto 28) = "0001" else '0';
   flash_active <= '1' when address(31 downto 28) = "0011" else '0';
   write_enable <= '1' when byte_we /= "0000" else '0';

   u1_plama: plasma 
      generic map (memory_type => "XILINX_16X",
                   log_file    => "UNUSED",
                   ethernet    => '1',
                   use_cache   => '1')
      --generic map (memory_type => "DUAL_PORT_",
      --             log_file    => "output2.txt",
      --             ethernet    => '1')
      PORT MAP (
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

	ddr_ck <= cntrl0_ddr_ck(0);
	ddr_ck_n <= cntrl0_ddr_ck_n(0);
	clk100_lock_n <= not(clk100_lock);
	dout <= not(reset);
	rst_int <= reset or clk100_lock_n;
   
	u1_ddr_ctrl_dcm: ddr_ctrl_dcm
		port map(
			U1_CLKin_in => clk50,
			U1_RST_in => reset,
			U1_CLKin_IBUFG_out => OPEN,
			U1_CLK2X_out => OPEN,
			U2_CLK0_out => clk100_0,
			U2_CLK90_out => clk100_90,
			U2_CLK180_out => clk100_180,
			U2_LOCKED_out => clk100_lock);
			
	u2_ddr_ctrl : ddr_ctrl
		port map(
			cntrl0_ddr_dq                 => SD_DQ,
			cntrl0_ddr_a                  => SD_A,
			cntrl0_ddr_ba                 => SD_BA,
			cntrl0_ddr_cke                => SD_CKE,
			cntrl0_ddr_cs_n               => SD_CS,
			cntrl0_ddr_ras_n              => SD_RAS,
			cntrl0_ddr_cas_n              => SD_CAS,
			cntrl0_ddr_we_n               => SD_WE,
			cntrl0_ddr_dm                 => SD_UDM & SD_LDM,
			cntrl0_rst_dqs_div_in         => rst_dqs_div,
			cntrl0_rst_dqs_div_out        => rst_dqs_div,
			reset_in_n                    => dout,
			cntrl0_burst_done             => dram_burst_done,
			cntrl0_init_val               => OPEN, -- dram_init_val,
			cntrl0_ar_done                => OPEN, -- dram_ar_done,
			cntrl0_user_data_valid        => OPEN, -- data_valid,
			cntrl0_auto_ref_req           => OPEN, -- dram_ar_req,
			cntrl0_user_cmd_ack           => dram_cmd_ack,
			cntrl0_user_command_register  => dram_cmd_reg,
			cntrl0_clk_tb                 => OPEN,
			cntrl0_clk90_tb               => OPEN,
			cntrl0_sys_rst_tb             => OPEN,
			cntrl0_sys_rst90_tb           => OPEN,
			cntrl0_sys_rst180_tb          => OPEN,
			cntrl0_user_data_mask         => dram_data_mask,
			cntrl0_user_output_data       => data_r_ddr,
			cntrl0_user_input_data        => data_write,
			cntrl0_user_input_address     => address(26 downto 2),
			clk_int                       => clk100_0,
			clk90_int                     => clk100_90,
			dcm_lock                      => clk100_lock,
			cntrl0_ddr_dqs                => SD_UDQS & SD_LDQS,
			cntrl0_ddr_ck                 => SD_CK_P,
			cntrl0_ddr_ck_n               => SD_CK_N);
			
	pause_ddr <= dram_cmd_ack;

   --Flash control (only lower 16-bit data lines connected)
   flash_ctrl: process(reset, clk_reg, flash_active, write_enable, 
                       flash_cnt, pause_ddr)
   begin
      if reset = '1' then
         flash_cnt <= "00";
         flash_we <= '1';
      elsif rising_edge(clk_reg) then
         if flash_active = '0' then
            flash_cnt <= "00";
            flash_we <= '1';
         else
            if write_enable = '1' and flash_cnt(1) = '0' then
               flash_we <= '0';
            else
               flash_we <= '1';
            end if;
            if flash_cnt /= "11" then
               flash_cnt <= flash_cnt + 1;
            end if;
         end if;
      end if;  --rising_edge(clk_reg)
      if pause_ddr = '1' or (flash_active = '1' and flash_cnt /= "11") then
         pause <= '1';
      else
         pause <= '0';
      end if;
   end process; --flash_ctrl

   SF_CE0  <= not flash_active;
   SF_OE   <= write_enable or not flash_active;
   SF_WE   <= flash_we;
   SF_BYTE <= '1';  --16-bit access
   SF_A    <= address(25 downto 2) & '0' when flash_active = '1' else
              "0000000000000000000000000";
   SF_D    <= data_write(15 downto 1) when 
              flash_active = '1' and write_enable = '1'
              else "ZZZZZZZZZZZZZZZ";
   SPI_MISO <= data_write(0) when 
              flash_active = '1' and write_enable = '1'
              else 'Z';
   data_read(31 downto 16) <= data_r_ddr(31 downto 16);
   data_read(15 downto 0) <= data_r_ddr(15 downto 0) when flash_active = '0' 
                             else SF_D & SPI_MISO;
         
end; --architecture logic

