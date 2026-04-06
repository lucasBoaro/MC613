LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.NUMERIC_STD.ALL;

-- Exemplo de memória ROM
ENTITY rom IS
  PORT (
    addr     : IN STD_LOGIC_VECTOR (7 DOWNTO 0); -- Endereço para ler ou escrever
    data_out : OUT STD_LOGIC_VECTOR (7 DOWNTO 0) -- Dados saindo da memória
  );
END rom;

ARCHITECTURE behavioral OF rom IS
  -- 256 posições de memória de um byte
  TYPE rom_array IS ARRAY (0 TO 255) OF STD_LOGIC_VECTOR (7 DOWNTO 0);
  -- Declaração e inicialização da memória
  SIGNAL storage: rom_array := (
    x"00",x"00",x"00",x"00",-- 0x00: 
    x"00",x"00",x"00",x"00",-- 0x04: 
    x"00",x"00",x"00",x"00",-- 0x08: 
    x"00",x"00",x"00",x"00",-- 0x0C: 
    x"00",x"00",x"00",x"00",-- 0x10: 
    x"00",x"00",x"00",x"00",-- 0x14: 
    x"00",x"00",x"00",x"00",-- 0x18: 
    x"00",x"00",x"00",x"00",-- 0x1C: 
    x"00",x"00",x"00",x"00",-- 0x20: 
    x"00",x"00",x"00",x"00",-- 0x24: 
    x"00",x"00",x"00",x"00",-- 0x28: 
    x"00",x"00",x"00",x"00",-- 0x2C: 
    x"00",x"00",x"00",x"00",-- 0x30: 
    x"00",x"00",x"00",x"00",-- 0x34: 
    x"00",x"00",x"00",x"00",-- 0x38: 
    x"00",x"00",x"00",x"00",-- 0x3C: 
    x"00",x"00",x"00",x"00",-- 0x40: 
    x"00",x"00",x"00",x"00",-- 0x44: 
    x"00",x"00",x"00",x"00",-- 0x48: 
    x"00",x"00",x"00",x"00",-- 0x4C: 
    x"00",x"00",x"00",x"00",-- 0x50: 
    x"00",x"00",x"00",x"00",-- 0x54: 
    x"00",x"00",x"00",x"00",-- 0x58: 
    x"00",x"00",x"00",x"00",-- 0x5C: 
    x"00",x"00",x"00",x"00",
    x"00",x"00",x"00",x"00",
    x"00",x"00",x"00",x"00",
    x"00",x"00",x"00",x"00",
    x"00",x"00",x"00",x"00",
    x"00",x"00",x"00",x"00",
    x"00",x"00",x"00",x"00",
    x"00",x"00",x"00",x"00",
    x"00",x"00",x"00",x"00",
    x"00",x"00",x"00",x"00",
    x"00",x"00",x"00",x"00",
    x"00",x"00",x"00",x"00",
    x"00",x"00",x"00",x"00",
    x"00",x"00",x"00",x"00",
    x"00",x"00",x"00",x"00",
    x"00",x"00",x"00",x"00",
    x"00",x"00",x"00",x"00",
    x"00",x"00",x"00",x"00",
    x"00",x"00",x"00",x"00",
    x"00",x"00",x"00",x"00",
    x"00",x"00",x"00",x"00",
    x"00",x"00",x"00",x"00",
    x"00",x"00",x"00",x"00",
    x"00",x"00",x"00",x"00",
    x"00",x"00",x"00",x"00",
    x"00",x"00",x"00",x"00",
    x"00",x"00",x"00",x"00",
    x"00",x"00",x"00",x"00",
    x"00",x"00",x"00",x"00",
    x"00",x"00",x"00",x"00",
    x"00",x"00",x"00",x"00",
    x"00",x"00",x"00",x"00",
    x"00",x"00",x"00",x"00",
    x"00",x"00",x"00",x"00",
    x"00",x"00",x"00",x"00",
    x"00",x"00",x"00",x"00",
    x"00",x"00",x"00",x"00",
    x"00",x"00",x"00",x"00",
    x"00",x"00",x"00",x"00",
    x"00",x"00",x"00",x"00"
  );
BEGIN
  -- Leitura assíncrona
  data_out <= storage(TO_INTEGER(UNSIGNED(addr)));
END behavioral;