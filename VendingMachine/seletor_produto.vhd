library ieee;
use ieee.std_logic_1164.all; 

entity seletor_produto is
    port (
        --entradas
        botao_confirmar : in  std_logic;                    -- KEY0
        codigo_entrada  : in  std_logic_vector(3 downto 0); -- SW[3:0]
        botao_cancelar   : in  std_logic;                    -- KEY1 
        --saída
        saida  : out std_logic_vector(3 downto 0) 
    );
end entity seletor_produto;

architecture behavior of seletor_produto is
    -- Sinais internos (nossas memórias)
    signal estado_cancela : std_logic := '0'; -- '0' = não cancelado, '1' = cancelado
    signal estado_travado : std_logic := '0'; 
    signal valor_salvo    : std_logic_vector(3 downto 0); 
begin

    
    -- process para lidar com o botão de cancelar
    process(botao_cancelar, codigo_entrada)
    begin
        if rising_edge(botao_cancelar) then
            estado_cancela <= '1';
            estado_travado <= '0'; -- destrava o sistema
            saida <= codigo_entrada; --mostra o valor atual dos switches
        end if;
    end process;

    -- process para lidar com o botão de confirmar
    process(botao_confirmar)
    begin
        -- rising_edge = momento que solta o botão (0 -> 1)
        if rising_edge(botao_confirmar) then 
            estado_travado <= '1';            --trava o sistema
            valor_salvo    <= codigo_entrada; -- pega a cópia do valor atual dos switches
        end if;
    end process;

    --este bloco decide: mostra o valor salvo ou o valor atual dos switches, dependendo do estado_travado
    process(estado_travado, codigo_entrada, valor_salvo)
    begin
        if (estado_travado = '1') then
            saida <= valor_salvo;  --mostra a cópia salva
        else
            saida <= codigo_entrada; --mostra os switches ao vivo
        end if;
    end process;

end architecture;