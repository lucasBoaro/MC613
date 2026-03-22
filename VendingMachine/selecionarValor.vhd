library ieee;
use ieee.std_logic_1164.all; 

entity selecionarValor is
    port (
        BIN_SWITCH  : in  std_logic_vector(5 downto 0); 
        BIN_VALOR   : out std_logic_vector(7 downto 0) := (others => '0')
    );
end entity selecionarValor;

architecture behavior of selecionarValor is
begin
    with BIN_SWITCH select
        BIN_VALOR <= "00000101" when "000001", -- R$ 0,05
                     "00001010" when "000010", -- R$ 0,10
                     "00011001" when "000100", -- R$ 0,25
                     "00110010" when "001000", -- R$ 0,50
                     "01100100" when "010000", -- R$ 1,00
                     "11001000" when "100000", -- R$ 2,00
                     "00000000" when others;
end architecture;