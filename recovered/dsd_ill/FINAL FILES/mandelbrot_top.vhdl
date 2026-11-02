--=============================================================================
-- @file mandelbrot_top.vhdl
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
-- mandelbrot_top
--
-- @brief This file specifies the toplevel of the pong game with the Mandelbrot
-- to generate the background for lab 8, the final lab.
--
--=============================================================================

--=============================================================================
-- ENTITY DECLARATION FOR MANDELBROT_TOP
--=============================================================================
entity mandelbrot_top is
  port (
    CLK125xCI : in std_logic;
    RSTxRI    : in std_logic;

    -- Button inputs
    LeftxSI  : in std_logic;
    RightxSI : in std_logic;

    -- Timing outputs
    HSxSO : out std_logic;
    VSxSO : out std_logic;
       

    -- Data/color output
    RedxSO   : out std_logic_vector(COLOR_BW - 1 downto 0);
    GreenxSO : out std_logic_vector(COLOR_BW - 1 downto 0);
    BluexSO  : out std_logic_vector(COLOR_BW - 1 downto 0)
  );
end mandelbrot_top;

--=============================================================================
-- ARCHITECTURE DECLARATION
--=============================================================================
architecture rtl of mandelbrot_top is

--=============================================================================
-- SIGNAL (COMBINATIONAL) DECLARATIONS
--=============================================================================;

  -- clk_wiz_0
  signal CLK75xC : std_logic;

  -- blk_mem_gen_0
  signal WrAddrAxD : std_logic_vector(MEM_ADDR_BW - 1 downto 0);
  signal RdAddrBxD : std_logic_vector(MEM_ADDR_BW - 1 downto 0);
  signal ENAxS     : std_logic;
  signal WEAxS     : std_logic_vector(0 downto 0);
  signal ENBxS     : std_logic;
  signal DINAxD    : std_logic_vector(MEM_DATA_BW - 1 downto 0);
  signal DOUTBxD   : std_logic_vector(MEM_DATA_BW - 1 downto 0);
  
  -- blk_mem_gen_1
  signal WrAddrCxD : std_logic_vector(MEM_ADDR_BW - 1 downto 0);
  signal RdAddrDxD : std_logic_vector(MEM_ADDR_BW - 1 downto 0);
  signal ENCxS     : std_logic;
  signal WECxS     : std_logic_vector(0 downto 0);
  signal ENDxS     : std_logic;
  signal DINCxD    : std_logic_vector(MEM_DATA_BW - 1 downto 0);
  signal DOUTDxD   : std_logic_vector(MEM_DATA_BW - 1 downto 0);

  signal BGRedxS   : std_logic_vector(COLOR_BW - 1 downto 0); -- Background colors from the memory
  signal BGGreenxS : std_logic_vector(COLOR_BW - 1 downto 0);
  signal BGBluexS  : std_logic_vector(COLOR_BW - 1 downto 0);

  -- vga_controller
  signal RedxS   : std_logic_vector(COLOR_BW - 1 downto 0); -- Color to VGA controller
  signal GreenxS : std_logic_vector(COLOR_BW - 1 downto 0);
  signal BluexS  : std_logic_vector(COLOR_BW - 1 downto 0);

  signal XCoordxD : unsigned(COORD_BW - 1 downto 0); -- Coordinates from VGA controller
  signal YCoordxD : unsigned(COORD_BW - 1 downto 0);
  
  signal VSEdgexS : std_logic; -- If 1, row counter resets (new frame). HIGH for 1 CC, when vertical sync starts)

  -- pong_fsm
  signal BallXxD  : unsigned(COORD_BW - 1 downto 0); -- Coordinates of ball and plate
  signal BallYxD  : unsigned(COORD_BW - 1 downto 0);
  signal PlateXxD : unsigned(COORD_BW - 1 downto 0);

  signal DrawBallxS  : std_logic; -- If 1, draw the ball
  signal DrawPlatexS : std_logic; -- If 1, draw the plate
  
  signal DistPix_BallxD : signed(32-1 downto 0); -- Distance between ball and the pixel we are ploting
  signal DistXPix_BallxD, DistYPix_BallxD : signed(32-1 downto 0);


  -- mandelbrot
  signal MandelbrotWExS   : std_logic; -- If 1, Mandelbrot writes
  signal MandelbrotXxD    : unsigned(COORD_BW - 1 downto 0);
  signal MandelbrotYxD    : unsigned(COORD_BW - 1 downto 0);
  signal MandelbrotITERxD : unsigned(MEM_DATA_BW - 1 downto 0);    -- Iteration number from Mandelbrot (chooses colour)

  signal CNTxDN, CNTxDP : unsigned(9-1 downto 0);


--=============================================================================
-- COMPONENT DECLARATIONS
--=============================================================================
  component clk_wiz_0 is
    port (
      clk_out1 : out std_logic;
      reset    : in  std_logic;
      locked   : out std_logic;
      clk_in1  : in  std_logic
    );
  end component clk_wiz_0;

  component blk_mem_gen_0
    port (
      clka  : in std_logic;
      ena   : in std_logic;
      wea   : in std_logic_vector(0 downto 0);
      addra : in std_logic_vector(15 downto 0);
      dina  : in std_logic_vector(11 downto 0);

      clkb  : in std_logic;
      enb   : in std_logic;
      addrb : in std_logic_vector(15 downto 0);
      doutb : out std_logic_vector(11 downto 0)
    );
  end component;
  
    component blk_mem_gen_1
    port (
      clka  : in std_logic;
      ena   : in std_logic;
      wea   : in std_logic_vector(0 downto 0);
      addra : in std_logic_vector(15 downto 0);
      dina  : in std_logic_vector(11 downto 0);

      clkb  : in std_logic;
      enb   : in std_logic;
      addrb : in std_logic_vector(15 downto 0);
      doutb : out std_logic_vector(11 downto 0)
    );
  end component;

  component vga_controller is
    port (
      CLKxCI : in std_logic;
      RSTxRI : in std_logic;

      -- Data/color input
      RedxSI   : in std_logic_vector(COLOR_BW - 1 downto 0);
      GreenxSI : in std_logic_vector(COLOR_BW - 1 downto 0);
      BluexSI  : in std_logic_vector(COLOR_BW - 1 downto 0);

      -- Coordinate output
      XCoordxDO : out unsigned(COORD_BW - 1 downto 0);
      YCoordxDO : out unsigned(COORD_BW - 1 downto 0);

      -- Timing output
      HSxSO : out std_logic;
      VSxSO : out std_logic;
      
      VSEdgexSO : out std_logic;


      -- Data/color output
      RedxSO   : out std_logic_vector(COLOR_BW - 1 downto 0);
      GreenxSO : out std_logic_vector(COLOR_BW - 1 downto 0);
      BluexSO  : out std_logic_vector(COLOR_BW - 1 downto 0)
    );
  end component vga_controller;
    
  component pong_fsm is
    port (
      CLKxCI : in std_logic;
      RSTxRI : in std_logic;

      -- Controls from push buttons
      LeftxSI  : in std_logic;
      RightxSI : in std_logic;

      -- Coordinate from VGA
      VgaXxDI : in unsigned(COORD_BW - 1 downto 0);
      VgaYxDI : in unsigned(COORD_BW - 1 downto 0);

      -- Ball and plate coordinates
      BallXxDO  : out unsigned(COORD_BW - 1 downto 0);
      BallYxDO  : out unsigned(COORD_BW - 1 downto 0);
      PlateXxDO : out unsigned(COORD_BW - 1 downto 0);
      
      VSEdgexSI : in std_logic 

    );
  end component pong_fsm;
  
  component mandelbrot is
    port (
      CLKxCI : in  std_logic;
      RSTxRI : in  std_logic;

      WExSO   : out std_logic;
      XxDO    : out unsigned(COORD_BW - 1 downto 0);
      YxDO    : out unsigned(COORD_BW - 1 downto 0);
      ITERxDO : out unsigned(MEM_DATA_BW - 1 downto 0)
    );
  end component mandelbrot;

--=============================================================================
-- ARCHITECTURE BEGIN
--=============================================================================
begin

--=============================================================================
-- COMPONENT INSTANTIATIONS
--=============================================================================
  i_clk_wiz_0 : clk_wiz_0
    port map (
      clk_out1 => CLK75xC,
      reset    => RSTxRI,
      locked   => open,
      clk_in1  => CLK125xCI
    );

  i_blk_mem_gen_0 : blk_mem_gen_0
    port map (
      clka  => CLK75xC,
      ena   => ENAxS,
      wea   => WEAxS,
      addra => WrAddrAxD,
      dina  => DINAxD,

      clkb  => CLK75xC,
      enb   => ENBxS,
      addrb => RdAddrBxD,
      doutb => DOUTBxD
    );
    
    i_blk_mem_gen_1 : blk_mem_gen_1
    port map (
      clka  => CLK75xC,
      ena   => ENCxS,
      wea   => WECxS,
      addra => WrAddrCxD,
      dina  => DINCxD,

      clkb  => CLK75xC,
      enb   => ENDxS,
      addrb => RdAddrDxD,
      doutb => DOUTDxD
    );

  i_vga_controller: vga_controller
    port map (
      CLKxCI => CLK75xC,
      RSTxRI => RSTxRI,

      RedxSI   => RedxS,
      GreenxSI => GreenxS,
      BluexSI  => BluexS,

      HSxSO => HSxSO,
      VSxSO => VSxSO,

      VSEdgexSO => VSEdgexS,

      XCoordxDO => XCoordxD,
      YCoordxDO => YCoordxD,

      RedxSO   => RedxSO,
      GreenxSO => GreenxSO,
      BluexSO  => BluexSO
    );
  
  i_pong_fsm : pong_fsm
    port map (
      CLKxCI => CLK75xC,
      RSTxRI => RSTxRI,

      RightxSI => RightxSI,
      LeftxSI  => LeftxSI,

      VgaXxDI => XCoordxD,
      VgaYxDI => YCoordxD,

      VSEdgexSI => VSEdgexS,
      
      BallXxDO  => BallXxD,
      BallYxDO  => BallYxD,
      PlateXxDO => PlateXxD
    );

  i_mandelbrot : mandelbrot
    port map (
      CLKxCI  => CLK75xC,
      RSTxRI  => RSTxRI,

      WExSO   => MandelbrotWExS,
      XxDO    => MandelbrotXxD,
      YxDO    => MandelbrotYxD,
      ITERxDO => MandelbrotITERxD
    );
    
    cnt: process(CLK75xC, RSTxRI) is
    begin
        if RSTxRI = '1' then
            CNTxDP <= (OTHERS => '0');
        elsif CLK75xC'event and CLK75xC = '1' then
            CNTxDP <= CNTxDN;
        end if;
    end process;
    
   

--=============================================================================
-- MEMORY SIGNAL MAPPING
--=============================================================================
-- Writing
-- Port A
  ENAxS     <= MandelbrotWExS;
  WEAxS     <= (others => MandelbrotWExS);
  WrAddrAxD <= std_logic_vector(resize(unsigned(MandelbrotXxD(COORD_BW - 1 downto 2))+unsigned(MandelbrotYxD(COORD_BW - 1 downto 2))*256, RdAddrBxD'length));
  DINAxD    <= std_logic_vector(MandelbrotITERxD);
  
-- Port C (second mandelbrot)
  ENCxS     <= MandelbrotWExS;
  WECxS     <= (others => MandelbrotWExS);
  WrAddrCxD <= std_logic_vector(resize(unsigned(MandelbrotXxD(COORD_BW - 1 downto 2))+unsigned(MandelbrotYxD(COORD_BW - 1 downto 2))*256, RdAddrBxD'length));
  DINCxD    <= std_logic_vector(MandelbrotITERxD);  

-- Reading
-- Port B
  ENBxS     <= '1'; 
      
  RdAddrBxD <= std_logic_vector(resize(unsigned(XCoordxD(COORD_BW - 1 downto 2))+unsigned(YCoordxD(COORD_BW - 1 downto 2))*256,  RdAddrBxD'length));

-- Port D (second mandelbrot)
  ENDxS     <= '1'; 
      
  RdAddrDxD <= std_logic_vector(resize(unsigned(XCoordxD(COORD_BW - 1 downto 2)+CNTxDP)+unsigned(YCoordxD(COORD_BW - 1 downto 2))*256,  RdAddrDxD'length));
--=============================================================================
-- SPRITE SIGNAL MAPPING
--=============================================================================
 
 process(all) is 
 begin
  if (DOUTBxD < "000001100100") then 
  
      BGRedxS   <= DOUTBxD(11 downto 8);
      BGGreenxS <= DOUTBxD(7 downto 4);
      BGBluexS  <= DOUTBxD(3 downto 0);
  else 
      BGRedxS   <= DOUTDxD(11 downto 8);
      BGGreenxS <= DOUTDxD(7 downto 4);
      BGBluexS  <= DOUTDxD(3 downto 0);
  end if;
  end process;
  
  process(all) is
  begin
  if (VSEdgexS = '1') then
    CNTxDN <= CNTxDP + 1;
  elsif (CNTxDP = "11111111") then
    CNTxDN <= (OTHERS => '0');
  else
    CNTxDN <= CNTxDP;
  end if;
  end process;
    
   process (all) is 
  begin
    if (YCoordxD >= VS_DISPLAY - PLATE_HEIGHT) and (XCoordxD >= (PlateXxD - PLATE_WIDTH) and XCoordxD <= (PlateXxD + PLATE_WIDTH)) then
      DrawPlatexS <= '1';
      DrawBallxS <= '0';
    elsif (XCoordxD >= BallXxD - BALL_WIDTH) and (XCoordxD <= BallXxD + BALL_WIDTH) and (YCoordxD >= BallYxD - BALL_WIDTH) and (YCoordxD <= BallYxD + BALL_WIDTH) then
      DrawPlatexS <= '0';
      DrawBallxS <= '1';
    else
      DrawPlatexS <= '0';
      DrawBallxS <= '0';
    end if;
    
  
    if DrawPlatexS = '1' then
      RedxS   <= "1111";
      GreenxS <= "0000";
      BluexS  <= "1111";
    elsif DrawBallxS = '1' then
      RedxS   <= "0000";
      GreenxS <= "0000";
      BluexS  <= "1111";
    else
      RedxS   <= BGRedxS;
      GreenxS <= BGGreenxS;
      BluexS  <= BGBluexS;
     
    end if;
  end process;process (all) is 
  begin
    if (YCoordxD >= VS_DISPLAY - PLATE_HEIGHT) and (XCoordxD >= (PlateXxD - PLATE_WIDTH) and XCoordxD <= (PlateXxD + PLATE_WIDTH)) then
      DrawPlatexS <= '1';
      DrawBallxS <= '0';
    elsif (XCoordxD >= BallXxD - BALL_WIDTH) and (XCoordxD <= BallXxD + BALL_WIDTH) and (YCoordxD >= BallYxD - BALL_WIDTH) and (YCoordxD <= BallYxD + BALL_WIDTH) then
      DrawPlatexS <= '0';
      DrawBallxS <= '1';
    else
      DrawPlatexS <= '0';
      DrawBallxS <= '0';
    end if;
    
  
    if DrawPlatexS = '1' then
      RedxS   <= "1111";
      GreenxS <= "0000";
      BluexS  <= "1111";
    elsif DrawBallxS = '1' then
      RedxS   <= "0000";
      GreenxS <= "0000";
      BluexS  <= "1111";
    else
      RedxS   <= BGRedxS;
      GreenxS <= BGGreenxS;
      BluexS  <= BGBluexS;
     
    end if;
  end process;
  
end rtl;
--=============================================================================
-- ARCHITECTURE END
--=============================================================================
