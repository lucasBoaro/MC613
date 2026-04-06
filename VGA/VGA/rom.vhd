LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.NUMERIC_STD.ALL;

ENTITY rom IS
    PORT (
        addr     : IN STD_LOGIC_VECTOR (5 DOWNTO 0); -- 6 bits para contar de 0 a 63
        data_out : OUT STD_LOGIC_VECTOR (7 DOWNTO 0) -- O índice da cor do pixel
    );
END rom;

ARCHITECTURE behavioral OF rom IS

    -- Matriz de exatos 64 endereços (um sprite 8x8)
    TYPE rom_array IS ARRAY (0 TO 63) OF STD_LOGIC_VECTOR (7 DOWNTO 0);
    
    -- Inicialização do desenho da Alavanca do Switch
    SIGNAL storage: rom_array := (
        -- Linha 0 (Topo)
        x"00", x"00", x"02", x"02", x"02", x"02", x"00", x"00",
        -- Linha 1
        x"00", x"02", x"01", x"01", x"01", x"01", x"02", x"00",
        -- Linha 2
        x"00", x"02", x"01", x"01", x"01", x"01", x"02", x"00",
        -- Linha 3
        x"00", x"02", x"01", x"01", x"01", x"01", x"02", x"00",
        -- Linha 4
        x"00", x"02", x"01", x"01", x"01", x"01", x"02", x"00",
        -- Linha 5
        x"00", x"02", x"01", x"01", x"01", x"01", x"02", x"00",
        -- Linha 6
        x"00", x"02", x"01", x"01", x"01", x"01", x"02", x"00",
        -- Linha 7 (Base)
        x"00", x"00", x"02", x"02", x"02", x"02", x"00", x"00"
    );

BEGIN

    -- Leitura assíncrona: a PPU manda o endereço, a ROM cospe o pixel na mesma hora
    data_out <= storage(TO_INTEGER(UNSIGNED(addr)));

END behavioral;