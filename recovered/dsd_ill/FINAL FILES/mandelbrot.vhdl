--=============================================================================
-- @file mandelbrot.vhdl
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
-- mandelbrot
--
-- @brief This file specifies a basic circuit for mandelbrot
--
--=============================================================================

--=============================================================================
-- ENTITY DECLARATION FOR MANDELBROT
--=============================================================================
entity mandelbrot is
  port (
    CLKxCI : in std_logic;
    RSTxRI : in std_logic;

    WExSO   : out std_logic;
    XxDO    : out unsigned(COORD_BW - 1 downto 0);
    YxDO    : out unsigned(COORD_BW - 1 downto 0);
    ITERxDO : out unsigned(MEM_DATA_BW - 1 downto 0)
  );
end entity mandelbrot;

--=============================================================================
-- ARCHITECTURE DECLARATION
--=============================================================================
architecture rtl of mandelbrot is

  --Signal definition
  --Position coordinates
  signal XxDP, XxDN, YxDP, YxDN: unsigned(COORD_BW-1 downto 0);
  --Complex number c used for iteration 
  signal C_RExDP, C_RExDN, C_IMxDP, C_IMxDN: signed(N_BITS-1 downto 0);
  --Complex number z used inside the "while" loop: local variable
  signal Z_RExDP, Z_RExDN, Z_IMxDP, Z_IMxDN: signed(N_BITS-1 downto 0);
  --Write-enable signal
  signal WExD: std_logic;
  --Iteration variable used for color plotting
  signal ITERxDP, ITERxDN, ITEROUTxDP, ITEROUTxDN: unsigned(MEM_DATA_BW-1 downto 0);
  --Intermediate multiplications 
  signal MULRE,MULIM,MULREIM: signed(2*N_BITS-1 downto 0);
  --Truncation multiplications
  signal MULRE_TRUNC, MULIM_TRUNC,MULREIM_TRUNC: signed(N_BITS-1 downto 0);
  --Intermediate addition and truncated intermediate addition
  signal SUM_MULREIM: signed(2*N_BITS-1 downto 0);
  signal SUM_MULREIM_TRUNC: signed(N_BITS+3-1 downto 0); 
--=============================================================================
-- ARCHITECTURE BEGIN
--=============================================================================
begin

  --Counter for X coordinate
    X: process(CLKxCI, RSTxRI) is
    begin
        if RSTxRI = '1' then
            XxDP <= (OTHERS => '0');
        elsif CLKxCI'event and CLKxCI = '1' then
            XxDP <= XxDN;
        end if;
    end process;
    
    --Counter for Y coordinate
    Y: process(CLKxCI, RSTxRI) is
    begin
        if RSTxRI = '1' then
            YxDP <= (OTHERS => '0');
        elsif CLKxCI'event and CLKxCI = '1' then
            YxDP <= YxDN;
        end if;
    end process;
    
    --Counter for real part of c
    C_RE: process(CLKxCI, RSTxRI) is
    begin
        if RSTxRI = '1' then
            C_RExDP <= C_RE_0;
        elsif CLKxCI'event and CLKxCI = '1' then
            C_RExDP <= C_RExDN;
        end if;
    end process;
    
    --Counter for imaginary part of c
    C_IM: process(CLKxCI, RSTxRI) is
    begin
        if RSTxRI = '1' then
            C_IMxDP <= C_IM_0;
        elsif CLKxCI'event and CLKxCI = '1' then
            C_IMxDP <= C_IMxDN;
        end if;
    end process;
    
    
    --Registers for intermediate values in the Mandelbrot algorithm
    --Real part intermediate result
    Z_RE: process(CLKxCI, RSTxRI) is
    begin
        if RSTxRI = '1' then
            Z_RExDP <= C_RE_0;
        elsif CLKxCI'event and CLKxCI = '1' then
            Z_RExDP <= Z_RExDN;
        end if;
    end process;
    --Imaginary part intermidiate result
    Z_IM: process(CLKxCI, RSTxRI) is
    begin
        if RSTxRI = '1' then
            Z_IMxDP <= C_IM_0;
        elsif CLKxCI'event and CLKxCI = '1' then
            Z_IMxDP <= Z_IMxDN;
        end if;
    end process; 
     
    --Register for iterations counter signal
    ITER: process(CLKxCI, RSTxRI) is
    begin
        if RSTxRI = '1' then
            ITERxDP <= (OTHERS => '0');
        elsif CLKxCI'event and CLKxCI = '1' then
            ITERxDP <= ITERxDN;
        end if;
    end process;

--=============================================================================
--=============================================================================
    --Intermediate computation of Mandelbrot multiplications
    --Multiplications needed inside the Mandelbrot loop
    MULRE <= Z_RExDP * Z_RExDP; --Q6.30
    MULIM <= Z_IMxDP * Z_IMxDP; --Q6.30
    MULREIM <= Z_RExDP * Z_IMxDP; --Q6.30
    
    --Truncated results to match signal sizes
    MULRE_TRUNC <= MULRE(2*N_BITS-3-1 downto N_BITS-3); --Q3.15
    MULIM_TRUNC <= MULIM(2*N_BITS-3-1 downto N_BITS-3); --Q3.15
    MULREIM_TRUNC <= MULREIM(2*N_BITS-3-1 downto N_BITS-3); --Q3.15
    
    
    SUM_MULREIM <= MULRE + MULIM;
    SUM_MULREIM_TRUNC <= SUM_MULREIM(SUM_MULREIM'length-1 downto N_frac);
    
    --Transition logic
Mandelbrot: process(all) is 
begin
    
	
    
	--Mandelbrot loop
	if (ITERxDP < MAX_ITER)
	and (SUM_MULREIM_TRUNC<ITER_LIM)
	then 
	    WExD <= '0';    
        --Update of te Mandelbrot values
    	Z_RExDN  <= MULRE_TRUNC	- MULIM_TRUNC + C_RExDP;                     	 
    	Z_IMxDN <= MULREIM_TRUNC + MULREIM_TRUNC + C_IMxDP;
    	
    	--Copy of the current state of the position variables
    	C_RExDN <= C_RExDP;
    	C_IMxDN <= C_IMxDP;
    	XxDN <= XxDP;
    	YxDN <= YxDP;
    	
    	--Incrementation of iterations variable 
    	ITERxDN <= ITERxDP +1;
    	
 	--Else: either divergence or maximum iterations reached
 	else     	
        WExD <= '1'; 
    	--End of screen conditions
    	if (XxDP = HS_DISPLAY-1)
        	and (YxDP = VS_DISPLAY-1) then
   	        --Reset of all position variables
        	C_RExDN <= C_RE_0;
        	C_IMxDN <= C_IM_0;
        	Z_RExDN <= C_RE_0;
        	Z_IMxDN <= C_IM_0;
        	XxDN <= (OTHERS =>'0');
        	YxDN <= (OTHERS =>'0');    
        	--Iteration variable reset to 0
        	ITERxDN <= (OTHERS =>'0');
    	--End of x coordinate and iteration of y coordinate
    	elsif (XxDP = HS_DISPLAY-1) then
        	--reset x to 0
        	XxDN <= (OTHERS =>'0');
        	--increment y by 1
        	YxDN <= YxDP + 1;
        	--reset the real part to -2
        	C_RExDN <= C_RE_0;
        	Z_RExDN <= C_RE_0;
        	--increment the imaginary part by 1 INC
        	C_IMxDN <= C_IMxDP + C_IM_INC;
        	Z_IMxDN <= C_IMxDP + C_IM_INC;
        	--Iteration variable reset to 0
        	ITERxDN <= (OTHERS =>'0');	 
       	--Iteration of x coordinate 
    	else
    	    --Incrementation of C_RE and copy of C_IM
        	C_RExDN <= C_RExDP + C_RE_INC;
        	C_IMxDN <= C_IMxDP;
        	--Incrementation of Z_RE and copy of Z_IM
        	Z_RExDN <= C_RExDP + C_RE_INC;
        	Z_IMxDN <= C_IMxDP;
        	--Incrementation of x and copy of y
        	XxDN <= XxDP + 1;
        	YxDN <= YxDP;
        	--Iteration variable reset to 0
        	ITERxDN <= (OTHERS =>'0');
        	--Enabling of the write-enable signal
    	end if;
	end if;          
end process;


    --Outputs of the Mandelbrot algorithm
    WExSO <= WExD;
    XxDO <= XxDP;
    YxDO <= YxDP;
    ITERxDO <= ITERxDP;
    
end architecture rtl;
--=============================================================================
-- ARCHITECTURE END
--=============================================================================




