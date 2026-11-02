--=============================================================================
-- @file pong_fsm.vhdl
--=============================================================================
-- Standard library
library ieee;
-- Standard packages
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
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
--    VgaXxDI : in unsigned(COORD_BW - 1 downto 0);
 --   VgaYxDI : in unsigned(COORD_BW - 1 downto 0);

    -- Signals from video interface to synchronize (HIGH for 1 CC, when vertical sync starts)
   -- VSEdgexSI : in std_logic;

    -- Ball and plate coordinates
    BallXxDO  : out signed(COORD_BW - 1 downto 0);
    BallYxDO  : out signed(COORD_BW - 1 downto 0);
    PlateXxDO : out signed(COORD_BW - 1 downto 0)
  );
end pong_fsm;

--=============================================================================
-- ARCHITECTURE DECLARATION
--=============================================================================
architecture rtl of pong_fsm is

-- TODO: Implement your code here
type player_state is (Reset, Idle, LoseGame,
                      GoingLeft, TouchingLeftWall,
                      GoingRight, TouchingRightWall);
                      
type ball_state is (Reset, Moving, LoseGame,
                    TouchingTop, TouchingDown,
                    TouchingLeft, TouchingRight,
                    TouchingPlayerTop,
                    TouchingLeftCorner, TouchingRightCorner);
                    
signal XPlayerLeftxD, XPlayerRightxD : signed(COORD_BW-1 downto 0) := (others => '0'); 
signal YBallUpxD, YBallDownxD, XBallLeftxD, XBallRightxD : signed(COORD_BW-1 downto 0) := (others => '0');
signal BallTouchGroundxS, StartGamexS : std_logic := '0';

signal PlayerStatexDP, PlayerStatexDN : player_state := Reset;
signal BallStatexDP, BallStatexDN : ball_state  := Reset;

signal XPlayerxDP, XPlayerxDN, XBallxDP, XBallxDN, YBallxDP, YBallxDN : signed(COORD_BW-1 downto 0) := (others => '0');
signal XBallSpeedxDP, XBallSpeedxDN, YBallSpeedxDP, YBallSpeedxDN : signed(COORD_BW-1 downto 0) := (others => '0');
signal DistB_LCxD, DistB_RCxD : signed(32-1 downto 0) := (others => '0');


--=============================================================================
-- ARCHITECTURE BEGIN
--=============================================================================
begin

-- TODO: Implement your code here

regist: process(RSTxRI, CLKxCI) is 
    begin
        if RSTxRI = '1' then
            PlayerStatexDP <= Reset;
            BallStatexDP <= Reset;
            XPlayerxDP <= to_signed(512, XPlayerxDP'length);
            XBallxDP <= to_signed(512, XBallxDP'length);
            YBallxDP <= to_signed(384, YBallxDP'length);
            XBallSpeedxDP <= (others =>'0');
            YBallSpeedxDP <= (others =>'0');
        elsif CLKxCI'event and CLKxCI = '1' then
            PlayerStatexDP <= PlayerStatexDN;
            BallStatexDP <= BallStatexDN;
            XPlayerxDP <= XPlayerxDN;
            XBallxDP <= XBallxDN;
            YBallxDP <= YBallxDN;
            XBallSpeedxDP <= XBallSpeedxDN;
            YBallSpeedxDP <= YBallSpeedxDN;
        end if;
    end process;
    
XPlayerLeftxD <= XPlayerxDN - PLATE_WIDTH;
XPlayerRightxD <= XPlayerxDN + PLATE_WIDTH;

YBallUpxD <= YBallxDN - BALL_WIDTH;
YBallDownxD <= YBallxDN + BALL_HEIGHT;
XBallLeftxD <= XBallxDN - BALL_HEIGHT;
XBallRightxD <= XBallxDN + BALL_WIDTH;
DistB_LCxD <= resize((XPlayerLeftxD - XBallxDN ) * (XPlayerLeftxD - XBallxDN ) + (YBallxDN - (VS_DISPLAY - PLATE_HEIGHT)) * (YBallxDN - (VS_DISPLAY - PLATE_HEIGHT)) , 32); 
DistB_RCxD <= resize((XBallxDN - XPlayerRightxD ) * (XBallxDN - XPlayerRightxD ) + (YBallxDN - (VS_DISPLAY - PLATE_HEIGHT)) * (YBallxDN - (VS_DISPLAY - PLATE_HEIGHT)), 32);

BallXxDO <= XBallxDP;
BallYxDO <= YBallxDP;
PlateXxDO <= XplayerxDP;

StartGamexS <= '1' when LeftxSI = '1' and RightxSI = '1' else '0';

switch_case: process(all) is 
begin
    case PlayerStatexDN is 
        when Reset =>
            XPlayerxDN <= to_signed(512, XPlayerxDN'length); -- mettre au milieu 384
            BallTouchGroundxS <= '0';
            if StartGamexS = '1' then
                PlayerStatexDN <= Idle;
            end if;
            
        when LoseGame =>       
            if LeftxSI = '1' and RightxSI = '0' then
                PlayerStatexDN <= Reset; 
            end if;
            
        when Idle =>          
            if LeftxSI = '1' and RightxSI = '0' then
                PlayerStatexDN <= Goingleft;
                  
            elsif LeftxSI = '0' and RightxSI = '1' then
                PlayerStatexDN <= GoingRight;
                
            elsif BallTouchGroundxS = '1' then
                PlayerStatexDN <= LoseGame;
            end if;
            
        when GoingLeft =>
            XPlayerxDN <= XPlayerxDP - PLATE_STEP_X;
            
            if (LeftxSI = '1' and RightxSI = '1') or LeftxSI = '0' then
                PlayerStatexDN <= Idle;
                  
            elsif LeftxSI = '1' and RightxSI = '0' and XPlayerleftxD <= 0 then
                PlayerStatexDN <= TouchingLeftWall;
                
            elsif BallTouchGroundxS = '1' then
                PlayerStatexDN <= LoseGame;
            end if;
        
        when TouchingLeftWall =>      
             if LeftxSI = '0' then
                PlayerStatexDN <= Idle;
                
            elsif BallTouchGroundxS = '1' then
                PlayerStatexDN <= LoseGame;
            end if;
        
        when GoingRight =>
            XPlayerxDN <= XPlayerxDP + PLATE_STEP_X;
            
            if (LeftxSI = '1' and RightxSI = '1') or RightxSI = '0' then
                PlayerStatexDN <= Idle;
                  
            elsif LeftxSI = '0' and RightxSI = '1' and XPlayerRightxD >= HS_DISPLAY then
                PlayerStatexDN <= TouchingRightWall;
                
            elsif BallTouchGroundxS = '1' then
                PlayerStatexDN <= LoseGame;
            end if;
            
        when TouchingRightWall =>        
            if RightxSI = '0' then
                PlayerStatexDN <= Idle;
                
            elsif BallTouchGroundxS = '1' then
                PlayerStatexDN <= LoseGame;
            end if;

    end case;
    
    case BallStatexDN is
    when Reset =>    
        XBallxDN <= to_signed(587, XBallxDN'length); -- Mettre au centre de l'écran X = 512
        YBallxDN <= to_signed(35, YBallxDN'length); -- Mettre au centre de l'écran Y = 384 
        XBallSpeedxDN <= to_signed(0, XBallSpeedxDN'length);
        YBallSpeedxDN <= to_signed(5, YBallSpeedxDN'length);
        BallTouchGroundxS <= '0';
        
        if StartGamexS = '1' then
            BallStatexDN <= Moving;
        end if;
        
    when LoseGame =>
        if LeftxSI = '1' and RightxSI = '1' then
            BallStatexDN <= Reset;
        end if;
        
    when Moving =>
        XBallxDN <= XBallxDP + XBallSpeedxDN;
        YBallxDN <= YBallxDP + YBallSpeedxDN;
        
        if YBallUpxD <= 0 then
            BallStatexDN <= TouchingTop;
        elsif YBallDownxD >= VS_DISPLAY then
            BallStatexDN <= TouchingDown;
        elsif XBallLeftxD <= 0 then
            BallStatexDN <= TouchingLeft;
        elsif XBallRightxD >= HS_DISPLAY then
            BallStatexDN <= TouchingRight;
        elsif (YBallDownxD <= PLATE_HEIGHT) and (XBallxDN >= XPlayerLeftxD) and (XBallxDN <= XPlayerRightxD) then
            BallStatexDN <= TouchingPlayerTop;
        elsif (XBallxDN <= XPlayerLeftxD) and (YBallxDN >= PLATE_HEIGHT) and (DistB_LCxD <= (BALL_WIDTH ** 2))then
            BallStatexDN <= TouchingLeftCorner;
        elsif (XBallxDN >= XPlayerRightxD) and (YBallxDN >= PLATE_HEIGHT) and (DistB_RCxD <= (BALL_WIDTH ** 2))then
            BallStatexDN <= TouchingRightCorner;
        end if;    
        
    when TouchingTop =>
        YBallSpeedxDN <= -YBallSpeedxDP;
        
        BallStatexDN <= Moving;  
          
    when TouchingDown =>
        BallTouchGroundxS <= '1';
        
        BallStatexDN <= LoseGame;   
        
    when TouchingLeft =>        
        XBallSpeedxDN <= -XBallSpeedxDP;

        BallStatexDN <= Moving; 
        
    when TouchingRight =>    
        XBallSpeedxDN <= -XBallSpeedxDP;
    
        BallStatexDN <= Moving;
        
    when TouchingPlayerTop =>
        YBallSpeedxDN <= -YBallSpeedxDP;
        
        BallStatexDN <= Moving;
        
    when TouchingLeftCorner =>
        XBallSpeedxDN <= to_signed(-2, XBallSpeedxDN'length);
        YBallSpeedxDN <= to_signed(-2, YBallSpeedxDN'length);

        BallStatexDN <= Moving;
    
    when TouchingRightCorner =>
        XBallSpeedxDN <= to_signed(2, XBallSpeedxDN'length);
        YBallSpeedxDN <= to_signed(-2, YBallSpeedxDN'length);
        
        BallStatexDN <= Moving;

    end case; 
end process;

end rtl;
--=============================================================================
-- ARCHITECTURE END
--=============================================================================
