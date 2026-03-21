library ieee;
use ieee.std_logic_1164.all; 

entity seletor_produto is
    port (
        KEY_CONFIRM: in  std_logic;    
        KEY_CANCELA: in std_logic;                
        BIN_PRODUTO: in  std_logic_vector(3 downto 0); 
        BIN_OUT: out std_logic_vector(3 downto 0) 
    );
end entity seletor_produto;

architecture behavior of seletor_produto is
    -- Sinais internos (nossas memórias)
    signal estado_travado : std_logic := '0'; 
    signal valor_salvo    : std_logic_vector(3 downto 0); 
begin

    -- process para lidar com o botão de confirmar
    process(KEY_CONFIRM, KEY_CANCELA)
    begin
        if(KEY_CANCELA = '1') then
            estado_travado <= '0';

        -- rising_edge = momento que solta o botão (0 -> 1)
        elsif rising_edge(KEY_CONFIRM) and (estado_travado = '0') then 
            estado_travado <= '1';            --trava o sistema
            valor_salvo    <= BIN_PRODUTO; -- pega a cópia do valor atual dos switches

        end if;
    end process;

    --este bloco decide: mostra o valor salvo ou o valor atual dos switches, dependendo do estado_travado
    process(estado_travado, BIN_PRODUTO, valor_salvo)
    begin
        if (estado_travado = '1') then
            BIN_OUT <= valor_salvo;  --mostra a cópia salva
        else
            BIN_OUT <= BIN_PRODUTO; --mostra os switches ao vivo
        end if;
    end process;

end architecture;