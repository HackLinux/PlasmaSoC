
-- VHDL Instantiation Created from source file dcm_ddr_s3e.vhd -- 05:07:08 05/28/2011
--
-- Notes: 
-- 1) This instantiation template has been automatically generated using types
-- std_logic and std_logic_vector for the ports of the instantiated module
-- 2) To use this template to instantiate this entity, cut-and-paste and then edit

	COMPONENT dcm_ddr_s3e
	PORT(
		U1_CLKIN_IN : IN std_logic;
		U1_RST_IN : IN std_logic;          
		U1_CLKIN_IBUFG_OUT : OUT std_logic;
		U1_CLK2X_OUT : OUT std_logic;
		U2_CLK0_OUT : OUT std_logic;
		U2_CLK90_OUT : OUT std_logic;
		U2_CLK180_OUT : OUT std_logic;
		U2_LOCKED_OUT : OUT std_logic
		);
	END COMPONENT;

	Inst_dcm_ddr_s3e: dcm_ddr_s3e PORT MAP(
		U1_CLKIN_IN => ,
		U1_RST_IN => ,
		U1_CLKIN_IBUFG_OUT => ,
		U1_CLK2X_OUT => ,
		U2_CLK0_OUT => ,
		U2_CLK90_OUT => ,
		U2_CLK180_OUT => ,
		U2_LOCKED_OUT => 
	);


