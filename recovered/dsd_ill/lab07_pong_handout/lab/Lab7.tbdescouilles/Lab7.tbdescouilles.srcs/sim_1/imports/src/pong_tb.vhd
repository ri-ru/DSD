----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 08.12.2024 10:22:25
-- Design Name: 
-- Module Name: pong_tb - Behavioral
-- Project Name: 
-- Target Devices: 
-- Tool Versions: 
-- Description: 
-- 
-- Dependencies: 
-- 
-- Revision:
-- Revision 0.01 - File Created
-- Additional Comments:
-- 
----------------------------------------------------------------------------------

library IEEE;
library std;
use std.env.all;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
library work;
use work.dsd_prj_pkg.all;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity pong_tb is
--  Port ( );
end pong_tb;

architecture tb of pong_tb is

    constant CLK_HIGH   : time := 4 ns;
    constant CLK_LOW    : time := 4 ns;
    constant CLK_PERIOD : time := CLK_LOW + CLK_HIGH;
    constant CLK_STIM   : time := 1 ns;
    constant CLK_PER  : time := CLK_LOW + CLK_HIGH;

component pong_fsm is 
    port (
        CLKxCI : in std_logic;
        RSTxRI : in std_logic;
    
        LeftxSI : in std_logic;
        RightxSI : in std_logic;
    
        BallXxDO  : out signed(COORD_BW - 1 downto 0);
        BallYxDO  : out signed(COORD_BW - 1 downto 0);
        PlateXxDO : out signed(COORD_BW - 1 downto 0)
        

        );
    end component pong_fsm;
    
    signal CLKxC : std_logic;
    signal RSTxR : std_logic;
    
    signal LeftxS : std_logic;
    signal RightxS : std_logic;
    
    signal BallXxD : signed(COORD_BW - 1 downto 0) := (others => '0');
    signal BallYxD : signed(COORD_BW - 1 downto 0)  := (others => '0');
    signal PlateXxD : signed(COORD_BW - 1 downto 0)  := (others => '0');
    
    
begin
    
    dut: pong_fsm
        port map ( 
            CLKxCI => CLKxC,
            RSTxRI => RSTxR,
            LeftxSI => LeftxS,
            RightxSI => RightxS,
            BallXxDO => BallXxD,
            BallYxDO => BallYxD,
            PlateXxDO => PlateXxD
            );
            
    p_clock: process is
    begin
        CLKxC <= '0';
        wait for CLK_LOW;
        CLKxC <= '1';
        wait for CLK_HIGH;
    end process p_clock;
    
     p_reset: process is
    begin
        RSTxR <= '1';
        wait until rising_edge(CLKxC);    -- Align to clock rising edge
        wait for (2*CLK_PER + CLK_STIM);  -- Align to CLK_STIM ns after rising edge
        RSTxR <= '0';
        wait;
    end process p_reset;

    p_stim: process is
    begin
    
        --Ball touch plate
        ----------------------------
        wait for 2*(2*CLK_PER + CLK_STIM);
        wait until CLKxC'event and CLKxC = '1';
        LeftxS <= '1';
        RightxS <= '1';
        wait for 0.25ms;
        
        RightxS <= '0';
        wait for 0.25ms;
        
        RightxS <= '1';
        LeftxS <= '0';
        wait for 0.25ms;
        stop(0);
    end process p_stim;



end tb;

    