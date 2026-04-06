LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.NUMERIC_STD.ALL;

ENTITY ControladorVGA IS 
    PORT(
        -- Clocks e placa
        CLK_50       : IN  STD_LOGIC;
        
        -- Entradas Físicas da Placa DE1-SoC
        SW           : IN  STD_LOGIC_VECTOR(9 DOWNTO 0);  -- Os 10 Switches físicos
        KEY          : IN  STD_LOGIC_VECTOR(3 DOWNTO 0);  -- Os 4 Botões físicos

        -- Saídas para o Monitor
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

    -- Sinais de Clock
    SIGNAL pixel_clk    : STD_LOGIC;
    
    -- Sinais de Sincronismo (VGA -> PPU)
    SIGNAL pixel_x      : STD_LOGIC_VECTOR(9 DOWNTO 0);
    SIGNAL pixel_y      : STD_LOGIC_VECTOR(9 DOWNTO 0);
    SIGNAL video_active : STD_LOGIC;
    
    -- Sinais de Cor (PPU -> VGA)
    SIGNAL ppu_r        : STD_LOGIC_VECTOR(7 DOWNTO 0);
    SIGNAL ppu_g        : STD_LOGIC_VECTOR(7 DOWNTO 0);
    SIGNAL ppu_b        : STD_LOGIC_VECTOR(7 DOWNTO 0);

    -- ==========================================
    -- DECLARAÇÃO DO COMPONENTE PLL (Novo!)
    -- ==========================================
    COMPONENT pll IS
        PORT (
            refclk   : IN  STD_LOGIC := '0';
            rst      : IN  STD_LOGIC := '0';
            outclk_0 : OUT STD_LOGIC;
            locked   : OUT STD_LOGIC
        );
    END COMPONENT;

BEGIN

    -- 1. Gerador de Clock (Coração do sistema)
    -- Tiramos o "entity work." e chamamos o componente direto
    instanciaPLL: pll
        port map (
            refclk   => CLK_50,
            rst      => '0',
            outclk_0 => pixel_clk,
            locked   => open
        );

    -- 2. A sua PPU (O Cérebro Gráfico)
    instancia_PPU: entity work.PPU
        port map (
            clk          => pixel_clk,  -- Usamos o clock de pixel para ficar tudo em sincronia
            reset_n      => '1',        -- Reset desativado por enquanto
            switches     => SW,         -- Ligando as chaves físicas na PPU
            buttons      => KEY,        -- Ligando os botões físicos na PPU
            
            -- Recebendo as coordenadas do VGA
            pixel_x      => pixel_x,
            pixel_y      => pixel_y,
            video_active => video_active,
            
            -- Enviando as cores geradas para o cabo
            r            => ppu_r,
            g            => ppu_g,
            b            => ppu_b
        );

    -- 3. O Controlador VGA (A Placa de Vídeo)
    instanciaVGA_Controler: entity work.VGA_Controller
        port map (
            r_in         => ppu_r,      -- Agora recebe a cor da PPU!
            g_in         => ppu_g,      -- Agora recebe a cor da PPU!
            b_in         => ppu_b,      -- Agora recebe a cor da PPU!
            
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
            
            -- Devolve as coordenadas para a PPU ler
            pixel_x      => pixel_x,
            pixel_y      => pixel_y,
            video_active => video_active
        );

END architecture;