LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.NUMERIC_STD.ALL;

ENTITY ControladorVGA IS 
    PORT(
        -- Clock principal da placa
        CLK_50       : IN  STD_LOGIC;
        
        -- Entradas da placa
        SW           : IN  STD_LOGIC_VECTOR(9 DOWNTO 0);
        KEY          : IN  STD_LOGIC_VECTOR(3 DOWNTO 0);

        -- Saídas VGA
        VGA_R        : OUT STD_LOGIC_VECTOR(7 DOWNTO 0);  
        VGA_G        : OUT STD_LOGIC_VECTOR(7 DOWNTO 0);  
        VGA_B        : OUT STD_LOGIC_VECTOR(7 DOWNTO 0);  
        VGA_HS       : OUT STD_LOGIC;                     
        VGA_VS       : OUT STD_LOGIC;                     
        VGA_BLANK_N  : OUT STD_LOGIC;  
        VGA_SYNC_N   : OUT STD_LOGIC := '1';              
        VGA_CLK      : OUT STD_LOGIC                   
    );
END ControladorVGA;

ARCHITECTURE Behavioral OF ControladorVGA IS

    -- Sinais internos
    SIGNAL pixel_clk    : STD_LOGIC;
    
    SIGNAL pixel_x      : STD_LOGIC_VECTOR(9 DOWNTO 0);
    SIGNAL pixel_y      : STD_LOGIC_VECTOR(9 DOWNTO 0);
    SIGNAL video_active : STD_LOGIC;
    
    SIGNAL ppu_r        : STD_LOGIC_VECTOR(7 DOWNTO 0);
    SIGNAL ppu_g        : STD_LOGIC_VECTOR(7 DOWNTO 0);
    SIGNAL ppu_b        : STD_LOGIC_VECTOR(7 DOWNTO 0);

    -- PLL para gerar o clock de pixel
    COMPONENT pll IS
        PORT (
            refclk   : IN  STD_LOGIC := '0';
            rst      : IN  STD_LOGIC := '0';
            outclk_0 : OUT STD_LOGIC;
            locked   : OUT STD_LOGIC
        );
    END COMPONENT;

BEGIN

    -- 1) Gera clock de pixel
    instanciaPLL: pll
        port map (
            refclk   => CLK_50,
            rst      => '0',
            outclk_0 => pixel_clk,
            locked   => open
        );

    -- 2) PPU gera a cor de cada pixel
    instancia_PPU: entity work.PPU
        port map (
            clk          => pixel_clk,
            reset_n      => '1',
            switches     => SW,
            buttons      => KEY,
            pixel_x      => pixel_x,
            pixel_y      => pixel_y,
            video_active => video_active,
            r            => ppu_r,
            g            => ppu_g,
            b            => ppu_b
        );

    -- 3) Controlador VGA envia sincronismo e vídeo
    instanciaVGA_Controler: entity work.VGA_Controller
        port map (
            r_in         => ppu_r,
            g_in         => ppu_g,
            b_in         => ppu_b,
            
            pixel_clk    => pixel_clk,
            reset_n      => '1', 
           
            VGA_R        => VGA_R,
            VGA_G        => VGA_G,
            VGA_B        => VGA_B,
            VGA_HS       => VGA_HS,
            VGA_VS       => VGA_VS,
            VGA_BLANK_N  => VGA_BLANK_N,
            VGA_SYNC_N   => VGA_SYNC_N,
            VGA_CLK      => VGA_CLK,
            
            pixel_x      => pixel_x,
            pixel_y      => pixel_y,
            video_active => video_active
        );

    instancia_PPU: entity work.PPU
        port map (
            clk          => pixel_clk,
            reset_n      => '1',
            switches     => SW,     
            buttons      => KEY,    
            pixel_x      => pixel_x,
            pixel_y      => pixel_y,
            video_active => video_active,
            r            => ppu_r,
            g            => ppu_g,
            b            => ppu_b
        );

END architecture;