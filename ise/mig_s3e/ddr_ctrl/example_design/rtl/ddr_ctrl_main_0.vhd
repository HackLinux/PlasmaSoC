--*****************************************************************************
-- DISCLAIMER OF LIABILITY
--
-- This file contains proprietary and confidential information of
-- Xilinx, Inc. ("Xilinx"), that is distributed under a license
-- from Xilinx, and may be used, copied and/or disclosed only
-- pursuant to the terms of a valid license agreement with Xilinx.
--
-- XILINX IS PROVIDING THIS DESIGN, CODE, OR INFORMATION
-- ("MATERIALS") "AS IS" WITHOUT WARRANTY OF ANY KIND, EITHER
-- EXPRESSED, IMPLIED, OR STATUTORY, INCLUDING WITHOUT
-- LIMITATION, ANY WARRANTY WITH RESPECT TO NONINFRINGEMENT,
-- MERCHANTABILITY OR FITNESS FOR ANY PARTICULAR PURPOSE. Xilinx
-- does not warrant that functions included in the Materials will
-- meet the requirements of Licensee, or that the operation of the
-- Materials will be uninterrupted or error-free, or that defects
-- in the Materials will be corrected. Furthermore, Xilinx does
-- not warrant or make any representations regarding use, or the
-- results of the use, of the Materials in terms of correctness,
-- accuracy, reliability or otherwise.
--
-- Xilinx products are not designed or intended to be fail-safe,
-- or for use in any application requiring fail-safe performance,
-- such as life-support or safety devices or systems, Class III
-- medical devices, nuclear facilities, applications related to
-- the deployment of airbags, or any other applications that could
-- lead to death, personal injury or severe property or
-- environmental damage (individually and collectively, "critical
-- applications"). Customer assumes the sole risk and liability
-- of any use of Xilinx products in critical applications,
-- subject only to applicable laws and regulations governing
-- limitations on product liability.
--
-- Copyright 2005, 2006, 2007 Xilinx, Inc.
-- All rights reserved.
--
-- This disclaimer and copyright notice must be retained as part
-- of this file at all times.
--*****************************************************************************
--   ____  ____
--  /   /\/   /
-- /___/  \  /   Vendor		    : Xilinx
-- \   \   \/    Version	    : 3.6.1
--  \   \        Application	    : MIG
--  /   /        Filename	    : ddr_ctrl_main_0.vhd
-- /___/   /\    Date Last Modified : $Date: 2010/11/26 18:25:43 $	
-- \   \  /  \   Date Created       : Mon May 2 2005
--  \___\/\___\
-- Device      : Spartan-3/3E/3A/3A-DSP
-- Design Name : DDR SDRAM
-- Purpose     : This modules has the instantiations top and test_bench modules. 
--*****************************************************************************

library IEEE;
use IEEE.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use work.ddr_ctrl_parameters_0.all;

library UNISIM;
use UNISIM.VCOMPONENTS.all;

entity ddr_ctrl_main_0 is
  port(
    rst_dqs_div_in    : in    std_logic;
    rst_dqs_div_out   : out   std_logic;
    delay_sel_val     : in    std_logic_vector(4 downto 0);
    clk_int           : in    std_logic;
    wait_200us        : in    std_logic;
    clk90_int         : in    std_logic;
    sys_rst_val       : in    std_logic;
    sys_rst90_val     : in    std_logic;
    sys_rst180_val    : in    std_logic;
    ddr_cke           : out   std_logic;
    ddr_cs_n          : out   std_logic;
    ddr_cas_n         : out   std_logic;
    ddr_ras_n         : out   std_logic;
    ddr_we_n          : out   std_logic;
    ddr_a             : out   std_logic_vector((ROW_ADDRESS - 1) downto 0);
    ddr_ba            : out   std_logic_vector((BANK_ADDRESS -1) downto 0);
    ddr_dq            : inout std_logic_vector((DATA_WIDTH -1) downto 0);
    ddr_dm            : out std_logic_vector((DATA_MASK_WIDTH-1) downto 0);
    ddr_dqs           : inout std_logic_vector((DATA_STROBE_WIDTH -1) downto 0);
 
    ddr_ck            : out   std_logic_vector((CLK_WIDTH-1) downto 0);
    ddr_ck_n          : out   std_logic_vector((CLK_WIDTH-1) downto 0);
    led_error_output1 : out   std_logic;
    init_done         : out   std_logic;
    data_valid_out    : out   std_logic;
    -- debug signals
    dbg_delay_sel     : out std_logic_vector(4 downto 0);
    dbg_rst_calib     : out std_logic;
    vio_out_dqs            : in  std_logic_vector(4 downto 0);
    vio_out_dqs_en         : in  std_logic;
    vio_out_rst_dqs_div    : in  std_logic_vector(4 downto 0);
    vio_out_rst_dqs_div_en : in  std_logic
    );
end ddr_ctrl_main_0;

architecture arc of ddr_ctrl_main_0 is

---- Component declarations             -----
  
  component ddr_ctrl_test_bench_0
    port (
      clk90            : in  std_logic;
      fpga_clk         : in  std_logic;
      fpga_rst90       : in  std_logic;
      fpga_rst180      : in  std_logic;
      burst_done       : out std_logic;
      init_done        : in  std_logic;
      auto_ref_req     : in  std_logic;
      ar_done          : in  std_logic;
      u_ack            : in  std_logic;
      u_data_val       : in  std_logic;
      u_data_o         : in  std_logic_vector(((DATA_WIDTH*2) -1) downto 0);
      u_addr           : out std_logic_vector(((ROW_ADDRESS + COLUMN_ADDRESS
                                                + BANK_ADDRESS)-1) downto 0);
      u_cmd            : out std_logic_vector(2 downto 0);
      u_data_i         : out std_logic_vector(((DATA_WIDTH*2) -1) downto 0);
      u_data_m         : out std_logic_vector(((DATA_MASK_WIDTH*2) -1) downto 0);
      led_error_output : out std_logic;
      data_valid_out   : out std_logic
      );
  end component;

  component ddr_ctrl_top_0
    port (
      auto_ref_req          : out   std_logic;
      wait_200us            : in    std_logic;
      rst_dqs_div_in        : in    std_logic;
      rst_dqs_div_out       : out   std_logic;
      user_input_data       : in    std_logic_vector(((DATA_WIDTH*2)-1) downto 0);
      user_output_data      : out   std_logic_vector(((DATA_WIDTH*2) -1)
                                              downto 0) := (others => 'Z');
      user_data_valid       : out   std_logic;
      user_data_mask        : in std_logic_vector(((DATA_MASK_WIDTH*2) -1) downto 0);
      user_input_address    : in    std_logic_vector(((ROW_ADDRESS +
                                                       COLUMN_ADDRESS + BANK_ADDRESS)-1) downto 0);
      user_command_register : in    std_logic_vector(2 downto 0);
      user_cmd_ack          : out   std_logic;
      burst_done            : in    std_logic;
      init_val              : out   std_logic;
      ar_done               : out   std_logic;

      ddr_ck                : out   std_logic_vector((CLK_WIDTH-1) downto 0);
      ddr_ck_n              : out   std_logic_vector((CLK_WIDTH-1) downto 0);
      ddr_dqs               : inout std_logic_vector((DATA_STROBE_WIDTH -1) downto 0);
      ddr_dm                : out std_logic_vector((DATA_MASK_WIDTH-1) downto 0);
      ddr_dq                : inout std_logic_vector((DATA_WIDTH -1) downto 0);
      ddr_cke               : out   std_logic;
      ddr_cs_n              : out   std_logic;
      ddr_ras_n             : out   std_logic;
      ddr_cas_n             : out   std_logic;
      ddr_we_n              : out   std_logic;
      ddr_ba                : out   std_logic_vector((BANK_ADDRESS -1) downto 0);
      ddr_a                 : out   std_logic_vector((ROW_ADDRESS -1) downto 0);
      clk_int               : in    std_logic;
      clk90_int             : in    std_logic;
      delay_sel_val         : in    std_logic_vector(4 downto 0);
      sys_rst_val           : in    std_logic;
      sys_rst90_val         : in    std_logic;
      sys_rst180_val        : in    std_logic;
      -- debug signals
      dbg_delay_sel         : out std_logic_vector(4 downto 0);
      dbg_rst_calib         : out std_logic;
      vio_out_dqs            : in  std_logic_vector(4 downto 0);
      vio_out_dqs_en         : in  std_logic;
      vio_out_rst_dqs_div    : in  std_logic_vector(4 downto 0);
      vio_out_rst_dqs_div_en : in  std_logic
      );
  end component;
  
  
  signal user_output_data : std_logic_vector(((DATA_WIDTH*2)-1) downto 0);
  signal u1_address       : std_logic_vector(((ROW_ADDRESS + COLUMN_ADDRESS
                                               + BANK_ADDRESS)-1) downto 0);
  signal user_data_val1   : std_logic;
  signal user_cmd1        : std_logic_vector(2 downto 0);
  signal auto_ref_req     : std_logic;
  signal user_ack1        : std_logic;
  signal u1_data_i        : std_logic_vector(((DATA_WIDTH*2)-1) downto 0);
  signal u1_data_m        : std_logic_vector(((DATA_MASK_WIDTH*2)-1) downto 0);
  signal burst_done_val1  : std_logic;
  signal ar_done_val1     : std_logic;
  signal init_done_int    : std_logic;

begin
  
---- Component instantiations           ----
  
  init_done <= init_done_int;
  top0 : ddr_ctrl_top_0
    port map (
      auto_ref_req          => auto_ref_req,
      wait_200us            => wait_200us,
      rst_dqs_div_in        => rst_dqs_div_in,
      rst_dqs_div_out       => rst_dqs_div_out,
      user_input_data       => u1_data_i,
      user_data_mask        => u1_data_m,
      user_output_data      => user_output_data,
      user_data_valid       => user_data_val1,
      user_input_address    => u1_address(((ROW_ADDRESS +
                                            COLUMN_ADDRESS + BANK_ADDRESS)-1) downto 0),
      user_command_register => user_cmd1,
      user_cmd_ack          => user_ack1,
      burst_done            => burst_done_val1,
      init_val              => init_done_int,
      ar_done               => ar_done_val1,
      ddr_dqs               => ddr_dqs,
      ddr_dq                => ddr_dq,
      ddr_cke               => ddr_cke,
      ddr_cs_n              => ddr_cs_n,
      ddr_ras_n             => ddr_ras_n,
      ddr_cas_n             => ddr_cas_n,
      ddr_we_n              => ddr_we_n,
      ddr_dm                => ddr_dm,

      ddr_ck                => ddr_ck,
      ddr_ck_n	            => ddr_ck_n,
      ddr_ba                => ddr_ba,
      ddr_a                 => ddr_a,
      clk90_int             => clk90_int,
      clk_int               => clk_int,
      delay_sel_val         => delay_sel_val,
      sys_rst_val           => sys_rst_val,
      sys_rst90_val         => sys_rst90_val,
      sys_rst180_val        => sys_rst180_val,
      dbg_delay_sel         => dbg_delay_sel,
      dbg_rst_calib         => dbg_rst_calib,
--debug signals
      vio_out_dqs            => vio_out_dqs,
      vio_out_dqs_en         => vio_out_dqs_en,
      vio_out_rst_dqs_div    => vio_out_rst_dqs_div,
      vio_out_rst_dqs_div_en => vio_out_rst_dqs_div_en
      );         

  test_bench0 : ddr_ctrl_test_bench_0
    port map (
      auto_ref_req     => auto_ref_req,
      fpga_clk         => clk_int,
      fpga_rst90       => sys_rst90_val,
      fpga_rst180      => sys_rst180_val,
      clk90            => clk90_int,
      burst_done       => burst_done_val1,
      init_done        => init_done_int,
      ar_done          => ar_done_val1,
      u_ack            => user_ack1,
      u_data_val       => user_data_val1,
      u_data_o         => user_output_data,
      u_addr           => u1_address,
      u_cmd            => user_cmd1,
      u_data_i         => u1_data_i,
      u_data_m         => u1_data_m,
      led_error_output => led_error_output1,
      data_valid_out   => data_valid_out
      );
  
end arc;
