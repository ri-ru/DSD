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
-- State machine
  type state_t is (INIT_PIXEL, ITERATE, WRITE_PIXEL);
  signal state : state_t;

  -- Coordinates
  signal x_cnt : unsigned(COORD_BW - 1 downto 0);
  signal y_cnt : unsigned(COORD_BW - 1 downto 0);

  -- Mandelbrot fixed-point variables
  subtype q_t  is signed(N_BITS-1 downto 0);
  subtype q2_t is signed(2*N_BITS-1 downto 0);

  signal c_re, c_im : q_t;
  signal z_re, z_im : q_t;

  signal iter_cnt : unsigned(MEM_DATA_BW-1 downto 0);

begin

  -----------------------------------------------------------------------------
  process(CLKxCI, RSTxRI)
    
    variable z_re_v, z_im_v : q_t;
    variable z_re_sq_v, z_im_sq_v, z_re_im_v : q2_t;
    variable iter_v : unsigned(MEM_DATA_BW-1 downto 0);
    variable c_re_v, c_im_v : q_t;
  begin
    z_re_v := z_re;
    z_im_v := z_im;
    iter_v := iter_cnt;
    c_re_v := c_re;
    c_im_v := c_im;

    if rising_edge(CLKxCI) then
      if RSTxRI = '1' then
        -- Reset all signals
        state    <= INIT_PIXEL;
        x_cnt    <= (others => '0');
        y_cnt    <= (others => '0');
        c_re     <= C_RE_0;
        c_im     <= C_IM_0;
        z_re     <= (others => '0');
        z_im     <= (others => '0');
        iter_cnt <= (others => '0');
        WExSO    <= '0';

      else
        WExSO <= '0';

        case state is

          -------------------------------------------------------------------
          when INIT_PIXEL =>
              z_re     <= (others => '0');
              z_im     <= (others => '0');
              iter_cnt <= (others => '0');
              state    <= ITERATE;
            
          -------------------------------------------------------------------
          when ITERATE =>
            -- Compute squares and product
            z_re_sq_v  := resize(z_re_v * z_re_v, 2*N_BITS);
            z_im_sq_v  := resize(z_im_v * z_im_v, 2*N_BITS);
            z_re_im_v  := resize(z_re_v * z_im_v, 2*N_BITS);

            -- Escape check
            if (shift_right(z_re_sq_v + z_im_sq_v, N_FRAC) >=
                 to_signed(ITER_LIM, 2*N_BITS)) or
               (iter_v = to_unsigned(MAX_ITER, MEM_DATA_BW)) then
              state <= WRITE_PIXEL;
            else
              z_re_v := resize(
                          shift_right(z_re_sq_v - z_im_sq_v, N_FRAC),
                          N_BITS) + c_re_v;
              z_im_v := resize(
                          shift_right(z_re_im_v sll 1, N_FRAC),
                          N_BITS) + c_im_v;
              iter_v := iter_v + 1;
            end if;


            -- Update signals
            z_re <= z_re_v;
            z_im <= z_im_v;
            iter_cnt <= iter_v;

          -------------------------------------------------------------------
          when WRITE_PIXEL =>
            -- Output pixel
            XxDO    <= x_cnt;
            YxDO    <= y_cnt;
            ITERxDO <= iter_cnt;
            WExSO   <= '1';

            -- Advance pixel coordinates
            if x_cnt = to_unsigned(HS_DISPLAY-1, COORD_BW) then
              x_cnt <= (others => '0');
              c_re <= C_RE_0;
              if y_cnt = to_unsigned(VS_DISPLAY-1, COORD_BW) then
                y_cnt <= (others => '0');
                c_im <= C_IM_0;
              else
                y_cnt <= y_cnt + 1;
                c_im <= c_im + C_IM_INC;
              end if;
            else
              x_cnt <= x_cnt + 1;
              c_re <= c_re + C_RE_INC;
            end if;

            state <= INIT_PIXEL;

        end case;
      end if;
    end if;
  end process;

end architecture rtl;
--=============================================================================
-- ARCHITECTURE END
--=============================================================================
