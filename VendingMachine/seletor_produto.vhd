library ieee;
use ieee.std_logic_1164.all; 

entity seletor_produto is
    port (
        CLK        : in std_logic;
        KEY_CONFIRM: in  std_logic;                  
        BIN_PRODUTO: in  std_logic_vector(3 downto 0); 
        BIN_FIM_VENDA: in std_logic;
        BIN_OUT: out std_logic_vector(3 downto 0)        --saída do código do produto(só sai se tiver o botão de confirmar)
    );
end entity seletor_produto;

architecture behavior of seletor_produto is
    -- Sinais internos (nossas memórias)
    signal estado_travado : std_logic := '0'; 
    signal valor_salvo    : std_logic_vector(3 downto 0); 
    signal confirm_antigo : std_logic := '1';
begin

    -- process para lidar com o botão de confirmar de forma síncrona
    process(CLK)
    begin
        if rising_edge(CLK) then
            confirm_antigo <= KEY_CONFIRM;

            if (BIN_FIM_VENDA = '1') then  --volta ao estado inicial
                estado_travado <= '0';
            elsif (KEY_CONFIRM = '1' and confirm_antigo = '0') and (estado_travado = '0') then 
                estado_travado <= '1';            --trava o sistema
                valor_salvo    <= BIN_PRODUTO; -- pega a cópia do valor atual dos switches
            end if;
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