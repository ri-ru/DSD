--=============================================================================
-- @file pong_fsm.vhdl
--=============================================================================
-- Standard library
library ieee;
-- Standard packages
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.std_logic_signed.all;
-- Packages
library work;
use work.dsd_prj_pkg.all;

--=============================================================================
--
-- pong_fsm
--
-- @brief This file specifies a basic circuit for the pong game. Note that coordinates are counted
-- from the upper left corner of the screen.
--
--=============================================================================

--=============================================================================
-- ENTITY DECLARATION FOR PONG_FSM
--=============================================================================
entity pong_fsm is
  port (
    CLKxCI : in std_logic;
    RSTxRI : in std_logic;

    -- Controls from push buttons
    LeftxSI  : in std_logic;
    RightxSI : in std_logic;

    -- Coordinate from VGA
    VgaXxDI : in unsigned(COORD_BW - 1 downto 0);
    VgaYxDI : in unsigned(COORD_BW - 1 downto 0);

    -- Signals from video interface to synchronize (HIGH for 1 CC, when vertical sync starts)
    VSEdgexSI : in std_logic;

    -- Ball and plate coordinates
    BallXxDO  : out unsigned(COORD_BW - 1 downto 0);
    BallYxDO  : out unsigned(COORD_BW - 1 downto 0);
    PlateXxDO : out unsigned(COORD_BW - 1 downto 0)
  );
end pong_fsm;

--=============================================================================
-- ARCHITECTURE DECLARATION
--=============================================================================
architecture rtl of pong_fsm is

-- TODO: Implement your code here
type game_state is (Idle, Playing);

    signal XPlayerxDP, XPlayerxDN, XBallxDP, XBallxDN, YBallxDP, YBallxDN : unsigned(COORD_BW-1 downto 0) := (others => '0');
    signal XBallDirxDP, XBallDirxDN, YBallDirxDP, YBallDirxDN : std_logic := '0'; 
    
    signal BallTouchGroundxS, StartGamexS : std_logic := '0';
    
    signal GameStatexDP, GameStatexDN : game_state := Idle;
    
    signal XPlayerLeftxD, XPlayerRightxD : unsigned(COORD_BW-1 downto 0) := (others => '0'); 
    signal YBallUpxD, YBallDownxD, XBallLeftxD, XBallRightxD : unsigned(COORD_BW-1 downto 0) := (others => '0');
    
    signal RandomxDP, RandomxDN : unsigned(2 - 1 downto 0) := (others => '0');
    
--=============================================================================
-- ARCHITECTURE BEGIN
--=============================================================================
begin

--REGISTER
    regist: process(CLKxCI, RSTxRI) is 
    begin
        if RSTxRI = '1' then
            GameStatexDP <= Idle;
            XPlayerxDP <= (others => '0');
            XBallxDP <= (others => '0');
            YBallxDP <= (others => '0');
            XBallDirxDP <= '0';
            YBallDirxDP <= '0';
            RandomxDP <= (others => '0');
        elsif CLKxCI'event and CLKxCI = '1' then
            GameStatexDP <= GameStatexDN;
            XPlayerxDP <= XPlayerxDN;
            XBallxDP <= XBallxDN;
            YBallxDP <= YBallxDN;
            XBallDirxDP <= XBallDirxDN;
            YBallDirxDP <= YBallDirxDN;
            RandomxDP <= RandomxDN;
        end if;
    end process;
    
    --FSM BALL
    game_fsm: process(GameStatexDP, StartGamexS, BallTouchGroundxS) is
    begin
        GameStatexDN <= GameStatexDP;
      
        case GameStatexDP is 
        when Idle =>
            if StartGamexS = '1' then
                GameStatexDN <= Playing;         
            end if;
            
        when Playing =>
            if BallTouchGroundxS = '1' then
                GameStatexDN <= Idle;
            end if;
        end case;
    end process;
    
    --OUTPUT
    BallXxDO <= XBallxDP;
    BallYxDO <= YBallxDP;
    PlateXxDO <= XPlayerxDP;
    
    --COMBINATORIAL LOGIC
    
    StartGamexS <= '1'          when LeftxSI = '1' and RightxSI = '1' else '0';
    BallTouchGroundxS <= '1'    when YBallDownxD = VS_DISPLAY else '0';
    
    XPlayerLeftxD <= XPlayerxDP - PLATE_WIDTH   when XPlayerxDP > PLATE_WIDTH 
                                                else to_unsigned(0, XPlayerLeftxD'length);
    XPlayerRightxD <= XPlayerxDP + PLATE_WIDTH  when XPlayerxDP < HS_DISPLAY - PLATE_WIDTH 
                                                else to_unsigned(HS_DISPLAY, XPlayerRightxD'length);
    
    YBallUpxD <= YBallxDP - BALL_HEIGHT     when YBallxDP > BALL_HEIGHT 
                                            else to_unsigned(0, YBallUPxD'length);
    YBallDownxD <= YBallxDP + BALL_HEIGHT   when YBallxDP < VS_DISPLAY - BALL_HEIGHT 
                                            else to_unsigned(VS_DISPLAY, YBallDownxD'length);
    XBallLeftxD <= XBallxDP - BALL_WIDTH    when XBallxDP > BALL_WIDTH 
                                            else to_unsigned(0, XBallLeftxD'length);
    XBallRightxD <= XBallxDP + BALL_WIDTH   when XBallxDP < HS_DISPLAY - BALL_WIDTH 
                                            else to_unsigned(HS_DISPLAY, XBallRightxD'length);

    RandomxDN <= RandomxDP + 1 
                 when GameStatexDP = Idle
                 else "00"
                 when GameStatexDP = Playing
                 else RandomxDP;
    
    XBallDirxDN <=      '1' 
                   when (GameStatexDP = Playing and VSEdgexSI = '1' and XBallLeftxD = 0) or 
                        (GameStatexDP = Idle and (RandomxDP = "00" or RandomxDP = "01")) or
                        (RightxSI = '1' and LeftxSI = '0' and GameStatexDP = Playing and VSEdgexSI = '1' and YBallDownxD >= VS_DISPLAY - PLATE_HEIGHT and XBallRightxD >= XPlayerLeftxD and XBallLeftxD <= XPlayerRightxD)
                   else '0' 
                   when (GameStatexDP = Playing and VSEdgexSI = '1' and XBallRightxD = HS_DISPLAY) or 
                        (GameStatexDP = Idle and (RandomxDP = "10" or RandomxDP = "11")) or
                        (RightxSI = '0' and LeftxSI = '1' and GameStatexDP = Playing and VSEdgexSI = '1' and YBallDownxD >= VS_DISPLAY - PLATE_HEIGHT and XBallRightxD >= XPlayerLeftxD and XBallLeftxD <= XPlayerRightxD)                   
                   else XBallDirxDP;

    YBallDirxDN <=      '1' 
                   when (GameStatexDP = Playing and VSEdgexSI = '1' and YBallUPxD = 0) or
                        (GameStatexDP = Idle and (RandomxDP = "00" or RandomxDP = "10"))
                   else '0' 
                   when (GameStatexDP = Playing and VSEdgexSI = '1' and YBallDownxD >= VS_DISPLAY - PLATE_HEIGHT and XBallRightxD >= XPlayerLeftxD and XBallLeftxD <= XPlayerRightxD) or (GameStatexDP = Idle and (RandomxDP = "01" or RandomxDP = "11"))
                   else YBallDirxDP;
                   
    XPlayerxDN <=      XPlayerxDP + PLATE_STEP_X
                  when GameStatexDP = Playing and VSEdgexSI = '1' and RightxSI = '1' and LeftxSI = '0' and XPlayerRightxD < HS_DISPLAY
                  else to_unsigned(HS_DISPLAY - PLATE_WIDTH, XPlayerxDN'length)
                  when GameStatexDP = Playing and VSEdgexSI = '1' and RightxSI = '1' and LeftxSI = '0' and XPlayerRightxD = HS_DISPLAY
                  else XPlayerxDP - PLATE_STEP_X
                  when GameStatexDP = Playing and VSEdgexSI = '1' and RightxSI = '0' and LeftxSI = '1' and XPlayerLeftxD > 0
                  else to_unsigned(PLATE_WIDTH, XPlayerxDN'length)
                  when GameStatexDP = Playing and VSEdgexSI = '1' and RightxSI = '0' and LeftxSI = '1' and XPlayerLeftxD = 0
                  else to_unsigned(HS_DISPLAY/2, XPlayerxDN'length)
                  when GameStatexDP = Idle
                  else XPlayerxDP;
                  
    XBallxDN <=      XBallxDP + BALL_STEP_X
                when GameStatexDP = Playing and VSEdgexSI = '1' and XBallDirxDP = '1' and XBallRightxD < HS_DISPLAY 
                else to_unsigned(HS_DISPLAY - BALL_WIDTH, XBallxDN'length)
                when GameStatexDP = Playing and VSEdgexSI = '1' and XBallDirxDP = '1' and XBallRightxD = HS_DISPLAY 
                else XBallxDP - BALL_STEP_X
                when GameStatexDP = Playing and VSEdgexSI = '1' and XBallDirxDP = '0' and XBallLeftxD > 0
                else to_unsigned(BALL_WIDTH, XBallxDN'length)
                when GameStatexDP = Playing and VSEdgexSI = '1' and XBallDirxDP = '0' and XBallLeftxD = 0
                else to_unsigned(HS_DISPLAY/2, XBallxDN'length)
                when GameStatexDP = Idle
                else XBallxDP;    
                
    YBallxDN <=      YBallxDP + BALL_STEP_Y
                when GameStatexDP = Playing and VSEdgexSI = '1' and YBallDirxDP = '1' and YBallDownxD < VS_DISPLAY
                else to_unsigned(VS_DISPLAY - BALL_HEIGHT, YBallxDN'length)
                when GameStatexDP = Playing and VSEdgexSI = '1' and YBallDirxDP = '1' and YBallDownxD = VS_DISPLAY
                else YBallxDP - BALL_STEP_Y
                when GameStatexDP = Playing and VSEdgexSI = '1' and YBallDirxDP = '0' and YBallUpxD > 0
                else to_unsigned(BALL_HEIGHT, YBallxDN'length)
                when GameStatexDP = Playing and VSEdgexSI = '1' and YBallDirxDP = '0' and YBallUpxD = 0
                else to_unsigned(VS_DISPLAY/4, YBallxDN'length)
                when GameStatexDP = Idle
                else YBallxDP;
end rtl;
--=============================================================================
-- ARCHITECTURE END
--=============================================================================