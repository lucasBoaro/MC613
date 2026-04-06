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

    CONSTANT BACKGROUND_TILE_COLUMNS : INTEGER := 80;

    COMPONENT rom IS
        PORT (
            bank_sel : IN STD_LOGIC;
            addr     : IN STD_LOGIC_VECTOR (12 DOWNTO 0);
            data_out : OUT STD_LOGIC_VECTOR (7 DOWNTO 0)
        );
    END COMPONENT;

    COMPONENT ram IS
        PORT (
            clock    : IN STD_LOGIC;
            wr_en    : IN STD_LOGIC;
            addr     : IN STD_LOGIC_VECTOR (7 DOWNTO 0);
            data_in  : IN STD_LOGIC_VECTOR (7 DOWNTO 0);
            data_out : OUT STD_LOGIC_VECTOR (7 DOWNTO 0)
        );
    END COMPONENT;

    SIGNAL background_red_channel   : STD_LOGIC_VECTOR(7 DOWNTO 0);
    SIGNAL background_green_channel : STD_LOGIC_VECTOR(7 DOWNTO 0);
    SIGNAL background_blue_channel  : STD_LOGIC_VECTOR(7 DOWNTO 0);

    SIGNAL sprite_red_channel       : STD_LOGIC_VECTOR(7 DOWNTO 0);
    SIGNAL sprite_green_channel     : STD_LOGIC_VECTOR(7 DOWNTO 0);
    SIGNAL sprite_blue_channel      : STD_LOGIC_VECTOR(7 DOWNTO 0);
    SIGNAL sprite_is_active         : STD_LOGIC;

    SIGNAL background_rom_data      : STD_LOGIC_VECTOR(7 DOWNTO 0);
    SIGNAL sprite_rom_data          : STD_LOGIC_VECTOR(7 DOWNTO 0);
    SIGNAL background_rom_address   : STD_LOGIC_VECTOR(12 DOWNTO 0);
    SIGNAL sprite_rom_address       : STD_LOGIC_VECTOR(12 DOWNTO 0);

    SIGNAL object_attribute_write_enable : STD_LOGIC;
    SIGNAL object_attribute_address_bus  : STD_LOGIC_VECTOR(7 DOWNTO 0);
    SIGNAL object_attribute_data_in      : STD_LOGIC_VECTOR(7 DOWNTO 0);
    SIGNAL object_attribute_data_out     : STD_LOGIC_VECTOR(7 DOWNTO 0);

    SIGNAL sprite_scan_index           : INTEGER RANGE 0 TO 9 := 0;
    SIGNAL sprite_write_address_index  : INTEGER RANGE 0 TO 9 := 0;
    SIGNAL sprite_read_address_bus     : STD_LOGIC_VECTOR(7 DOWNTO 0);

    SIGNAL pixel_x_unsigned            : UNSIGNED(9 DOWNTO 0);
    SIGNAL pixel_y_unsigned            : UNSIGNED(9 DOWNTO 0);
    SIGNAL current_sprite_y_unsigned   : UNSIGNED(9 DOWNTO 0);
    SIGNAL pixel_offset_inside_sprite_x : UNSIGNED(9 DOWNTO 0);
    SIGNAL pixel_offset_inside_sprite_y : UNSIGNED(9 DOWNTO 0);

    SIGNAL selected_sprite_identifier  : STD_LOGIC_VECTOR(7 DOWNTO 0);
    SIGNAL selected_sprite_origin_x    : UNSIGNED(9 DOWNTO 0);
    SIGNAL selected_sprite_is_hit      : STD_LOGIC;

    SIGNAL background_tile_column      : INTEGER RANGE 0 TO 79;
    SIGNAL background_tile_row         : INTEGER RANGE 0 TO 59;
    SIGNAL background_tile_linear_index: INTEGER RANGE 0 TO 4799;
    SIGNAL background_tile_identifier  : STD_LOGIC_VECTOR(7 DOWNTO 0);

BEGIN

    -- Conversao das coordenadas atuais para unsigned.
    pixel_x_unsigned <= UNSIGNED(pixel_x);
    pixel_y_unsigned <= UNSIGNED(pixel_y);

    -- Selecao do sprite pela faixa horizontal da tela.
    selected_sprite_identifier <=
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

    -- Posicao X de referencia para cada sprite.
    selected_sprite_origin_x <=
        TO_UNSIGNED(64, 10) WHEN selected_sprite_identifier = x"00" ELSE
        TO_UNSIGNED(128, 10) WHEN selected_sprite_identifier = x"01" ELSE
        TO_UNSIGNED(192, 10) WHEN selected_sprite_identifier = x"02" ELSE
        TO_UNSIGNED(256, 10) WHEN selected_sprite_identifier = x"03" ELSE
        TO_UNSIGNED(320, 10) WHEN selected_sprite_identifier = x"04" ELSE
        TO_UNSIGNED(384, 10) WHEN selected_sprite_identifier = x"05" ELSE
        TO_UNSIGNED(448, 10) WHEN selected_sprite_identifier = x"06" ELSE
        TO_UNSIGNED(512, 10) WHEN selected_sprite_identifier = x"07" ELSE
        TO_UNSIGNED(576, 10) WHEN selected_sprite_identifier = x"08" ELSE
        TO_UNSIGNED(0, 10);

    sprite_read_address_bus <= selected_sprite_identifier WHEN selected_sprite_identifier /= x"FF" ELSE x"00";
    current_sprite_y_unsigned <= RESIZE(UNSIGNED(object_attribute_data_out), 10);

    -- Teste de cobertura vertical do sprite (16x16).
    selected_sprite_is_hit <= '1'
        WHEN (selected_sprite_identifier /= x"FF")
         AND (pixel_y_unsigned >= current_sprite_y_unsigned)
         AND (pixel_y_unsigned < current_sprite_y_unsigned + 16)
        ELSE '0';

    pixel_offset_inside_sprite_x <= pixel_x_unsigned - selected_sprite_origin_x;
    pixel_offset_inside_sprite_y <= pixel_y_unsigned - current_sprite_y_unsigned;

    -- Endereco do pixel dentro do sprite na ROM.
    sprite_rom_address <= (12 DOWNTO 8 => '0')
        & STD_LOGIC_VECTOR(pixel_offset_inside_sprite_y(3 DOWNTO 0) & pixel_offset_inside_sprite_x(3 DOWNTO 0))
        WHEN selected_sprite_is_hit = '1' ELSE (OTHERS => '0');

    sprite_is_active <= '1' WHEN (selected_sprite_is_hit = '1') AND (sprite_rom_data /= x"00") ELSE '0';

    sprite_red_channel   <= x"FF" WHEN sprite_rom_data /= x"00" ELSE x"00";
    sprite_green_channel <= x"00";
    sprite_blue_channel  <= x"00";

    -- Atualizacao das posicoes Y na OAM durante o blanking.
    PROCESS(clk, reset_n)
    BEGIN
        IF reset_n = '0' THEN
            sprite_scan_index <= 0;
            object_attribute_write_enable <= '0';
        ELSIF RISING_EDGE(clk) THEN
            IF video_active = '0' THEN
                object_attribute_write_enable <= '1';
                sprite_write_address_index <= sprite_scan_index;

                IF switches(9 - sprite_scan_index) = '1' THEN
                    object_attribute_data_in <= STD_LOGIC_VECTOR(TO_UNSIGNED(160, 8));
                ELSE
                    object_attribute_data_in <= STD_LOGIC_VECTOR(TO_UNSIGNED(192, 8));
                END IF;

                IF sprite_scan_index = 9 THEN
                    sprite_scan_index <= 0;
                ELSE
                    sprite_scan_index <= sprite_scan_index + 1;
                END IF;
            ELSE
                object_attribute_write_enable <= '0';
            END IF;
        END IF;
    END PROCESS;

    object_attribute_address_bus <= STD_LOGIC_VECTOR(TO_UNSIGNED(sprite_write_address_index, 8))
        WHEN object_attribute_write_enable = '1' ELSE sprite_read_address_bus;

    -- Leitura do tile de fundo a partir da coordenada de tela.
    background_tile_column <= TO_INTEGER(pixel_x_unsigned(9 DOWNTO 3));
    background_tile_row <= TO_INTEGER(pixel_y_unsigned(9 DOWNTO 3));
    background_tile_linear_index <= (background_tile_row * BACKGROUND_TILE_COLUMNS) + background_tile_column;
    background_rom_address <= STD_LOGIC_VECTOR(TO_UNSIGNED(background_tile_linear_index, 13));
    background_tile_identifier <= background_rom_data;

    -- Paleta do fundo (IDs 0..3).
    WITH background_tile_identifier SELECT
        background_red_channel <= x"4A" WHEN x"00",
                                  x"66" WHEN x"01",
                                  x"8D" WHEN x"02",
                                  x"00" WHEN x"03",
                                  x"00" WHEN OTHERS;

    WITH background_tile_identifier SELECT
        background_green_channel <= x"4D" WHEN x"00",
                                    x"63" WHEN x"01",
                                    x"8A" WHEN x"02",
                                    x"00" WHEN x"03",
                                    x"00" WHEN OTHERS;

    WITH background_tile_identifier SELECT
        background_blue_channel <= x"8B" WHEN x"00",
                                   x"62" WHEN x"01",
                                   x"94" WHEN x"02",
                                   x"00" WHEN x"03",
                                   x"00" WHEN OTHERS;

    -- Composicao final: sprite sobre fundo.
    r <= sprite_red_channel WHEN sprite_is_active = '1' ELSE background_red_channel;
    g <= sprite_green_channel WHEN sprite_is_active = '1' ELSE background_green_channel;
    b <= sprite_blue_channel WHEN sprite_is_active = '1' ELSE background_blue_channel;

    -- Banco 0: fundo.
    background_rom_instance : rom
        PORT MAP (
            bank_sel => '0',
            addr     => background_rom_address,
            data_out => background_rom_data
        );

    -- Banco 1: sprite.
    sprite_rom_instance : rom
        PORT MAP (
            bank_sel => '1',
            addr     => sprite_rom_address,
            data_out => sprite_rom_data
        );

    -- RAM de atributos de sprite (posicao Y).
    object_attribute_memory_instance : ram
        PORT MAP (
            clock    => clk,
            wr_en    => object_attribute_write_enable,
            addr     => object_attribute_address_bus,
            data_in  => object_attribute_data_in,
            data_out => object_attribute_data_out
        );

END behavior;
