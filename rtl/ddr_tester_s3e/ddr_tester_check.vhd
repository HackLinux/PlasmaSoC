library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;
use ieee.numeric_std.all;

entity ddr_tester_check is
   port( 
      clk100_90   : in     std_logic;
      data_valid  : in     std_logic;
      output_data : in     std_logic_vector (31 downto 0);
      read_done   : in     std_logic;
      rst_int     : in     std_logic;
      strt_pb     : in     std_logic;
      err         : out    std_logic;
      error_trig  : out    std_logic);
end ddr_tester_check;

architecture Behavioral of ddr_tester_check is

   signal data_count		: std_logic_vector (15 downto 0);	-- internal data counter
   signal expected		: std_logic_vector (31 downto 0);	-- data expected
   signal expected_old	: std_logic_vector (31 downto 0);	-- data expected, old value
   signal received		: std_logic_vector (31 downto 0);	-- data received
   signal received_old	: std_logic_vector (31 downto 0);	-- data received, old value
   signal check_ena		: std_logic;								-- checker enable
   signal check_ena_old	: std_logic;								-- checker enable, old value
   signal error_count	: std_logic_vector (23 downto 0);	-- error counter

begin

   datacount_proc : process (clk100_90, rst_int)
   begin
      if (rst_int = '1') then
         data_count <= (others => '0') ;
      elsif (clk100_90'event and clk100_90 = '1') then
         if strt_pb = '1'  then
            data_count <= (others => '0') ;
         elsif data_valid = '1'  then
            data_count <= data_count + "10";
         end if;
      end if;
   end process datacount_proc;

   expecteddata_proc : process (clk100_90, rst_int)
   begin
      if (rst_int = '1') then
         expected <= (others => '0');
         expected_old <= (others => '0');
         received <= (others => '0');
         received_old <= (others => '0');
         check_ena <= '0';
         check_ena_old <= '0';

      elsif (clk100_90'event and clk100_90 = '1') then
         expected <= expected_old;
         expected_old <= data_count & (data_count + '1');
         received <= received_old;
         received_old <= output_data ;
         check_ena <= check_ena_old;
         check_ena_old <= data_valid;
      end if;
   end process expecteddata_proc;

   compare_proc : process (clk100_90, rst_int)
   begin
      if (rst_int = '1') then
         error_count <= (others => '0');
         error_trig <= '0' ;

      elsif (clk100_90'event and clk100_90 = '1') then
         if strt_pb = '1' then
            error_count <= (others => '0');
            error_trig <= '0' ;
         elsif check_ena = '1' then
            if expected /= received then
               error_count <= error_count + '1';
               error_trig <= '1' ;
            end if;
         end if;
      end if;
   end process compare_proc;

   showerror_proc : process (clk100_90, rst_int)
   begin
      if (rst_int = '1') then
         err <= '0' ;

      elsif (clk100_90'event and clk100_90 = '1') then
         if strt_pb = '1'  then
            err <= '0' ;
         elsif read_done = '1'  then
            if error_count /= "000000000000000000000000" then
               err <= '1' ;
            else
               err <= '0' ;
            end if;
         end if;
      end if;
   end process showerror_proc;

end Behavioral;
