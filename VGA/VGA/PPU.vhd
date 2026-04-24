LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.NUMERIC_STD.ALL;

ENTITY PPU IS
  PORT (
    clk          : IN  STD_LOGIC;
    reset_n      : IN  STD_LOGIC;
    switches     : IN  STD_LOGIC_VECTOR(9 DOWNTO 0);
    buttons      : IN  STD_LOGIC_VECTOR(3 DOWNTO 0);
    pixel_x      : IN  STD_LOGIC_VECTOR(9 DOWNTO 0);
    pixel_y      : IN  STD_LOGIC_VECTOR(9 DOWNTO 0);
    video_active : IN  STD_LOGIC;
    r            : OUT STD_LOGIC_VECTOR(7 DOWNTO 0);
    g            : OUT STD_LOGIC_VECTOR(7 DOWNTO 0);
    b            : OUT STD_LOGIC_VECTOR(7 DOWNTO 0)
  );
END PPU;

ARCHITECTURE behavior OF PPU IS

    CONSTANT BG_COLS : INTEGER := 80;

    COMPONENT rom IS
        PORT (
            bank_sel : IN STD_LOGIC_VECTOR (1 DOWNTO 0);
            addr     : IN STD_LOGIC_VECTOR (12 DOWNTO 0);
            data_out : OUT STD_LOGIC_VECTOR (7 DOWNTO 0)
        );
    END COMPONENT;

    SIGNAL bg_r : STD_LOGIC_VECTOR(7 DOWNTO 0);
    SIGNAL bg_g : STD_LOGIC_VECTOR(7 DOWNTO 0);
    SIGNAL bg_b : STD_LOGIC_VECTOR(7 DOWNTO 0);

    SIGNAL sprite_r                 : STD_LOGIC_VECTOR(7 DOWNTO 0);
    SIGNAL sprite_g                 : STD_LOGIC_VECTOR(7 DOWNTO 0);
    SIGNAL sprite_b                 : STD_LOGIC_VECTOR(7 DOWNTO 0);
    SIGNAL sprite_active            : STD_LOGIC;

    SIGNAL bg_data : STD_LOGIC_VECTOR(7 DOWNTO 0);
    SIGNAL bg_addr : STD_LOGIC_VECTOR(12 DOWNTO 0);

    SIGNAL pixel_x_unsigned            : UNSIGNED(9 DOWNTO 0);
    SIGNAL pixel_y_unsigned            : UNSIGNED(9 DOWNTO 0);
    SIGNAL sprite_y                    : UNSIGNED(9 DOWNTO 0);

    SIGNAL sprite_id                  : STD_LOGIC_VECTOR(7 DOWNTO 0);
    SIGNAL sprite_switch_on           : STD_LOGIC;

    SIGNAL bg_col : INTEGER RANGE 0 TO 79;
    SIGNAL bg_row : INTEGER RANGE 0 TO 59;
    SIGNAL bg_idx : INTEGER RANGE 0 TO 4799;
    SIGNAL bg_id  : STD_LOGIC_VECTOR(7 DOWNTO 0);

    SIGNAL botoes_hit     : STD_LOGIC_VECTOR(3 DOWNTO 0);
    SIGNAL btn_rom_data   : STD_LOGIC_VECTOR(7 DOWNTO 0);
    SIGNAL btn_rom_addr   : STD_LOGIC_VECTOR(12 DOWNTO 0);
    SIGNAL btn_r, btn_g, btn_b : STD_LOGIC_VECTOR(7 DOWNTO 0);
    SIGNAL btn_active     : STD_LOGIC;
    SIGNAL pixel_x_btn_offset : UNSIGNED(9 DOWNTO 0);

BEGIN

    -- Conversao das coordenadas atuais para unsigned.
    pixel_x_unsigned <= UNSIGNED(pixel_x);
    pixel_y_unsigned <= UNSIGNED(pixel_y);

    background_rom_instance : rom
        PORT MAP (
            bank_sel => "00",
            addr     => bg_addr,
            data_out => bg_data
        );

    button_rom_instance : rom
        PORT MAP (
            bank_sel => "10",
            addr     => btn_rom_addr,
            data_out => btn_rom_data
        );


--===========================DEFINIÇÃO: BOTOES==============================================
    -- 4 botoes de 56x56 (sprite 7x7 escalado por 8), alinhados horizontalmente.
    botoes_hit(0) <= '1' WHEN (pixel_x_unsigned >= 160 AND pixel_x_unsigned < 216) AND (pixel_y_unsigned >= 280 AND pixel_y_unsigned < 336) ELSE '0';
    botoes_hit(1) <= '1' WHEN (pixel_x_unsigned >= 256 AND pixel_x_unsigned < 312) AND (pixel_y_unsigned >= 280 AND pixel_y_unsigned < 336) ELSE '0';
    botoes_hit(2) <= '1' WHEN (pixel_x_unsigned >= 352 AND pixel_x_unsigned < 408) AND (pixel_y_unsigned >= 280 AND pixel_y_unsigned < 336) ELSE '0';
    botoes_hit(3) <= '1' WHEN (pixel_x_unsigned >= 448 AND pixel_x_unsigned < 504) AND (pixel_y_unsigned >= 280 AND pixel_y_unsigned < 336) ELSE '0';

    pixel_x_btn_offset <= pixel_x_unsigned - 160 WHEN botoes_hit(0) = '1' ELSE
                          pixel_x_unsigned - 256 WHEN botoes_hit(1) = '1' ELSE
                          pixel_x_unsigned - 352 WHEN botoes_hit(2) = '1' ELSE
                          pixel_x_unsigned - 448 WHEN botoes_hit(3) = '1' ELSE (OTHERS => '0');

    -- Calculo do endereco da ROM: (Y_offset * 7) + X_offset
    btn_rom_addr <= STD_LOGIC_VECTOR(RESIZE(((pixel_y_unsigned - 280)/8 * 7) + (pixel_x_btn_offset/8), 13));


--=========================DEFINIÇÃO: SPRITES================================================

    -- Identifica se a posição atual é a de um sprite
    sprite_id <=
        x"00" WHEN (pixel_x_unsigned >= 64  AND pixel_x_unsigned < 80)  ELSE
        x"01" WHEN (pixel_x_unsigned >= 128 AND pixel_x_unsigned < 144) ELSE
        x"02" WHEN (pixel_x_unsigned >= 192 AND pixel_x_unsigned < 208) ELSE
        x"03" WHEN (pixel_x_unsigned >= 256 AND pixel_x_unsigned < 272) ELSE
        x"04" WHEN (pixel_x_unsigned >= 320 AND pixel_x_unsigned < 336) ELSE
        x"05" WHEN (pixel_x_unsigned >= 384 AND pixel_x_unsigned < 400) ELSE
        x"06" WHEN (pixel_x_unsigned >= 448 AND pixel_x_unsigned < 464) ELSE
        x"07" WHEN (pixel_x_unsigned >= 512 AND pixel_x_unsigned < 528) ELSE
        x"08" WHEN (pixel_x_unsigned >= 576 AND pixel_x_unsigned < 592) ELSE
        x"FF";
    
    -- Se está na faixa de um sprite, verifica o valor do switch correspondente 
    sprite_switch_on <=
        switches(9) WHEN sprite_id = x"00" ELSE
        switches(8) WHEN sprite_id = x"01" ELSE
        switches(7) WHEN sprite_id = x"02" ELSE
        switches(6) WHEN sprite_id = x"03" ELSE
        switches(5) WHEN sprite_id = x"04" ELSE
        switches(4) WHEN sprite_id = x"05" ELSE
        switches(3) WHEN sprite_id = x"06" ELSE
        switches(2) WHEN sprite_id = x"07" ELSE
        switches(1) WHEN sprite_id = x"08" ELSE
        '0';

    -- Define a posição Y do sprite, linha 160 se ligado, linha 192 se desligado
    sprite_y <= TO_UNSIGNED(160, 10) WHEN sprite_switch_on = '1' ELSE TO_UNSIGNED(192, 10);

    -- Sprite_id verificou a posição horizontal, agora Sprite_active verifica se o pixel atual está na faixa vertical do sprite
    sprite_active <= '1' WHEN (sprite_id /= x"FF") AND (pixel_y_unsigned >= sprite_y) AND (pixel_y_unsigned < sprite_y + 16) ELSE '0';

    sprite_r <= x"FF" WHEN sprite_active = '1' ELSE x"00";
    sprite_g <= x"00";
    sprite_b <= x"00";

--=========================DEFINIÇÃO: BACKGROUND================================================
    bg_col <= TO_INTEGER(pixel_x_unsigned(9 DOWNTO 3));
    bg_row <= TO_INTEGER(pixel_y_unsigned(9 DOWNTO 3));
    bg_idx <= (bg_row * BG_COLS) + bg_col;
    bg_addr <= STD_LOGIC_VECTOR(TO_UNSIGNED(bg_idx, 13));
    bg_id <= bg_data;

    -- Paleta do fundo.
    WITH bg_id SELECT
        bg_r <= x"4A" WHEN x"00",
                x"66" WHEN x"01",
                x"8D" WHEN x"02",
                x"00" WHEN x"03",
                x"00" WHEN OTHERS;

    WITH bg_id SELECT
        bg_g <= x"4D" WHEN x"00",
                x"63" WHEN x"01",
                x"8A" WHEN x"02",
                x"00" WHEN x"03",
                x"00" WHEN OTHERS;

    WITH bg_id SELECT
        bg_b <= x"8B" WHEN x"00",
                x"62" WHEN x"01",
                x"94" WHEN x"02",
                x"00" WHEN x"03",
                x"00" WHEN OTHERS;

--=================================LÓGICA: BOTÕES===============================================

    PROCESS(botoes_hit, buttons, btn_rom_data)
    BEGIN
        btn_r <= x"00"; btn_g <= x"00"; btn_b <= x"00"; btn_active <= '0';
        
        IF (botoes_hit /= "0000") AND (btn_rom_data = x"01") THEN
            btn_active <= '1';
            
                IF (botoes_hit(0) = '1' AND buttons(3) = '0') OR 
                    (botoes_hit(1) = '1' AND buttons(2) = '0') OR
                    (botoes_hit(2) = '1' AND buttons(1) = '0') OR
                    (botoes_hit(3) = '1' AND buttons(0) = '0') THEN
                btn_g <= x"FF"; -- Verde
            ELSE
                btn_r <= x"FF"; -- Vermelho
            END IF;
        END IF;
    END PROCESS;

--=================================COMPOSIÇÃO FINAL===============================================
    r <= sprite_r WHEN sprite_active = '1' ELSE btn_r WHEN btn_active = '1' ELSE bg_r;
    g <= sprite_g WHEN sprite_active = '1' ELSE btn_g WHEN btn_active = '1' ELSE bg_g;
    b <= sprite_b WHEN sprite_active = '1' ELSE btn_b WHEN btn_active = '1' ELSE bg_b;

END behavior;
