library ieee;
use ieee.std_logic_1164.all; 

entity selecionarValor is
    port (
        KEY_CONFIRM : in  std_logic;                    
        BIN_SWITCH  : in  std_logic_vector(5 downto 0); 
        BIN_VALOR   : out std_logic_vector(7 downto 0) := (others => '0')
    );
end entity selecionarValor;

architecture behavior of selecionarValor is
begin
    process(KEY_CONFIRM)
    begin
        -- Detecta o momento em que o botão é solto (Active Low na DE0-CV)
        if rising_edge(KEY_CONFIRM) then 
            case BIN_SWITCH is
                when "000001" => BIN_VALOR <= "00000101"; -- R$ 0,05 (5 em decimal)
                when "000010" => BIN_VALOR <= "00001010"; -- R$ 0,10 (10)
                when "000100" => BIN_VALOR <= "00011001"; -- R$ 0,25 (25)
                when "001000" => BIN_VALOR <= "00110010"; -- R$ 0,50 (50)
                when "010000" => BIN_VALOR <= "01100100"; -- R$ 1,00 (100)
                when "100000" => BIN_VALOR <= "11001000"; -- R$ 2,00 (200)
                when others   => BIN_VALOR <= (others => '0');
            end case;
        end if;
    end process;

end architecture;