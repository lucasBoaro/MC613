LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.NUMERIC_STD.ALL;

ENTITY VGA IS
    PORT (
        -- Clock e reset
        pixel_clk    : IN  STD_LOGIC;
        reset_n      : IN  STD_LOGIC;

        -- Cor do pixel atual (vinda da PPU)
        r_in         : IN  STD_LOGIC_VECTOR(7 DOWNTO 0);
        g_in         : IN  STD_LOGIC_VECTOR(7 DOWNTO 0);
        b_in         : IN  STD_LOGIC_VECTOR(7 DOWNTO 0);

        -- Coordenada atual e região visível
        pixel_x      : OUT STD_LOGIC_VECTOR(9 DOWNTO 0);
        pixel_y      : OUT STD_LOGIC_VECTOR(9 DOWNTO 0);
        video_active : OUT STD_LOGIC;

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
END VGA;

ARCHITECTURE Behavioral OF VGA IS

    SIGNAL x_counter : INTEGER RANGE 0 TO 799 := 0;
    SIGNAL y_counter : INTEGER RANGE 0 TO 523 := 0;
    
    -- Sinal interno para reutilizar a condição de área visível
    SIGNAL video_on  : STD_LOGIC;

BEGIN
    -- Processo de contagem de pixels e linhas
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

    -- Sincronismo VGA (640x480 @ 60 Hz)
    VGA_HS      <= '0' WHEN (x_counter >= 656 AND x_counter <= 751) ELSE '1';
    VGA_VS      <= '0' WHEN (y_counter >= 491 AND y_counter <= 492) ELSE '1';
    VGA_BLANK_N <= '0' WHEN (x_counter > 639 OR y_counter > 479) ELSE '1';
    VGA_SYNC_N  <= '1';
    VGA_CLK     <= pixel_clk;

    video_on    <= '1' WHEN (x_counter <= 639 AND y_counter <= 479) ELSE '0';
    video_active <= video_on;

    VGA_R <= r_in WHEN video_on = '1' ELSE (OTHERS => '0');
    VGA_G <= g_in WHEN video_on = '1' ELSE (OTHERS => '0');
    VGA_B <= b_in WHEN video_on = '1' ELSE (OTHERS => '0');

    -- Coordenada do pixel atual
    pixel_x <= STD_LOGIC_VECTOR(TO_UNSIGNED(x_counter, 10));
    pixel_y <= STD_LOGIC_VECTOR(TO_UNSIGNED(y_counter, 10));

END Behavioral;