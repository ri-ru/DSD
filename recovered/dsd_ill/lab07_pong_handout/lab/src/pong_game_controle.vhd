----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 27.11.2024 09:47:46
-- Design Name: 
-- Module Name: pong_game_controle - Behavioral
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
use IEEE.STD_LOGIC_1164.ALL;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity pong_game_controle is
    generic(
    YMax, XMax : integer := 100;
    Ymin, XMin : integer := 0;
    XPlayerSpeed : integer := 1;
    SpeedBallX : integer := 1;
    SpeedBallY : integer := 3;
    PlayerWidth : integer := 10;
    BallSize : integer := 5;
    YPlayerTop : integer := 10;
    DiagPlayer : integer := 15 );

    port (
    CLKxCI : in std_logic;
    RSTxRI : in std_logic;
    
    KeyLeftxSI : in std_logic;
    KeyRightxSI : in std_logic;
    StartGamexSI : in std_logic 
    
     );
end pong_game_controle;

architecture Behavioral of pong_game_controle is

type player_state is (Reset, Idle, LoseGame,
                      GoingLeft, TouchingLeftWall,
                      GoingRight, TouchingRightWall);
                      
type ball_state is (Reset, Moving, LoseGame,
                    TouchingTop, TouchingDown,
                    TouchingLeft, TouchingRight,
                    TouchingPlayerTop);
                    -- TouchingLeftCorner, TouchingRightCorner);
                    
signal XPlayerLeftxD, XPlayerRightxD : unsigned(8-1 downto 0) := (others => '0'); 
signal YBallUpxD, YBallDownxD, XBallLeftxD, XBallRightxD : unsigned(8-1 downto 0) := (others => '0');
signal BallTouchGroundxS : std_logic := '0';

signal PlayerStatexDP, PlayerStatexDN : player_state := Reset;
signal BallStatexDP, BallStatexDN : ball_state  := Reset;

signal XPlayerxDP, XPlayerxDN, XBallxDP, XBallxDN, YBallxDP, YBallxDN : unsigned(8-1 downto 0) := (others => '0');
signal XBallSpeedxDP, XBallSpeedxDN, YBallSpeedxDP, YBallSpeedxDN : unsigned(8-1 downto 0) := (others => '0');
signal DistB_PxD : unsigned(8-1 downto 0) := (others => '0');

begin

regist: process(RSTxRI, CLKxCI) is 
    begin
        if RSTxRI = '1' then
            PlayerStatexDP <= Reset;
            BallStatexDP <= Reset;
            XPlayerxDP <= (others =>'0');
            XBallxDP <= (others =>'0');
            YBallxDP <= (others =>'0');
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

XPlayerLeftxD <= XPlayerxDP - PlayerWidth;
XPlayerRightxD <= XPlayerxDP + PlayerWidth;

YBallUpxD <= YBallxDP + BallSize;
YBallDownxD <= YBallxDP - BallSize;
XBallLeftxD <= XBallxDP - BallSize;
XBallRightxD <= XBallxDP + BallSize;


switch_case: process(all) is 
begin
    case PlayerStatexDN is 
        when Reset =>
            XPlayerxDN <= "0000"; -- mettre au milieu
            BallTouchGroundxS <= '0';
            if StartGamexSI = '1' then
                PlayerStatexDN <= Idle;
            end if;
            
        when LoseGame =>       
            if KeyLeftxSI = '1' and KeyRightxSI = '0' then
                PlayerStatexDN <= Reset; 
            end if;
            
        when Idle =>          
            if KeyLeftxSI = '1' and KeyRightxSI = '0' then
                PlayerStatexDN <= Goingleft;
                  
            elsif KeyLeftxSI = '0' and KeyRightxSI = '1' then
                PlayerStatexDN <= GoingRight;
                
            elsif BallTouchGroundxS = '1' then
                PlayerStatexDN <= LoseGame;
            end if;
            
        when GoingLeft =>
            XPlayerxDN <= XPlayerxDP - XPlayerSpeed;
            
            if (KeyLeftxSI = '1' and KeyRightxSI = '1') or KeyLeftxSI = '0' then
                PlayerStatexDN <= Idle;
                  
            elsif KeyLeftxSI = '1' and KeyRightxSI = '0' and (XPlayerleftxD < XMin or XPlayerLeftxD < XBallRightxD) then
                PlayerStatexDN <= TouchingLeftWall;
                
            elsif BallTouchGroundxS = '1' then
                PlayerStatexDN <= LoseGame;
            end if;
        
        when TouchingLeftWall =>      
             if KeyLeftxSI = '0' then
                PlayerStatexDN <= Idle;
                
            elsif BallTouchGroundxS = '1' then
                PlayerStatexDN <= LoseGame;
            end if;
        
        when GoingRight =>
            XPlayerxDN <= XPlayerxDP + XPlayerSpeed;
            
            if (KeyLeftxSI = '1' and KeyRightxSI = '1') or KeyRightxSI = '0' then
                PlayerStatexDN <= Idle;
                  
            elsif KeyLeftxSI = '0' and KeyRightxSI = '1' and (XPlayerRightxD < XMax or XPlayerRightxD > XBallLeftxD) then
                PlayerStatexDN <= TouchingLeftWall;
                
            elsif BallTouchGroundxS = '1' then
                PlayerStatexDN <= LoseGame;
            end if;
            
        when TouchingRightWall =>        
            if KeyRightxSI = '0' then
                PlayerStatexDN <= Idle;
                
            elsif BallTouchGroundxS = '1' then
                PlayerStatexDN <= LoseGame;
            end if;

    end case;
    
    case BallStatexDN is
    when Reset =>    
        XBallxDN <= "0000"; -- Mettre au centre de l'écran
        YBallxDN <= "0000"; -- Mettre au centre de l'écran
        BallTouchGroundxS <= '0';
        
        if StartGamexSI = '1' then
            BallStatexDN <= Moving;
        end if;
        
    when LoseGame =>
        if KeyLeftxSI = '1' and KeyRightxSI = '1' then
            BallStatexDN <= Reset;
        end if;
        
    when Moving =>
        XBallxDN <= XBallxDP + XBallSpeedxDP;
        YBallxDN <= YBallxDP + YBallSpeedxDP;
        
        if YBallUpxD > YMax then
            BallStatexDN <= TouchingTop;
        elsif YBallDownxD < YMin then
            BallStatexDN <= TouchingDown;
        elsif (XBallLeftxD < XMin) or ((XBallLeftxD < XPlayerRightxD) and (YBallxDN < YPlayerTop)) then
            BallStatexDN <= TouchingLeft;
        elsif (XBallRightxD > XMax) or ((XBallRightxD > XPlayerLeftxD) and (YBallxDN < YPlayerTop)) then
            BallStatexDN <= TouchingRight;
        elsif (YBallDownxD < YPlayerTop) and (XBallxDN > XPlayerLeftxD) and (XBallxDN < XPlayerRightxD) then
            BallStatexDN <= TouchingPlayerTop;
/*        elsif (XBallxDN < XPlayerLeftxD) and (YBallxDN > YPlayerTop) and (DistB_PxD < BallSize + DiagPlayer)then
            BallStatexDN <= TouchingLeftCorner;
        elsif (XBallxDN > XPlayerRightxD) and (YBallxDN > YPlayerTop) and (DistB_PxD < BallSize + DiagPlayer)then
            BallStatexDN <= TouchingRightCorner;*/
        end if;    
        
    when TouchingTop =>
        YBallSpeedxDN <= YBallSpeedxDP * (-1);
        
        BallStatexDN <= Moving;  
          
    when TouchingDown =>
        BallTouchGroundxS <= '1';
        
        BallStatexDN <= LoseGame;   
        
    when TouchingLeft =>        
        XBallSpeedxDN <= XBallSpeedxDP * (-1);

        BallStatexDN <= Moving; 
        
    when TouchingRight =>    
        XBallSpeedxDN <= XBallSpeedxDP * (-1);
    
        BallStatexDN <= Moving;
        
    when TouchingPlayerTop =>
        YBallSpeedxDN <= YBallSpeedxDP * (-1);
        
        BallStatexDN <= Moving;
 /*       
    when TouchingLeftCorner =>
    
        BallStatexDN <= Moving;
    
    when TouchingRightCorner =>
        
        BallStatexDN <= Moving;
*/
    end case; 
end process;

end Behavioral;
