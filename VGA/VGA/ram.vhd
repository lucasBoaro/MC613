LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.NUMERIC_STD.ALL;

-- Exemplo de memória RAM de uma porta (single-port RAM)
ENTITY ram IS
  PORT (
    clock    : IN STD_LOGIC;                     -- Clock da memória
    addr     : IN STD_LOGIC_VECTOR (7 DOWNTO 0); -- Endereço para ler ou escrever
    data_in  : IN STD_LOGIC_VECTOR (7 DOWNTO 0); -- Dados para escrever na memória
    wr_en    : IN STD_LOGIC;                     -- Seletor de operação de escrita
    data_out : OUT STD_LOGIC_VECTOR (7 DOWNTO 0) -- Dados saindo da memória
  );
END ram;

ARCHITECTURE behavioral OF ram IS
  -- 256 posições de memória de um byte
  TYPE ram_array IS ARRAY (0 TO 255) OF STD_LOGIC_VECTOR (7 DOWNTO 0);
  -- Declaração da memória
  -- Você pode inicializar a memória com valores adicionando := (x"C0",x"FF",x"EE",x"00", ...)
  SIGNAL storage: ram_array;
  -- Você pode inicializar a memória usando um arquivo .mif
  -- ATTRIBUTE init_file : STRING;
  -- ATTRIBUTE init_file OF storage :
  --   SIGNAL IS "<caminho_para_o_arquivo>/ram_init_file.mif";
BEGIN
  PROCESS(clock)
  BEGIN
    -- Escrita síncrona
    IF (RISING_EDGE(clock)) THEN
      IF (wr_en = '1') THEN
        storage(TO_INTEGER(UNSIGNED(addr))) <= data_in;
      END IF;
    END IF;
  END PROCESS;

  -- Leitura assíncrona
  data_out <= storage(TO_INTEGER(UNSIGNED(addr)));
END behavioral;