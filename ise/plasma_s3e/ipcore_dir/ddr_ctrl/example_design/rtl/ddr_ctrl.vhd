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
-- Copyright 2005, 2006, 2007, 2008 Xilinx, Inc.
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
--  /   /        Filename	    : ddr_ctrl.vhd
-- /___/   /\    Date Last Modified : $Date: 2010/11/26 18:25:43 $
-- \   \  /  \   Date Created       : Mon May 2 2005
--  \___\/\___\
-- Device      : Spartan-3/3E/3A/3A-DSP
-- Design Name : DDR SDRAM
-- Purpose     : This module has the instantiations infrastructure_top and
--               main modules.
--*****************************************************************************

library IEEE;
use IEEE.STD_LOGIC_1164.all;
library UNISIM;
use UNISIM.VCOMPONENTS.all;


entity ddr_ctrl is
  port (
      cntrl0_ddr_dq                 : inout std_logic_vector(7 downto 0);
      cntrl0_ddr_a                  : out   std_logic_vector(12 downto 0);
      cntrl0_ddr_ba                 : out   std_logic_vector(1 downto 0);
      cntrl0_ddr_cke                : out   std_logic;
      cntrl0_ddr_cs_n               : out   std_logic;
      cntrl0_ddr_ras_n              : out   std_logic;
      cntrl0_ddr_cas_n              : out   std_logic;
      cntrl0_ddr_we_n               : out   std_logic;
      cntrl0_ddr_dm                 : out   std_logic_vector(0 downto 0);
      cntrl0_rst_dqs_div_in         : in    std_logic;
      cntrl0_rst_dqs_div_out        : out   std_logic;
      sys_clkb                      : in    std_logic;
      sys_clk                       : in    std_logic;
      reset_in_n                    : in    std_logic;
      cntrl0_led_error_output1      : out   std_logic;
      cntrl0_data_valid_out         : out   std_logic;
      cntrl0_init_done              : out   std_logic;
      cntrl0_ddr_dqs                : inout std_logic_vector(0 downto 0);
      cntrl0_ddr_ck                 : out   std_logic_vector(0 downto 0);
      cntrl0_ddr_ck_n               : out   std_logic_vector(0 downto 0)
    );
end ddr_ctrl;

architecture arc_mem_interface_top of ddr_ctrl is

  ATTRIBUTE X_CORE_INFO          : STRING;
  ATTRIBUTE CORE_GENERATION_INFO : STRING;

  ATTRIBUTE X_CORE_INFO of arc_mem_interface_top : ARCHITECTURE IS "mig_v3_61_ddr_sp3, Coregen 12.4";
  ATTRIBUTE CORE_GENERATION_INFO of arc_mem_interface_top : ARCHITECTURE IS "ddr_sp3,mig_v3_61,{component_name=ddr_sp3, data_width=8, memory_width=8, clk_width=1, bank_address=2, row_address=13, column_address=10, no_of_cs=1, cke_width=1, registered=0, data_mask=1, mask_enable=1, load_mode_register=0000000100001, ext_load_mode_register=0000000000000, language=VHDL, synthesis_tool=ISE, interface_type=DDR_SDRAM, no_of_controllers=1}";

  component ddr_ctrl_main_0
    port(
      ddr_dq                : inout std_logic_vector(7 downto 0);
      ddr_a                 : out   std_logic_vector(12 downto 0);
      ddr_ba                : out   std_logic_vector(1 downto 0);
      ddr_cke               : out   std_logic;
      ddr_cs_n              : out   std_logic;
      ddr_ras_n             : out   std_logic;
      ddr_cas_n             : out   std_logic;
      ddr_we_n              : out   std_logic;
      ddr_dm                : out   std_logic_vector(0 downto 0);
      rst_dqs_div_in        : in    std_logic;
      rst_dqs_div_out       : out   std_logic;
      led_error_output1     : out   std_logic;
      data_valid_out        : out   std_logic;
      init_done             : out   std_logic;
      ddr_dqs               : inout std_logic_vector(0 downto 0);
      ddr_ck                : out   std_logic_vector(0 downto 0);
      ddr_ck_n              : out   std_logic_vector(0 downto 0);
      wait_200us             : in std_logic;   
      delay_sel_val          : in std_logic_vector(4 downto 0);   
      clk_int                : in std_logic;   
      clk90_int              : in std_logic;   
      sys_rst_val            : in std_logic;   
      sys_rst90_val          : in std_logic;   
      sys_rst180_val         : in std_logic;   
      --Debug ports

      dbg_delay_sel          : out std_logic_vector(4 downto 0);
      dbg_rst_calib          : out std_logic;
      vio_out_dqs            : in  std_logic_vector(4 downto 0);
      vio_out_dqs_en         : in  std_logic;
      vio_out_rst_dqs_div    : in  std_logic_vector(4 downto 0);
      vio_out_rst_dqs_div_en : in  std_logic
    );
  end component;
  component ddr_ctrl_infrastructure_top
    port (
            sys_clk_in            : in    std_logic;
      sys_clkb              : in    std_logic;
      sys_clk               : in    std_logic;
      reset_in_n            : in    std_logic;
      wait_200us_rout        : out std_logic;
      delay_sel_val1_val     : out std_logic_vector(4 downto 0);
      sys_rst_val            : out std_logic;
      sys_rst90_val          : out std_logic;
      clk_int_val            : out std_logic;
      clk90_int_val          : out std_logic;
      sys_rst180_val         : out std_logic;
      dbg_phase_cnt          : out std_logic_vector(4 downto 0);
      dbg_cnt                : out std_logic_vector(5 downto 0);
      dbg_trans_onedtct      : out std_logic;
      dbg_trans_twodtct      : out std_logic;
      dbg_enb_trans_two_dtct : out std_logic
      );
  end component;




  signal sys_rst                : std_logic;
  signal wait_200us             : std_logic;
  signal sys_rst90              : std_logic;
  signal sys_rst180             : std_logic;
  signal clk_0                  : std_logic;
  signal clk90_0                : std_logic;
  signal delay_sel_val          : std_logic_vector(4 downto 0);
  -- debug signals
  signal dbg_phase_cnt          : std_logic_vector(4 downto 0);
  signal dbg_cnt                : std_logic_vector(5 downto 0);
  signal dbg_trans_onedtct      : std_logic;
  signal dbg_trans_twodtct      : std_logic;
  signal dbg_enb_trans_two_dtct : std_logic;
  signal dbg_delay_sel          : std_logic_vector(4 downto 0);
  signal dbg_rst_calib          : std_logic;
  -- chipscope signals
  signal dbg_data               : std_logic_vector(19 downto 0);
  signal dbg_trig               : std_logic_vector(3 downto 0);
  signal control0               : std_logic_vector(35 downto 0);
  signal control1               : std_logic_vector(35 downto 0);
  signal vio_out_dqs            : std_logic_vector(4 downto 0);
  signal vio_out_dqs_en         : std_logic;
  signal vio_out_rst_dqs_div    : std_logic_vector(4 downto 0);
  signal vio_out_rst_dqs_div_en : std_logic;
  signal vio_out                : std_logic_vector(11 downto 0);

  signal sys_clk_in : std_logic;

begin

  sys_clk_in <= '0';

  main_00 : ddr_ctrl_main_0
    port map (
      ddr_dq                => cntrl0_ddr_dq,
      ddr_a                 => cntrl0_ddr_a,
      ddr_ba                => cntrl0_ddr_ba,
      ddr_cke               => cntrl0_ddr_cke,
      ddr_cs_n              => cntrl0_ddr_cs_n,
      ddr_ras_n             => cntrl0_ddr_ras_n,
      ddr_cas_n             => cntrl0_ddr_cas_n,
      ddr_we_n              => cntrl0_ddr_we_n,
      ddr_dm                => cntrl0_ddr_dm,
      rst_dqs_div_in        => cntrl0_rst_dqs_div_in,
      rst_dqs_div_out       => cntrl0_rst_dqs_div_out,
      led_error_output1     => cntrl0_led_error_output1,
      data_valid_out        => cntrl0_data_valid_out,
      init_done             => cntrl0_init_done,
      ddr_dqs               => cntrl0_ddr_dqs,
      ddr_ck                => cntrl0_ddr_ck,
      ddr_ck_n              => cntrl0_ddr_ck_n,
      wait_200us             => wait_200us,
      delay_sel_val          => delay_sel_val,
      clk_int                => clk_0,
      clk90_int              => clk90_0,
      sys_rst_val            => sys_rst,
      sys_rst90_val          => sys_rst90,
      sys_rst180_val         => sys_rst180,

    --Debug signals

      dbg_delay_sel      => dbg_delay_sel,
      dbg_rst_calib       => dbg_rst_calib,
      vio_out_dqs            => vio_out_dqs,
      vio_out_dqs_en         => vio_out_dqs_en,
      vio_out_rst_dqs_div    => vio_out_rst_dqs_div,
      vio_out_rst_dqs_div_en => vio_out_rst_dqs_div_en
      );
  infrastructure_top0 : ddr_ctrl_infrastructure_top
    port map (
            sys_clk_in            => sys_clk_in,
      sys_clkb              => sys_clkb,
      sys_clk               => sys_clk,
      reset_in_n            => reset_in_n,
      wait_200us_rout        => wait_200us,
      delay_sel_val1_val     => delay_sel_val,
      clk_int_val            => clk_0,
      clk90_int_val          => clk90_0,
      sys_rst_val            => sys_rst,
      sys_rst90_val          => sys_rst90,
      sys_rst180_val         => sys_rst180,
      dbg_phase_cnt          => dbg_phase_cnt,
      dbg_cnt                => dbg_cnt,
      dbg_trans_onedtct      => dbg_trans_onedtct,
      dbg_trans_twodtct      => dbg_trans_twodtct,
      dbg_enb_trans_two_dtct => dbg_enb_trans_two_dtct
      );



end arc_mem_interface_top;
