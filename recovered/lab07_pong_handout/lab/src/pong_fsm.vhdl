--=============================================================================
-- @file pong_fsm.vhdl
-- MY ONE
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
-- @brief This file specifies a basic circuit for the pong game. Note that 
-- coordinates are counted from the upper left corner of the screen.
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

    -- FSM states
    type PongFSM_Type is (IDLE, PLAYING, GAME_OVER);

    -- FSM state signals
    signal STATExDN, STATExDP : PongFSM_Type;

    -- Ball position signals
    signal BallXxDN, BallXxDP : unsigned(COORD_BW - 1 downto 0);
    signal BallYxDN, BallYxDP : unsigned(COORD_BW - 1 downto 0);

    -- Ball direction signals: '1' = positive (right or down), '0' = negative (left or up)
    signal BallDirXxDN, BallDirXxDP : std_logic;
    signal BallDirYxDN, BallDirYxDP : std_logic;

    -- Plate position signals
    signal PlateXxDN, PlateXxDP : unsigned(COORD_BW - 1 downto 0);

    -- Control signals (FSM -> datapath)
    signal BallENxS  : std_logic;  -- Enable ball movement
    signal BallCLRxS : std_logic;  -- Reset ball to center
    signal PlateENxS : std_logic;  -- Enable plate movement

    -- Status signals (datapath -> FSM)
    signal HitBottomxS : std_logic;
    signal HitPlatexS  : std_logic;

--=============================================================================
-- ARCHITECTURE BEGIN
--=============================================================================
begin

--=============================================================================
-- STATE AND DATA REGISTERS
--=============================================================================
  p_Reg : process (CLKxCI, RSTxRI) is
  begin
    if RSTxRI = '1' then
      -- Async reset: initialize all registers
      STATExDP    <= IDLE;
      BallXxDP    <= to_unsigned(HS_DISPLAY / 2, COORD_BW);
      BallYxDP    <= to_unsigned(VS_DISPLAY / 2, COORD_BW);
      BallDirXxDP <= '1';
      BallDirYxDP <= '1';
      PlateXxDP   <= to_unsigned(HS_DISPLAY / 2 - PLATE_WIDTH / 2, COORD_BW);

    elsif CLKxCI'event and CLKxCI = '1' then
      -- Rising clock edge: update all registers
      STATExDP    <= STATExDN;
      BallXxDP    <= BallXxDN;
      BallYxDP    <= BallYxDN;
      BallDirXxDP <= BallDirXxDN;
      BallDirYxDP <= BallDirYxDN;
      PlateXxDP   <= PlateXxDN;
    end if;
  end process p_Reg;

--=============================================================================
-- FSM COMBINATIONAL PROCESS
--=============================================================================
  p_FSM : process (all) is
  begin
    -- Default assignments
    STATExDN  <= STATExDP;
    BallENxS  <= '0';
    BallCLRxS <= '0';
    PlateENxS <= '0';

    case STATExDP is

      ----------------------------------------------------------------------
      -- IDLE: Wait for both buttons to start the game
      ----------------------------------------------------------------------
      when IDLE =>
        PlateENxS <= VSEdgexSI;  -- Allow plate movement in IDLE

        if LeftxSI = '1' and RightxSI = '1' then
          BallCLRxS <= '1';      -- Reset ball to center
          STATExDN  <= PLAYING;
        end if;

      ----------------------------------------------------------------------
      -- PLAYING: Game active, ball moves
      ----------------------------------------------------------------------
      when PLAYING =>
        BallENxS  <= VSEdgexSI;  -- Move ball once per frame
        PlateENxS <= VSEdgexSI;  -- Move plate once per frame

        -- Check for game over: ball hit bottom without hitting plate
        if HitBottomxS = '1' and HitPlatexS = '0' then
          STATExDN <= GAME_OVER;
        end if;

      ----------------------------------------------------------------------
      -- GAME_OVER: Wait for restart
      ----------------------------------------------------------------------
      when GAME_OVER =>
        if LeftxSI = '1' and RightxSI = '1' then
          STATExDN <= IDLE;
        end if;

      when others =>
        STATExDN <= IDLE;

    end case;
  end process p_FSM;

--=============================================================================
-- COLLISION DETECTION (concurrent assignments)
--=============================================================================

  -- Hit bottom of screen (ball reaches actual bottom)
  HitBottomxS <= '1' when (BallYxDP + to_unsigned(BALL_HEIGHT, COORD_BW) >= to_unsigned(VS_DISPLAY, COORD_BW)) else '0';

  -- Hit plate: ball overlaps with plate horizontally when at plate level
  HitPlatexS <= '1' when (BallYxDP + to_unsigned(BALL_HEIGHT, COORD_BW) >= to_unsigned(PLATE_Y, COORD_BW) and
                          BallYxDP + to_unsigned(BALL_HEIGHT, COORD_BW) < to_unsigned(PLATE_Y + PLATE_HEIGHT, COORD_BW) and
                          BallXxDP + to_unsigned(BALL_WIDTH, COORD_BW) > PlateXxDP and
                          BallXxDP < PlateXxDP + to_unsigned(PLATE_WIDTH, COORD_BW)) else '0';
                          

--=============================================================================
-- BALL DIRECTION LOGIC (concurrent assignments)
--=============================================================================

  -- Ball X direction
  BallDirXxDN <= '1' when (BallENxS = '1' and BallXxDP <= to_unsigned(BALL_STEP_SIZE, COORD_BW)) else
                 '0' when (BallENxS = '1' and BallXxDP >= to_unsigned(HS_DISPLAY - BALL_WIDTH - BALL_STEP_SIZE, COORD_BW)) else
                 VgaXxDI(0) when (BallCLRxS = '1') else
                 BallDirXxDP;

  -- Ball Y direction
  BallDirYxDN <= '1' when (BallENxS = '1' and BallYxDP <= to_unsigned(BALL_STEP_SIZE, COORD_BW)) else
                 '0' when (BallENxS = '1' and HitPlatexS = '1') else
                 '1' when (BallCLRxS = '1') else
                 BallDirYxDP;

--=============================================================================
-- BALL POSITION LOGIC (concurrent assignments)
--=============================================================================

  -- Ball X position
  BallXxDN <= to_unsigned(HS_DISPLAY / 2, COORD_BW) when (BallCLRxS = '1') else
              BallXxDP + to_unsigned(BALL_STEP_SIZE, COORD_BW) when (BallENxS = '1' and BallDirXxDP = '1') else
              BallXxDP - to_unsigned(BALL_STEP_SIZE, COORD_BW) when (BallENxS = '1' and BallDirXxDP = '0') else
              BallXxDP;

  -- Ball Y position
  BallYxDN <= to_unsigned(VS_DISPLAY / 2, COORD_BW) when (BallCLRxS = '1') else
              BallYxDP + to_unsigned(BALL_STEP_SIZE, COORD_BW) when (BallENxS = '1' and BallDirYxDP = '1') else
              BallYxDP - to_unsigned(BALL_STEP_SIZE, COORD_BW) when (BallENxS = '1' and BallDirYxDP = '0') else
              BallYxDP;

--=============================================================================
-- PLATE POSITION LOGIC (concurrent assignments)
--=============================================================================

  PlateXxDN <= PlateXxDP - to_unsigned(PLATE_STEP_SIZE, COORD_BW) when (PlateENxS = '1' and LeftxSI = '1' and RightxSI = '0' and PlateXxDP > to_unsigned(PLATE_STEP_SIZE, COORD_BW)) else
               to_unsigned(0, COORD_BW) when (PlateENxS = '1' and LeftxSI = '1' and RightxSI = '0') else
               PlateXxDP + to_unsigned(PLATE_STEP_SIZE, COORD_BW) when (PlateENxS = '1' and RightxSI = '1' and LeftxSI = '0' and PlateXxDP < to_unsigned(HS_DISPLAY - PLATE_WIDTH - PLATE_STEP_SIZE, COORD_BW)) else
               to_unsigned(HS_DISPLAY - PLATE_WIDTH, COORD_BW) when (PlateENxS = '1' and RightxSI = '1' and LeftxSI = '0') else
               PlateXxDP;

--=============================================================================
-- OUTPUT LOGIC (concurrent assignments)
--=============================================================================

  BallXxDO  <= BallXxDP;
  BallYxDO  <= BallYxDP;
  PlateXxDO <= PlateXxDP;
  
  


end rtl;
--=============================================================================
-- ARCHITECTURE END
--=============================================================================