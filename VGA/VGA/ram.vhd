LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.NUMERIC_STD.ALL;

-- RAM de porta unica.
ENTITY ram IS
  PORT (
    -- Entradas e saida da memoria
    clock    : IN STD_LOGIC;
    addr     : IN STD_LOGIC_VECTOR (7 DOWNTO 0);
    data_in  : IN STD_LOGIC_VECTOR (7 DOWNTO 0);
    wr_en    : IN STD_LOGIC;
    data_out : OUT STD_LOGIC_VECTOR (7 DOWNTO 0)
  );
END ram;

ARCHITECTURE behavioral OF ram IS
  -- 256 posicoes de 8 bits.
  TYPE ram_array IS ARRAY (0 TO 255) OF STD_LOGIC_VECTOR (7 DOWNTO 0);
  SIGNAL storage: ram_array;
BEGIN
  -- Escrita sincronizada ao clock.
  PROCESS(clock)
  BEGIN
    IF (RISING_EDGE(clock)) THEN
      IF (wr_en = '1') THEN
        storage(TO_INTEGER(UNSIGNED(addr))) <= data_in;
      END IF;
    END IF;
  END PROCESS;

  -- Leitura combinacional.
  data_out <= storage(TO_INTEGER(UNSIGNED(addr)));
END behavioral;