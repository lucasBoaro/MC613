LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.NUMERIC_STD.ALL;

ENTITY VGA_Controller IS
    PORT (
        -- Entradas de Controle de Clock e Reset
        pixel_clk    : IN  STD_LOGIC;                     -- Clock de 25.175 MHz gerado pelo PLL
        reset_n      : IN  STD_LOGIC;                     -- Reset assíncrono (ativo baixo)

        -- Entradas de Cor (vindos da PPU)
        r_in         : IN  STD_LOGIC_VECTOR(7 DOWNTO 0);  -- Intensidade do vermelho do pixel atual
        g_in         : IN  STD_LOGIC_VECTOR(7 DOWNTO 0);  -- Intensidade do verde do pixel atual
        b_in         : IN  STD_LOGIC_VECTOR(7 DOWNTO 0);  -- Intensidade do azul do pixel atual

        -- Saídas de Controle Interno (enviados para a PPU)
        pixel_x      : OUT STD_LOGIC_VECTOR(9 DOWNTO 0);  -- Coordenada X atual
        pixel_y      : OUT STD_LOGIC_VECTOR(9 DOWNTO 0);  -- Coordenada Y atual
        video_active : OUT STD_LOGIC;                     -- '1' se estiver dentro da área visível (Active Video)

        -- Saídas Físicas (conectadas aos pinos da DE1-SoC)
        VGA_R        : OUT STD_LOGIC_VECTOR(7 DOWNTO 0);  -- Saída VGA Vermelha
        VGA_G        : OUT STD_LOGIC_VECTOR(7 DOWNTO 0);  -- Saída VGA Verde
        VGA_B        : OUT STD_LOGIC_VECTOR(7 DOWNTO 0);  -- Saída VGA Azul
        VGA_HS       : OUT STD_LOGIC;                     -- Sincronismo Horizontal
        VGA_VS       : OUT STD_LOGIC;                     -- Sincronismo Vertical
        VGA_BLANK_N  : OUT STD_LOGIC;                     -- Fora da área visível
        VGA_SYNC_N   : OUT STD_LOGIC := '1';              -- Sincronização de vídeo
        VGA_CLK      : OUT STD_LOGIC                      -- Clock do pixel
    );
END VGA_Controller;

ARCHITECTURE Behavioral OF VGA_Controller IS

    SIGNAL x_counter : INTEGER RANGE 0 TO 799 := 0;
    SIGNAL y_counter : INTEGER RANGE 0 TO 523 := 0;
    
    -- SINAL NOVO: Sinal interno para driblar a restrição da porta OUT
    SIGNAL video_on  : STD_LOGIC;

BEGIN

    PROCESS(pixel_clk, reset_n)
    BEGIN
        IF reset_n = '0' THEN
            x_counter <= 0;
            y_counter <= 0;
        ELSIF RISING_EDGE(pixel_clk) THEN
            IF x_counter = 799 THEN
                x_counter <= 0;
                IF y_counter = 523 THEN
                    y_counter <= 0;
                ELSE
                    y_counter <= y_counter + 1;
                END IF;
            ELSE
                x_counter <= x_counter + 1; 
            END IF;
        END IF;
    END PROCESS;

    -- Atribuições de Sincronismo
    VGA_HS      <= '0' WHEN (x_counter >= 656 AND x_counter <= 751) ELSE '1';
    VGA_VS      <= '0' WHEN (y_counter >= 491 AND y_counter <= 492) ELSE '1';
    VGA_BLANK_N <= '0' WHEN (x_counter > 639 OR y_counter > 479) ELSE '1';
    VGA_SYNC_N  <= '1';
    VGA_CLK     <= pixel_clk;

    -- A MÁGICA DA CORREÇÃO: Usar o sinal interno 'video_on'
    video_on    <= '1' WHEN (x_counter <= 639 AND y_counter <= 479) ELSE '0';
    
    -- Passa o valor pro módulo externo (PPU) e usa internamente para as cores
    video_active <= video_on;

    VGA_R <= r_in WHEN video_on = '1' ELSE (OTHERS => '0');
    VGA_G <= g_in WHEN video_on = '1' ELSE (OTHERS => '0');
    VGA_B <= b_in WHEN video_on = '1' ELSE (OTHERS => '0');

    -- Converte os contadores para passar as coordenadas para a PPU
    pixel_x <= STD_LOGIC_VECTOR(TO_UNSIGNED(x_counter, 10));
    pixel_y <= STD_LOGIC_VECTOR(TO_UNSIGNED(y_counter, 10));

END Behavioral;